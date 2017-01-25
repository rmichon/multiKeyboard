package com.ccrma.romain.faust;

import android.content.Context;
import android.view.ViewGroup;

import com.DspFaust.DspFaust;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class InstrumentInterface extends ViewGroup {
    private MultiKeyboard multiKeyboard;
    private NavBar navBar;
    private ConfigDisplay configDisplay;
    private String documentsDirectory;
    private String localSettingsFile;
    private Map<String,Object> localSettings;
    private ArrayList<String> presetsList;
    private Context context;
    private DspFaust dspFaust;
    private String currentPresetName;
    private float viewsRatio;
    private boolean configDisplayOn;

    public int currentPreset; // TODO might not have to be public depending on the listener

    public InstrumentInterface(Context c, DspFaust faustDsp, int presetId) {
        super(c);

        context = c;
        dspFaust = faustDsp;
        configDisplayOn = false;
        documentsDirectory = context.getFilesDir().toString();
        currentPreset = presetId;
        viewsRatio = 0.92f;

        presetsList = new ArrayList<String>();
        updatePresetsList();
        currentPresetName = presetsList.get(currentPreset);

        // retrieving saved local settings
        localSettingsFile = documentsDirectory.concat("/instrIntSettings");
        try {
            loadLocalSettings();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }

        // if no saved settings then create defaults
        if(localSettings == null){
            try {
                createDefaultLocalSettings();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        buildUI();
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

    private void saveLocalSettings() throws IOException {
        FileOutputStream fileOutputStream = new FileOutputStream(localSettingsFile);
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(fileOutputStream);
        objectOutputStream.writeObject(localSettings);
        objectOutputStream.close();
    }

    private void loadLocalSettings() throws IOException, ClassNotFoundException {
        FileInputStream fileInputStream = new FileInputStream(localSettingsFile);
        ObjectInputStream objectInputStream = new ObjectInputStream(fileInputStream);
        localSettings = (Map<String,Object>) objectInputStream.readObject();
    }

    private void createDefaultLocalSettings() throws IOException {
        localSettings = new HashMap<String,Object>();
        localSettings.put("navBarPos", 2);

        FileOutputStream fileOutputStream = new FileOutputStream(localSettingsFile);
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(fileOutputStream);
        objectOutputStream.writeObject(localSettings);
        objectOutputStream.close();
    }

    public void buildUI(){
        cleanUI(); // cleaning first

        // UI is built in function of the position of the navbar
        if((int)localSettings.get("navBarPos") == 0){ // navbar is at the bottom
            navBar = new NavBar(context,true);
        }
        else if((int)localSettings.get("navBarPos") == 1){ // navbar is at the left
            navBar = new NavBar(context,false);
        }
        else if((int)localSettings.get("navBarPos") == 2){ // navbar is at the top
            navBar = new NavBar(context,true);
        }
        else if((int)localSettings.get("navBarPos") == 3){ // navbar is at the right
            navBar = new NavBar(context,false);
        }
        multiKeyboard = new MultiKeyboard(context,dspFaust,currentPresetName);
        navBar.setOnNavBarStatusChangedListener(new NavBar.OnNavBarStatusChangedListener() {
            @Override
            public void OnNavBarButtonTouched(int buttonID) {
                if(buttonID == 0){ // going back to home
                        // multiKeyboard.savePreset(); // TODO might have to be replaced here by something else
                    // TODO missing sender here
                    //[self sendActionsForControlEvents:UIControlEventValueChanged];
                }
                else if(buttonID == 1){
                    if(!configDisplayOn){ // opening config display
                        removeView(multiKeyboard);
                        multiKeyboard = null;
                        configDisplay = new ConfigDisplay(context);
                        addView(configDisplay);
                        configDisplayOn = true;
                    }
                    else{ // closing config window
                        // TODO need to call save parameters on config display!
                        removeView(configDisplay); // dealloc config display
                        configDisplay = null;
                        configDisplayOn = false;
                        multiKeyboard = new MultiKeyboard(context,dspFaust,currentPresetName);
                        addView(multiKeyboard);
                    }
                }
                else if(buttonID == 2){ // loading previous preset
                    if(currentPreset>0 && configDisplay==null){
                        currentPreset--;
                        currentPresetName = presetsList.get(currentPreset).replace("_keyb","");
                        buildUI();
                    }
                }
                else if(buttonID == 3 && configDisplay==null){ // loading next preset
                    if(currentPreset < presetsList.size()-1){
                        currentPreset++;
                        currentPresetName = presetsList.get(currentPreset).replace("_keyb","");
                        buildUI();
                    }
                }
                else if(buttonID == 4 && configDisplay==null){ // changing position of navbar
                    localSettings.put("navBarPos",((int)localSettings.get("navBarPos")+1)%4);
                    try {
                        saveLocalSettings();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    buildUI();
                }
            }
        });
        addView(multiKeyboard);
        addView(navBar);
    }

    // TODO should also check that guy... not sure we need this anymore with the future system
    public void cleanUI(){
        if(multiKeyboard != null){
            // TODO not so sure baout this: might be a source of memory leak
            //multiKeyboard.cleanInterface(); // necessary because of acceleremoeters (wont get dealloc otherwise)
            removeView(multiKeyboard);
            multiKeyboard = null;
        }
        if(navBar != null){
            removeView(navBar);
            navBar = null;
        }
    }

    @Override
    protected void onLayout(boolean b, int left, int top, int right, int bottom) {
        int width = right-left;
        int height = bottom-top;

        if((int)localSettings.get("navBarPos") == 0){ // navbar is at the bottom
            int multiKeyboardHeight = (int)(height*viewsRatio);
            if(navBar != null) navBar.layout(0,multiKeyboardHeight,width,height);
            if(multiKeyboard != null) multiKeyboard.layout(0,0,width,(int)(height*viewsRatio));
            if(configDisplay != null) configDisplay.layout(0,0,width,(int)(height*viewsRatio));
        }
        else if((int)localSettings.get("navBarPos") == 1){ // navbar is at the left
            int navBarWidth = (int)(width*(1-viewsRatio));
            if(navBar != null) navBar.layout(0,0,navBarWidth,height);
            if(multiKeyboard != null) multiKeyboard.layout(navBarWidth,0,width,height);
            if(configDisplay != null) configDisplay.layout(navBarWidth,0,width,height);
        }
        else if((int)localSettings.get("navBarPos") == 2){ // navbar is at the top
            int navBarHeight = (int)(height*(1-viewsRatio));
            if(navBar != null) navBar.layout(0,0,width,navBarHeight);
            if(multiKeyboard != null) multiKeyboard.layout(0,navBarHeight,width,height);
            if(configDisplay != null) configDisplay.layout(0,navBarHeight,width,height);
        }
        else if((int)localSettings.get("navBarPos") == 3){ // navbar is at the right
            int multiKeyboardWidth = (int)(width*viewsRatio);
            if(navBar != null) navBar.layout(multiKeyboardWidth,0,width,height);
            if(multiKeyboard != null) multiKeyboard.layout(0,0,multiKeyboardWidth,height);
            if(configDisplay != null) configDisplay.layout(0,0,multiKeyboardWidth,height);
        }
    }
}
