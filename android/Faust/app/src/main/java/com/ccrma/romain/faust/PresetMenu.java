package com.ccrma.romain.faust;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.BitmapDrawable;
import android.os.Environment;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.ActionBar;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class PresetMenu extends ViewGroup {
    private ArrayList<String> presetsList;
    private Menu menu;
    private PopupWindow popupWindow;
    private int borderSize;
    private String documentsDirectory;
    private FramedTextView presetsTitleLabel;
    private ScrollView presetsView;
    private AudioSettings audioSettingsView;

    private String audioSettingsFile;
    private Map<String,Object> audioSettings;

    private int selectedButtonColor;
    private int presetsListTitleColor;
    private int presetsListTitleBackgroundColor;
    private int oddPresetsNameFieldsBackgroundColor;
    private int evenPresetsNameFieldsBackgroundColor;
    private int selectedPresetsNameFieldsBackgroundColor;
    private int menuButtonsTextColor;
    private int menuButtonsBackgroundColor;
    private int presetsNameColor;
    private int oddSelectButtonsColor;
    private int evenSelectButtonsColor;

    private int fieldsHeight;

    private float presetsListFontSize;
    private float presetsListTitleFontSize;
    private float menuButtonsFontSize;

    private Context context;
    public int currentPreset;

    private OnPresetMenuChangedListener mPresetMenuChangedListener = null;

    public interface OnPresetMenuChangedListener {
        void OnAudioSettingsChanged();
        void OnPresetLaunch(int preset);
    }

    public PresetMenu(Context c, int preset) {
        super(c);

        context = c;
        currentPreset = preset;
        documentsDirectory = context.getFilesDir().toString();

        presetsList = new ArrayList<String>();

        // Color maps
        selectedButtonColor = Color.argb((int)(255*0.7), (int)(255*1), (int)(255*0.3), (int)(255*0.3));
        presetsListTitleColor = Color.argb((int)(255*1), (int)(255*0.96), (int)(255*0.96), (int)(255*0.96));
        presetsListTitleBackgroundColor = Color.argb((int)(255*0.7), (int)(255*0.2), (int)(255*0.2), (int)(255*0.2));
        oddPresetsNameFieldsBackgroundColor = Color.argb((int)(255*0.7), (int)(255*0.9), (int)(255*0.9), (int)(255*0.9));
        evenPresetsNameFieldsBackgroundColor = Color.argb((int)(255*0.7), (int)(255*0.8), (int)(255*0.8), (int)(255*0.8));
        selectedPresetsNameFieldsBackgroundColor = Color.argb((int)(255*0.7), (int)(255*1), (int)(255*0.7), (int)(255*0.7));
        menuButtonsTextColor = Color.argb((int)(255*1), (int)(255*0.85), (int)(255*0.85), (int)(255*0.85));
        menuButtonsBackgroundColor = Color.argb((int)(255*0.7), (int)(255*0.2), (int)(255*0.2), (int)(255*0.2));
        presetsNameColor = Color.argb((int)(255*1), (int)(255*0.2), (int)(255*0.2), (int)(255*0.2));
        oddSelectButtonsColor = Color.argb((int)(255*0.7), (int)(255*0.4), (int)(255*0.4), (int)(255*0.4));
        evenSelectButtonsColor = Color.argb((int)(255*0.7), (int)(255*0.3), (int)(255*0.3), (int)(255*0.3));

        // other parameters
        presetsListTitleFontSize = 24;
        presetsListFontSize = 22;
        menuButtonsFontSize = 20;

        // positions
        borderSize = 2;

        setBackground(ContextCompat.getDrawable(context, R.drawable.main_background));

        presetsTitleLabel = new FramedTextView(context);
        presetsTitleLabel.setBackgroundColor(presetsListTitleBackgroundColor);
        presetsTitleLabel.text.setTextColor(presetsListTitleColor);
        presetsTitleLabel.text.setTextSize(presetsListTitleFontSize);
        presetsTitleLabel.text.setTypeface(null, Typeface.BOLD);
        presetsTitleLabel.text.setText("Presets Name");
        addView(presetsTitleLabel);

        menu = new Menu(context);
        addView(menu);

        updatePresetsList();

        // If no presets (first run), then create one
        if(presetsList.size() == 0){
            try {
                createDefaultPresetFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
            updatePresetsList();
        }

        buildPresetsTable();

        audioSettingsFile = documentsDirectory.concat("/audioSettings");
        try {
            loadAudioSettings();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }

        audioSettingsView = new AudioSettings(context);
        audioSettingsView.setVisibility(INVISIBLE);
        addView(audioSettingsView);

        popupWindow = new PopupWindow(context);
        popupWindow.setVisibility(INVISIBLE);
        addView(popupWindow);
    }

    public void setOnPresetMenuChangedListener(OnPresetMenuChangedListener listener) {
        mPresetMenuChangedListener = listener;
    }

    private void loadAudioSettings() throws IOException, ClassNotFoundException {
        FileInputStream fileInputStream = new FileInputStream(audioSettingsFile);
        ObjectInputStream objectInputStream = new ObjectInputStream(fileInputStream);
        audioSettings = (Map<String,Object>) objectInputStream.readObject();
    }

    private void saveAudioSettings() throws IOException {
        FileOutputStream fileOutputStream = new FileOutputStream(audioSettingsFile);
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(fileOutputStream);
        objectOutputStream.writeObject(audioSettings);
        objectOutputStream.close();
    }

    private void updatePresetsList(){
        File f = new File(documentsDirectory);
        File file[] = f.listFiles();
        presetsList.clear();
        for(int i=0; i<file.length; i++){
            if(file[i].toString().contains("_keyb")) {
                presetsList.add(file[i].toString().replace(documentsDirectory.concat("/"),"").replace("_keyb",""));
            }
        }
        Collections.sort(presetsList,String.CASE_INSENSITIVE_ORDER);
    }

    private void buildPresetsTable(){
        presetsView = new PresetsView(context);
        addView(presetsView);
    }

    private void clearPresetsTable() {
        if(presetsView != null){
            removeView(presetsView);
            presetsView = null;
        }
    }

    class PresetsView extends ScrollView{
        private PresetsTable presetsTable;

        public PresetsView(Context context) {
            super(context);

            presetsTable = new PresetsTable(context);
            addView(presetsTable);
        }

        class PresetsTable extends ViewGroup {
            private ArrayList<Button> selectButtons;
            private ArrayList<FramedEditText> presetsNameFields;

            public PresetsTable(Context context) {
                super(context);

                selectButtons = new ArrayList<>();
                presetsNameFields = new ArrayList<>();

                // used to prevent edittext to gain focus
                setFocusable(true);
                setFocusableInTouchMode(true);

                for (int i = 0; i < presetsList.size(); i++) {
                    selectButtons.add(new Button(context,0));
                    if (i == currentPreset) {
                        selectButtons.get(i).setOffColor(selectedButtonColor);
                        selectButtons.get(i).setOnColor(selectedButtonColor);
                    } else {
                        if (i % 2 == 1) {
                            selectButtons.get(i).setOffColor(evenSelectButtonsColor);
                            selectButtons.get(i).setOnColor(evenSelectButtonsColor);
                        } else {
                            selectButtons.get(i).setOffColor(oddSelectButtonsColor);
                            selectButtons.get(i).setOnColor(oddSelectButtonsColor);
                        }
                    }
                    selectButtons.get(i).tag = i;
                    selectButtons.get(i).setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                        @Override
                        public void OnButtonStatusChanged(Button source) {
                            if (source.on) {
                                if (source.tag != currentPreset) {
                                    if (currentPreset % 2 == 1) {
                                        selectButtons.get(currentPreset).setOffColor(evenSelectButtonsColor);
                                        selectButtons.get(currentPreset).setOnColor(evenSelectButtonsColor);
                                        presetsNameFields.get(currentPreset).setBackgroundColor(evenPresetsNameFieldsBackgroundColor);
                                    } else {
                                        selectButtons.get(currentPreset).setOffColor(oddSelectButtonsColor);
                                        selectButtons.get(currentPreset).setOnColor(oddSelectButtonsColor);
                                        presetsNameFields.get(currentPreset).setBackgroundColor(oddPresetsNameFieldsBackgroundColor);
                                    }

                                    selectButtons.get(source.tag).setOffColor(selectedButtonColor);
                                    selectButtons.get(source.tag).setOnColor(selectedButtonColor);
                                    presetsNameFields.get(source.tag).setBackgroundColor(selectedPresetsNameFieldsBackgroundColor);
                                    currentPreset = source.tag;
                                }
                            }
                        }
                    });

                    addView(selectButtons.get(i));

                    presetsNameFields.add(new FramedEditText(context));
                    if (i == currentPreset) {
                        presetsNameFields.get(i).setBackgroundColor(selectedPresetsNameFieldsBackgroundColor);
                    } else {
                        if (i % 2 == 1) {
                            presetsNameFields.get(i).setBackgroundColor(evenPresetsNameFieldsBackgroundColor);
                        } else {
                            presetsNameFields.get(i).setBackgroundColor(oddPresetsNameFieldsBackgroundColor);
                        }
                    }
                    presetsNameFields.get(i).text.setTextSize(presetsListFontSize);
                    presetsNameFields.get(i).text.setTextColor(presetsNameColor);
                    presetsNameFields.get(i).text.setText(presetsList.get(i));
                    presetsNameFields.get(i).text.setId(i); // TODO might have to be normalized with other elements
                    presetsNameFields.get(i).text.setOnEditorActionListener(new TextView.OnEditorActionListener() {
                        @Override
                        public boolean onEditorAction(TextView textView, int actionId, KeyEvent keyEvent) {
                            if (actionId == EditorInfo.IME_ACTION_DONE) {
                                // when a preset name changes, the name of the corresponding preset files are updated
                                File currentKeybFile = new File(documentsDirectory.concat("/").concat(presetsList.get(textView.getId())).concat("_keyb"));
                                File newKeybFile = new File(documentsDirectory.concat("/").concat(textView.getText().toString()).concat("_keyb"));
                                File currentDspFile = new File(documentsDirectory.concat("/").concat(presetsList.get(textView.getId())).concat("_dsp"));
                                File newDspFile = new File(documentsDirectory.concat("/").concat(textView.getText().toString()).concat("_dsp"));
                                currentKeybFile.renameTo(newKeybFile);
                                currentDspFile.renameTo(newDspFile);

                                updatePresetsList();
                                clearPresetsTable();
                                buildPresetsTable();
                                return false;
                            }
                            return false;
                        }
                    });
                    addView(presetsNameFields.get(i));
                }
            }

            @Override
            protected void onLayout(boolean b, int left, int top, int right, int bottom) {
                for (int i = 0; i < presetsList.size(); i++) {
                    int width = right - left;
                    selectButtons.get(i).layout(0, fieldsHeight * i, fieldsHeight, fieldsHeight * (i + 1));
                    presetsNameFields.get(i).layout(fieldsHeight, fieldsHeight * i, width, fieldsHeight * (i + 1));
                }
            }
        }

        @Override
        protected void onLayout(boolean b, int left, int top, int right, int bottom) {
            int width = right-left;
            presetsTable.layout(0,0,width,presetsList.size()*fieldsHeight);
        }
    }

    class Menu extends ViewGroup{
        private Button menuButtons[];

        public Menu(Context context){
            super(context);

            String menuButtonsLabel[] = {"+ Add Preset", "- Delete Preset", "Audio Settings", "Run Preset :>"};
            menuButtons = new Button[4];
            for(int i=0; i<menuButtons.length; i++){
                menuButtons[i] = new Button(context,0);
                menuButtons[i].tag = i;
                menuButtons[i].setOnColor(menuButtonsBackgroundColor); // TODO perhaps should be moved here
                menuButtons[i].setOffColor(menuButtonsBackgroundColor); // TODO perhaps should be moved here
                menuButtons[i].setTextColor(menuButtonsTextColor);
                menuButtons[i].setTextSize(menuButtonsFontSize);
                menuButtons[i].setText(menuButtonsLabel[i]);
                menuButtons[i].setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                    @Override
                    public void OnButtonStatusChanged(Button source) {
                        if(source.on){
                            // when adding a new preset, the current preset files are copied
                            if(source.tag == 0){
                                // copying current keyboard preset to new file
                                String currentKeyboardPresetFile = documentsDirectory.concat("/").concat(presetsList.get(currentPreset).concat("_keyb"));
                                String currentDspPresetFile = documentsDirectory.concat("/").concat(presetsList.get(currentPreset).concat("_dsp"));
                                try {
                                    copyFile(new File(currentKeyboardPresetFile),new File(documentsDirectory.concat("/*New Preset*_keyb")));
                                    copyFile(new File(currentDspPresetFile),new File(documentsDirectory.concat("/*New Preset*_dsp")));
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                                updatePresetsList();
                                clearPresetsTable();
                                buildPresetsTable();
                            }
                            // when deleting a preset, the related files are deleted
                            else if(source.tag == 1 && presetsList.size()>1){
                                popupWindow.bringToFront();
                                popupWindow.setVisibility(VISIBLE);
                            }
                            else if(source.tag == 2){
                                if(source.polarity){
                                    source.setBackgroundColor(selectedButtonColor);
                                    audioSettingsView.setVisibility(VISIBLE);
                                    presetsTitleLabel.setVisibility(INVISIBLE);
                                    presetsView.setVisibility(INVISIBLE);
                                }
                                else{
                                    source.setBackgroundColor(menuButtonsBackgroundColor);
                                    audioSettingsView.setVisibility(INVISIBLE);
                                    presetsTitleLabel.setVisibility(VISIBLE);
                                    presetsView.setVisibility(VISIBLE);
                                    if (mPresetMenuChangedListener != null) {
                                        mPresetMenuChangedListener.OnAudioSettingsChanged();
                                    }
                                }
                            }
                            else if(source.tag == 3){
                                if (mPresetMenuChangedListener != null) {
                                    mPresetMenuChangedListener.OnPresetLaunch(currentPreset);
                                }
                            }
                        }
                    }
                });
                addView(menuButtons[i]);
            }

        }

        @Override
        protected void onLayout(boolean b, int left, int top, int right, int bottom) {
            int width = right-left;
            int buttonsWidth = width/menuButtons.length;
            for(int i=0; i<menuButtons.length; i++){
                menuButtons[i].layout(borderSize+buttonsWidth*i,
                        borderSize,
                        buttonsWidth*(i+1)-borderSize*2,
                        bottom-top-borderSize);
            }
        }
    }

    class PopupWindow extends ViewGroup{
        private TextView popupMessage;
        private Button buttons[];

        public PopupWindow(Context context) {
            super(context);

            setBackgroundColor(oddPresetsNameFieldsBackgroundColor);

            popupMessage = new TextView(context);
            popupMessage.setGravity(Gravity.CENTER);
            popupMessage.setTextSize(presetsListFontSize);
            // TODO missing line number set to 2 here
            popupMessage.setText("Are you sure you want to delete this preset?");
            addView(popupMessage);

            String popupWindowButtonsLabels[] = {"No","Yes"};
            buttons = new Button[2];
            for(int i=0; i<2; i++){
                buttons[i] = new Button(context,0);
                buttons[i].setOnColor(menuButtonsBackgroundColor);
                buttons[i].setOffColor(menuButtonsBackgroundColor);
                buttons[i].setTextColor(menuButtonsTextColor);
                buttons[i].setTextSize(presetsListFontSize);
                buttons[i].setText(popupWindowButtonsLabels[i]);
                buttons[i].tag = i;
                buttons[i].setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                    @Override
                    public void OnButtonStatusChanged(Button source) {
                        if (source.on) {
                            // when adding a new preset, the current preset files are copied
                            if (source.tag == 1) { // yes
                                String currentKeyboardPresetFilePath = documentsDirectory.concat("/").concat(presetsList.get(currentPreset).concat("_keyb"));
                                String currentDspPresetFilePath = documentsDirectory.concat("/").concat(presetsList.get(currentPreset).concat("_dsp"));
                                File currentKeyboardPresetFile = new File(currentKeyboardPresetFilePath);
                                File currentDspPresetFile = new File(currentDspPresetFilePath);
                                if(currentKeyboardPresetFile.delete() && currentDspPresetFile.delete()) {
                                    currentPreset = 0;
                                    updatePresetsList();
                                    clearPresetsTable();
                                    buildPresetsTable();
                                }
                            }
                        }
                        popupWindow.setVisibility(INVISIBLE);
                    }
                });
                addView(buttons[i]);
            }
        }

        @Override
        protected void onLayout(boolean b, int left, int top, int right, int bottom) {
            int width = right-left;
            int height = bottom-top;
            int buttonsWidth = width/2-borderSize*2;
            popupMessage.layout(0,0,width,height-fieldsHeight-borderSize*2);
            for(int i=0; i<2; i++){
                // TODO doesn't look perfectly right but same problem on iOS
                buttons[i].layout(borderSize+(buttonsWidth+borderSize)*i,
                        height-fieldsHeight-borderSize,
                        (buttonsWidth+borderSize)*(i+1),
                        height-borderSize);
            }
        }
    }

    class AudioSettings extends ViewGroup{
        private ArrayList<TextView> labels;
        private ArrayList<EditText> valueFields;
        private String audioSettingsLabels[] = {"Sampling Rate", "Buffer Size"};

        public AudioSettings(Context context) {
            super(context);

            // preventing automatic focus
            setFocusable(true);
            setFocusableInTouchMode(true);

            labels = new ArrayList<TextView>();
            valueFields = new ArrayList<EditText>();

            for(int i=0; i<audioSettingsLabels.length; i++){
                labels.add(new TextView(context));
                labels.get(i).setGravity(Gravity.CENTER);
                labels.get(i).setTextColor(menuButtonsTextColor);
                labels.get(i).setTextSize(presetsListFontSize);
                labels.get(i).setText(audioSettingsLabels[i]);
                if(i%2 == 1){
                    labels.get(i).setBackgroundColor(evenSelectButtonsColor);
                }
                else{
                    labels.get(i).setBackgroundColor(oddSelectButtonsColor);
                }
                addView(labels.get(i));

                valueFields.add(new EditText(context));
                if(i%2 == 1){
                    valueFields.get(i).setBackgroundColor(evenPresetsNameFieldsBackgroundColor);
                }
                else{
                    valueFields.get(i).setBackgroundColor(oddPresetsNameFieldsBackgroundColor);
                }
                valueFields.get(i).setGravity(Gravity.CENTER);
                valueFields.get(i).setTextSize(presetsListFontSize);
                valueFields.get(i).setTextColor(presetsNameColor);
                valueFields.get(i).setSingleLine(true);
                valueFields.get(i).setImeOptions(EditorInfo.IME_ACTION_DONE);
                if(i == 0){
                    valueFields.get(i).setText(audioSettings.get("SR").toString());
                }
                else if (i == 1){
                    valueFields.get(i).setText(audioSettings.get("bufferLength").toString());
                }
                valueFields.get(i).setId(i); // TODO not sure, this light create issues...
                valueFields.get(i).setOnEditorActionListener(new TextView.OnEditorActionListener() {
                    @Override
                    public boolean onEditorAction(TextView source, int actionId, KeyEvent keyEvent) {
                        if (actionId == EditorInfo.IME_ACTION_DONE) {
                            String currentSetting;
                            if(source.getId() == 0){
                                currentSetting ="SR";
                            }
                            else{
                                currentSetting = "bufferLength";
                            }
                            if(Integer.parseInt(source.getText().toString()) != 0){
                                audioSettings.put(currentSetting,Integer.parseInt(source.getText().toString()));
                                try {
                                    saveAudioSettings();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                            }
                            else{
                                source.setText(audioSettings.get(currentSetting).toString());
                            }
                            return false;
                        }
                        return false;
                    }
                });
                addView(valueFields.get(i));
            }
        }

        @Override
        protected void onLayout(boolean b, int left, int top, int right, int bottom) {
            int width = right-left;
            int labelsWidth = width/5;
            for(int i=0; i<audioSettingsLabels.length; i++) {
                labels.get(i).layout(0,fieldsHeight*i,labelsWidth,fieldsHeight*(i+1));
                valueFields.get(i).layout(labelsWidth,fieldsHeight*i,width,fieldsHeight*(i+1));
            }
        }
    }

    // Creates a set of new default preset file
    private void createDefaultPresetFile() throws IOException {
        Map<String,Object> keyboardParameters;
        keyboardParameters = new HashMap<String,Object>();
        keyboardParameters.put("Number of Keyboards", 4);
        keyboardParameters.put("Max Fingers", 10);
        keyboardParameters.put("Max Keyboard Polyphony", 16);
        keyboardParameters.put("Mono Mode", 1);
        keyboardParameters.put("Rounding Mode", 0);
        keyboardParameters.put("Inter-Keyboard Slide", 1);
        keyboardParameters.put("Send Current Key", 1);
        keyboardParameters.put("Send Current Keyboard", 1);
        keyboardParameters.put("Send X", 1);
        keyboardParameters.put("Send Y", 1);
        keyboardParameters.put("Send Sensors", 1);
        keyboardParameters.put("Rounding Update Speed", (float) 0.06);
        keyboardParameters.put("Rounding Smooth", (float) 0.9);
        keyboardParameters.put("Rounding Threshold", (float) 3.0);
        keyboardParameters.put("Rounding Cycles", 5);

        // keyboard dependent default parameters TODO: this is missing on iOS
        for(int i=0; i<(int)keyboardParameters.get("Number of Keyboards") ; i++){
            if(keyboardParameters.get(String.format("Keyboard %d - Number of Keys",i)) == null) {
                keyboardParameters.put(String.format("Keyboard %d - Number of Keys", i), 7);
            }
            if(keyboardParameters.get(String.format("Keyboard %d - Lowest Key",i)) == null) {
                keyboardParameters.put(String.format("Keyboard %d - Lowest Key", i), (48 + i * 12) % 127);
            }
            if(keyboardParameters.get(String.format("Keyboard %d - Scale",i)) == null) {
                keyboardParameters.put(String.format("Keyboard %d - Scale", i), 0);
            }
            if(keyboardParameters.get(String.format("Keyboard %d - Show Notes",i)) == null) {
                keyboardParameters.put(String.format("Keyboard %d - Show Notes", i), 1);
            }
            if(keyboardParameters.get(String.format("Keyboard %d - Root Position",i)) == null) {
                keyboardParameters.put(String.format("Keyboard %d - Root Position", i), 0);
            }
            if(keyboardParameters.get(String.format("Keyboard %d - Orientation",i)) == null) {
                keyboardParameters.put(String.format("Keyboard %d - Orientation", i), 0);
            }
            if(keyboardParameters.get(String.format("Keyboard %d - Mode",i)) == null) {
                keyboardParameters.put(String.format("Keyboard %d - Mode", i), 1);
            }
        }

        FileOutputStream fileOutputStreamKeyb = new FileOutputStream(documentsDirectory.concat("/Preset 0_keyb"));
        ObjectOutputStream objectOutputStreamKeyb = new ObjectOutputStream(fileOutputStreamKeyb);
        objectOutputStreamKeyb.writeObject(keyboardParameters);
        objectOutputStreamKeyb.close();

        Map<String,Object> dspParameters;
        dspParameters = new HashMap<String,Object>();

        FileOutputStream fileOutputStreamDsp = new FileOutputStream(documentsDirectory.concat("/Preset 0_dsp"));
        ObjectOutputStream objectOutputStreamDsp = new ObjectOutputStream(fileOutputStreamDsp);
        objectOutputStreamDsp.writeObject(dspParameters);
        objectOutputStreamDsp.close();
    }

    public void copyFile(File src, File dst) throws IOException {
        InputStream in = new FileInputStream(src);
        OutputStream out = new FileOutputStream(dst);

        // Transfer bytes from in to out
        byte[] buf = new byte[1024];
        int len;
        while ((len = in.read(buf)) > 0) {
            out.write(buf, 0, len);
        }
        in.close();
        out.close();
    }

    @Override
    protected void onLayout(boolean b, int left, int top, int right, int bottom) {
        int width = right-left;
        int height = bottom-top;
        int presetsListWidth = width;
        int presetsListXOffset = width/12;
        int presetsListYOffset = width/8; // /6 on iOS
        fieldsHeight = height/16; // TODO may be copy to the other
        int presetsListHeight = (int)(height*0.92);
        int popupWindowWidth = width/3;
        int popupWindowHeight = height/4;

        // TODO alignment of that one doesn't look right compared to Android
        if(presetsTitleLabel != null) {
            presetsTitleLabel.layout(borderSize + presetsListXOffset + fieldsHeight,
                    borderSize + presetsListYOffset,
                    (presetsListWidth - borderSize - presetsListXOffset),
                    borderSize + presetsListYOffset + fieldsHeight);
        }
        if(presetsView != null) {
            presetsView.layout(borderSize + presetsListXOffset,
                    borderSize + presetsListYOffset + fieldsHeight,
                    presetsListWidth - borderSize - presetsListXOffset,
                    presetsListHeight + borderSize - presetsListXOffset);
        }
        if(menu != null) {
            menu.layout(0, presetsListHeight, right, bottom - top);
        }
        if(popupWindow != null) {
            popupWindow.layout(width/2-popupWindowWidth/2,
                    height/2-popupWindowHeight/2,
                    popupWindowWidth+width/2-popupWindowWidth/2,
                    popupWindowHeight+height/2-popupWindowHeight/2);
        }
        if(audioSettingsView != null){
            audioSettingsView.layout(borderSize + presetsListXOffset,
                    borderSize + presetsListYOffset,
                    presetsListWidth - borderSize - presetsListXOffset,
                    presetsListHeight + borderSize - presetsListXOffset);
        }
    }
}
