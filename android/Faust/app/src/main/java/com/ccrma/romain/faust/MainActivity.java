package com.ccrma.romain.faust;

import android.content.Context;
import android.media.midi.MidiDevice;
import android.media.midi.MidiDeviceInfo;
import android.media.midi.MidiManager;
import android.media.midi.MidiOutputPort;
import android.media.midi.MidiReceiver;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.widget.RelativeLayout;

import com.DspFaust.DspFaust;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.HashMap;
import java.util.Map;

/*
TODOs
- For new, bitmaps are handled in a very simple way and there's currently only one size available
we might have to do some extra work on this and try with other devices than the nexus 9
 */

public class MainActivity extends AppCompatActivity {
    private DspFaust dspFaust;
    private PresetMenu presetMenu;
    private InstrumentInterface instrumentInterface;
    private int currentPreset;
    private String audioSettingsFile;
    private String documentsDirectory;
    private Map<String,Object> audioSettings;
    private Context context;
    private RelativeLayout mainLayout;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        context = getApplicationContext();
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

        mainLayout = (RelativeLayout) findViewById(R.id.activity_main);

        if(getResources().getString(R.string.app_type).contains("Full")) {
            buildPresetMenu();
        }
        else{
            MultiKeyboard multiKeyboard = new MultiKeyboard(this, dspFaust, null);
            mainLayout.addView(multiKeyboard);
        }

        if(Build.VERSION.SDK_INT >= 23) {
            // MIDI Support
            final FaustMidiReceiver midiReceiver = new FaustMidiReceiver();
            final MidiManager m = (MidiManager) context.getSystemService(Context.MIDI_SERVICE);
            final MidiDeviceInfo[] infos = m.getDevices();

            // opening all the available ports and devices already connected
            for (int i = 0; i < infos.length; i++) {
                final int currentDevice = i;
                m.openDevice(infos[i], new MidiManager.OnDeviceOpenedListener() {
                    @Override
                    public void onDeviceOpened(MidiDevice device) {
                        if (device == null) {
                            Log.e("", "could not open device");
                        } else {
                            for (int j = 0; j < infos[currentDevice].getOutputPortCount(); j++) {
                                MidiOutputPort outputPort = device.openOutputPort(j);
                                outputPort.connect(midiReceiver);
                            }
                        }
                    }
                }, new Handler(Looper.getMainLooper()));
            }

            // adding any newly connected device
            m.registerDeviceCallback(new MidiManager.DeviceCallback() {
                public void onDeviceAdded(final MidiDeviceInfo info) {
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

                public void onDeviceRemoved(final MidiDeviceInfo info) {

                }

            }, new Handler(Looper.getMainLooper()));
        }
    }

    private void buildPresetMenu(){
        presetMenu = new PresetMenu(context,currentPreset);
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
                currentPreset = preset;
                mainLayout.removeView(presetMenu);
                presetMenu = null;
                buildInstrInterface();
            }
        });
        mainLayout.addView(presetMenu);
    }

    private void buildInstrInterface(){
        instrumentInterface = new InstrumentInterface(context, dspFaust, currentPreset);
        instrumentInterface.setInstrInterfaceStatusChangedListener(new InstrumentInterface.OnInstrInterfaceStatusChangedListener() {
            @Override
            public void OnStatusChanged(int preset) {
                currentPreset = preset;
                mainLayout.removeView(instrumentInterface);
                instrumentInterface = null;
                buildPresetMenu();
            }
        });
        mainLayout.addView(instrumentInterface);
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
