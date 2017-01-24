package com.ccrma.romain.faust;

import android.content.Context;
import android.media.midi.MidiDevice;
import android.media.midi.MidiDeviceInfo;
import android.media.midi.MidiManager;
import android.media.midi.MidiOutputPort;
import android.media.midi.MidiReceiver;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.widget.RelativeLayout;

import com.DspFaust.DspFaust;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.HashMap;
import java.util.Map;

public class MainActivity extends AppCompatActivity {
    private DspFaust dspFaust;
    private PresetMenu presetMenu;
    private InstrumentInterface instrumentInterface;
    private int currentPreset;
    private String audioSettingsFile;
    private String documentsDirectory;
    private Map<String,Object> audioSettings;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        currentPreset = 0;
        documentsDirectory = this.getFilesDir().toString();

        // TODO: missing upload default presets

        // initializing audio settings
        audioSettingsFile = documentsDirectory.concat("/audioSettings");
        try {
            loadAudioSettings();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }

        // if no saved settings then create defaults
        if(audioSettings == null){
            try {
                createDefaultAudioSettings();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        startFaustDsp();

        final RelativeLayout mainLayout = (RelativeLayout) findViewById(R.id.activity_main);
        final PresetMenu presetMenu = new PresetMenu(this,currentPreset);
        presetMenu.setOnPresetMenuChangedListener(new PresetMenu.OnPresetMenuChangedListener() {
            @Override
            public void OnAudioSettingsChanged() {
                try {
                    loadAudioSettings();
                } catch (IOException e) {
                    e.printStackTrace();
                } catch (ClassNotFoundException e) {
                    e.printStackTrace();
                }
                stopFaustDsp();
                startFaustDsp();
            }

            @Override
            public void OnPresetLaunch(int preset) {
                /*
                currentPreset = preset;
                instrumentInterface = new InstrumentInterface(this, dspFaust, currentPreset);
                mainLayout.removeView(presetMenu);
                presetMenu = null;
                [instrumentInterface addTarget:self action:@selector(newEventOnInstrumentInterface:) forControlEvents:UIControlEventValueChanged];
                [self.view addSubview:instrumentInterface];
                */
            }
        });
        mainLayout.addView(presetMenu);

        // TODO: missing keyboard only
        //MultiKeyboard multiKeyboard = new MultiKeyboard(this, dspFaust, null);
        //mainLayout.addView(multiKeyboard);

        // MIDI Support
        final FaustMidiReceiver midiReceiver = new FaustMidiReceiver();
        final MidiManager m = (MidiManager)this.getSystemService(Context.MIDI_SERVICE);
        final MidiDeviceInfo[] infos = m.getDevices();

        // opening all the available ports and devices already connected
        for(int i=0; i<infos.length; i++){
            final int currentDevice = i;
            m.openDevice(infos[i], new MidiManager.OnDeviceOpenedListener() {
                @Override
                public void onDeviceOpened(MidiDevice device) {
                    if (device == null) {
                        Log.e("", "could not open device");
                    } else {
                        for(int j=0; j<infos[currentDevice].getOutputPortCount(); j++) {
                            MidiOutputPort outputPort = device.openOutputPort(j);
                            outputPort.connect(midiReceiver);
                        }
                    }
                }
            }, new Handler(Looper.getMainLooper()));
        }

        // adding any newly connected device
        m.registerDeviceCallback(new MidiManager.DeviceCallback() {
            public void onDeviceAdded( final MidiDeviceInfo info ) {
                m.openDevice(info, new MidiManager.OnDeviceOpenedListener() {
                    @Override
                    public void onDeviceOpened(MidiDevice device) {
                        if (device == null) {
                            Log.e("", "could not open device");
                        } else {
                            for (int j = 0; j < info.getOutputPortCount(); j++) {
                                MidiOutputPort outputPort = device.openOutputPort(j);
                                outputPort.connect(midiReceiver);
                            }
                        }
                    }
                }, new Handler(Looper.getMainLooper()));
            }

            public void onDeviceRemoved( final MidiDeviceInfo info ) {

            }

        }, new Handler(Looper.getMainLooper()));
    }

    private void loadAudioSettings() throws IOException, ClassNotFoundException {
        FileInputStream fileInputStream = new FileInputStream(audioSettingsFile);
        ObjectInputStream objectInputStream = new ObjectInputStream(fileInputStream);
        audioSettings = (Map<String,Object>) objectInputStream.readObject();
    }

    private void createDefaultAudioSettings() throws IOException {
        audioSettings = new HashMap<String,Object>();
        audioSettings.put("SR", 48000);
        audioSettings.put("bufferLength",128);

        FileOutputStream fileOutputStream = new FileOutputStream(documentsDirectory.concat("/audioSettings"));
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(fileOutputStream);
        objectOutputStream.writeObject(audioSettings);
        objectOutputStream.close();
    }

    private void startFaustDsp(){
        if(dspFaust == null){
            dspFaust = new DspFaust((int)audioSettings.get("SR"), (int)audioSettings.get("bufferLength"));
            dspFaust.start();
        }
    }

    private void stopFaustDsp(){
        if(dspFaust != null){
            dspFaust.stop();
            dspFaust = null;
        }
    }

    @Override
    public void onPause(){
        super.onPause();
        dspFaust.stop();
    }

    @Override
    public void onResume(){
        super.onPause();
        dspFaust.start();
    }

    @Override
    public void onDestroy(){
        super.onDestroy();
        dspFaust.stop();
    }

    class FaustMidiReceiver extends MidiReceiver {
        public void onSend(byte[] data, int offset,
                           int count, long timestamp) {
            // we only consider MIDI messages containing 3 bytes (see is just an example)
            if(count%3 == 0) {
                int nMessages = count / 3; // in case the event contains several messages
                for (int i = 0; i < nMessages; i++) {
                    int type = (int) (data[offset + i*3] & 0xF0);
                    int channel = (int) (data[offset + i*3] & 0x0F);
                    int data1 = (int) data[offset + 1 + i*3];
                    int data2 = (int) data[offset + 2 + i*3];
                    dspFaust.propagateMidi(3, timestamp, type, channel, data1, data2);
                }
            }
        }
    }
}
