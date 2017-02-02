package com.ccrma.faust;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.support.v4.content.ContextCompat;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.webkit.WebView;
import android.widget.EditText;
import android.widget.ScrollView;
import android.widget.TextView;

import com.DspFaust.DspFaust;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Map;

class ConfigDisplay extends ViewGroup{
    private Map<String,Object> keyboardParameters;
    private Map<String,Object> dspParameters;
    private DspFaust dspFaust;
    private Context context;

    private ParamsView keyboardParamsView;
    private ParamsView dspParamsView;
    private WebView dspHtmlDoc;
    private EditText dspGeneratedDoc;
    private String dspGeneratedDocText;
    private PopupWindow popupWindow;

    // UI elements sizes
    private int width;
    private int height;
    private int borderSize;
    private int columnWidth;
    private int columnLabelHeight;

    // UI elements colors
    private int columnTitleBackgroundColor;
    private int titleButtonsColor;
    private int textWhiteColor;
    private int oddFieldsColor0;
    private int oddFieldsColor1;
    private int evenFieldsColor0;
    private int evenFieldsColor1;
    private int lockedButtonColor;
    private int popupWindowColor;

    // UI font sizes
    private int titlesFontSize;
    private int titlesButtonsFontSize;
    private int defaultTextFontSize;

    private  String currentPresetName;
    private String documentsDirectory;

    private int deleteActionType;
    private String paramToDelete;

    public ConfigDisplay(Context c, DspFaust dsp, String presetName) {
        super(c);

        context = c;

        setBackground(ContextCompat.getDrawable(context, R.drawable.config_display_background));

        dspFaust = dsp;
        currentPresetName = presetName;
        documentsDirectory = context.getFilesDir().toString();

        try {
            loadPreset();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }

        // configuring UI elements colors
        columnTitleBackgroundColor = Color.argb((int)(0.7*255), (int)(0.3*255), (int)(0.3*255), (int)(0.3*255));
        titleButtonsColor = Color.argb((int)(0.7*255), (int)(0.3*255), (int)(0.1*255), (int)(0.1*255));
        textWhiteColor = Color.argb((int)(1*255), (int)(0.9*255), (int)(0.9*255), (int)(0.9*255));
        oddFieldsColor0 = Color.argb((int)(0.7*255), (int)(0.5*255), (int)(0.5*255), (int)(0.5*255));
        evenFieldsColor0 = Color.argb((int)(0.7*255), (int)(0.7*255), (int)(0.7*255), (int)(0.7*255));
        oddFieldsColor1 = Color.argb((int)(0.7*255), (int)(0.7*255), (int)(0.7*255), (int)(0.7*255));
        evenFieldsColor1 = Color.argb((int)(0.7*255), (int)(0.9*255), (int)(0.9*255), (int)(0.9*255));
        lockedButtonColor = Color.argb((int)(0.7*255), (int)(1*255), (int)(0.3*255), (int)(0.3*255));
        popupWindowColor = Color.argb((int)(0.9*255), (int)(0.9*255), (int)(0.9*255), (int)(0.9*255));

        // configuring UI elements font sizes
        titlesFontSize = 24;
        titlesButtonsFontSize = 26;
        defaultTextFontSize = 18;

        // setting elements sizes
        borderSize = 4;

        buildKeyboardParamsView();
        buildDspParamsView();

        buildDspDoc();

        popupWindow = new PopupWindow(context);
        popupWindow.setVisibility(INVISIBLE);
        addView(popupWindow);
    }

    private void buildKeyboardParamsView(){
        if(keyboardParamsView != null){
            removeView(keyboardParamsView);
            keyboardParamsView = null;
        }
        keyboardParamsView = new ParamsView(context, keyboardParameters,0);
        addView(keyboardParamsView);
        if(keyboardParamsView.getWidth() == 0) { // not sure why we have to do that but it works...
            keyboardParamsView.layout(borderSize, borderSize, columnWidth - borderSize, height - borderSize);
        }
    }

    private void buildDspParamsView(){
        if(dspParamsView != null){
            removeView(dspParamsView);
            dspParamsView = null;
        }
        dspParamsView = new ParamsView(context,dspParameters,1);
        addView(dspParamsView);
        if(dspParamsView.getWidth() == 0){ // not sure why we have to do that but it works...
            dspParamsView.layout(borderSize+columnWidth,borderSize,columnWidth*2-borderSize,height-borderSize);
        }
    }

    private void buildDspDoc() {
        boolean htmlDocExists = false;
        try {
            htmlDocExists = Arrays.asList(context.getAssets().list("")).contains("dspDoc.html");
        } catch (IOException e) {
            e.printStackTrace();
        }

        if(htmlDocExists){
            dspHtmlDoc = new WebView(context);
            dspHtmlDoc.loadUrl("file:///android_asset/dspDoc.html");
            dspHtmlDoc.setVisibility(INVISIBLE);
            addView(dspHtmlDoc);
        }
        else{
            dspGeneratedDoc = new EditText(context);
            dspGeneratedDoc.setKeyListener(null);
            dspGeneratedDoc.setTextIsSelectable(true);

            try {
                loadSavedDoc();
            } catch (IOException e) {
                e.printStackTrace();
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            }

            if(dspGeneratedDocText == null){
                // if doc was never generated then generate it and save it
                dspGeneratedDocText = "CURRENT FAUST DSP DOCUMENTATION\n\nThis was automatically generated from the UI description of the Faust code associated with this app.\n\n";
                for(int i=0; i<dspFaust.getParamsCount(); i++){
                    dspGeneratedDocText = dspGeneratedDocText + dspFaust.getParamAddress(i).toString() + "\n";
                    dspGeneratedDocText = dspGeneratedDocText + "Description: " + dspFaust.getParamTooltip(i).toString() + "\n";
                    dspGeneratedDocText = dspGeneratedDocText + "Min: " + String.valueOf(dspFaust.getParamMin(i)) + "\n";
                    dspGeneratedDocText = dspGeneratedDocText + "Max: " + String.valueOf(dspFaust.getParamMax(i)) + "\n";
                    dspGeneratedDocText = dspGeneratedDocText + "Default: " + String.valueOf(dspFaust.getParamInit(i)) + "\n";
                    dspGeneratedDocText = dspGeneratedDocText + "----------\n\n";
                }
                try {
                    saveDoc();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            dspGeneratedDoc.setText(dspGeneratedDocText);
            dspGeneratedDoc.setBackgroundColor(evenFieldsColor0);
            dspGeneratedDoc.setTextSize(defaultTextFontSize);
            dspGeneratedDoc.setVisibility(INVISIBLE);
            addView(dspGeneratedDoc);
        }
    }

    private void loadSavedDoc() throws IOException, ClassNotFoundException {
        FileInputStream fileInputStreamKeyb = new FileInputStream(documentsDirectory.concat("/").concat("dspDoc"));
        ObjectInputStream objectInputStreamKeyb = new ObjectInputStream(fileInputStreamKeyb);
        dspGeneratedDocText = (String) objectInputStreamKeyb.readObject();
    }

    private void saveDoc() throws IOException {
        FileOutputStream fileOutputStreamKeyb = new FileOutputStream(documentsDirectory.concat("/").concat("dspDoc"));
        ObjectOutputStream objectOutputStreamKeyb = new ObjectOutputStream(fileOutputStreamKeyb);
        objectOutputStreamKeyb.writeObject(dspGeneratedDocText);
        objectOutputStreamKeyb.close();
    }

    private void loadPreset() throws IOException, ClassNotFoundException {
        // loading keyboard parameters
        FileInputStream fileInputStreamKeyb = new FileInputStream(documentsDirectory.concat("/").concat(currentPresetName).concat("_keyb"));
        ObjectInputStream objectInputStreamKeyb = new ObjectInputStream(fileInputStreamKeyb);
        keyboardParameters = (Map<String,Object>) objectInputStreamKeyb.readObject();

        // loading DSP parameters
        FileInputStream fileInputStreamDsp = new FileInputStream(documentsDirectory.concat("/").concat(currentPresetName).concat("_dsp"));
        ObjectInputStream objectInputStreamDsp = new ObjectInputStream(fileInputStreamDsp);
        dspParameters = (Map<String,Object>) objectInputStreamDsp.readObject();
    }

    public void savePreset() throws IOException {
        FileOutputStream fileOutputStreamKeyb = new FileOutputStream(documentsDirectory.concat("/").concat(currentPresetName).concat("_keyb"));
        ObjectOutputStream objectOutputStreamKeyb = new ObjectOutputStream(fileOutputStreamKeyb);
        objectOutputStreamKeyb.writeObject(keyboardParameters);
        objectOutputStreamKeyb.close();

        FileOutputStream fileOutputStreamDsp = new FileOutputStream(documentsDirectory.concat("/").concat(currentPresetName).concat("_dsp"));
        ObjectOutputStream objectOutputStreamDsp = new ObjectOutputStream(fileOutputStreamDsp);
        objectOutputStreamDsp.writeObject(dspParameters);
        objectOutputStreamDsp.close();
    }

    @Override
    protected void onLayout(boolean b, int left, int top, int right, int bottom) {
        width = right-left;
        height = bottom-top;
        columnWidth = width/2;
        columnLabelHeight = (int)(height*0.08);
        int popupWindowWidth = width/3;
        int popupWindowHeight = height/4;
        if(keyboardParamsView != null) {
            keyboardParamsView.layout(borderSize,borderSize,columnWidth-borderSize,height-borderSize);
        }
        if(dspParamsView != null) {
            dspParamsView.layout(borderSize+columnWidth,borderSize,columnWidth*2-borderSize,height-borderSize);
        }
        if(dspHtmlDoc != null){
            dspHtmlDoc.layout(borderSize,borderSize+columnLabelHeight,width-borderSize,height-borderSize);
        }
        if(dspGeneratedDoc != null){
            dspGeneratedDoc.layout(borderSize,borderSize+columnLabelHeight,width-borderSize,height-borderSize);
        }
        if(popupWindow != null) {
            popupWindow.layout(width/2-popupWindowWidth/2,
                    height/2-popupWindowHeight/2,
                    popupWindowWidth+width/2-popupWindowWidth/2,
                    popupWindowHeight+height/2-popupWindowHeight/2);
        }
    }

    class ParamsView extends ViewGroup{
        private ParamsScrollView paramsColumn;
        private FramedTextView paramsLabel;
        private Button showKeyboardParametersButton;
        private Button addKeyboardFieldButton;
        private int type;

        public ParamsView(Context context, Map<String,Object> params, int t){
            super(context);

            type = t;

            paramsLabel = new FramedTextView(context);
            if(type == 0) {
                paramsLabel.text.setText("Keyboard Parameters");
            }
            else{
                paramsLabel.text.setText("DSP Parameters");
            }
            paramsLabel.text.setTextSize(titlesFontSize);
            paramsLabel.text.setTextColor(textWhiteColor);
            paramsLabel.setBackgroundColor(columnTitleBackgroundColor);
            addView(paramsLabel);

            showKeyboardParametersButton = new Button(context,0);
            showKeyboardParametersButton.setOnColor(titleButtonsColor);
            showKeyboardParametersButton.setOffColor(titleButtonsColor);
            showKeyboardParametersButton.setTextBold();
            showKeyboardParametersButton.setTextSize(titlesButtonsFontSize);
            showKeyboardParametersButton.setTextColor(textWhiteColor);
            showKeyboardParametersButton.setText("H");
            showKeyboardParametersButton.setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                @Override
                public void OnButtonStatusChanged(Button source) {
                    if(source.on){
                        if(type == 0) {
                        }
                        else if(type == 1){
                            if(source.polarity){ // displaying the view
                                if(dspHtmlDoc == null){ // dsp doc
                                    dspGeneratedDoc.setVisibility(VISIBLE);
                                }
                                else {
                                    dspHtmlDoc.setVisibility(VISIBLE);
                                }
                                source.setOffColor(lockedButtonColor);
                                keyboardParamsView.hideColumn();
                                dspParamsView.hideColumn();
                            }
                            else{ // hiding the view
                                if(dspHtmlDoc == null){ // dsp doc
                                    dspGeneratedDoc.setVisibility(INVISIBLE);
                                }
                                else {
                                    dspHtmlDoc.setVisibility(INVISIBLE);
                                }
                                source.setOffColor(titleButtonsColor);
                                keyboardParamsView.showColumn();
                                dspParamsView.showColumn();
                            }
                        }
                    }
                }
            });
            addView(showKeyboardParametersButton);

            addKeyboardFieldButton = new Button(context,0);
            addKeyboardFieldButton.setOnColor(titleButtonsColor);
            addKeyboardFieldButton.setOffColor(titleButtonsColor);
            addKeyboardFieldButton.setTextBold();
            addKeyboardFieldButton.setTextSize(titlesButtonsFontSize);
            addKeyboardFieldButton.setTextColor(textWhiteColor);
            addKeyboardFieldButton.setText("+");
            addKeyboardFieldButton.setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                @Override
                public void OnButtonStatusChanged(Button source) {
                    if(source.on){
                        if(type == 0) {
                            keyboardParameters.put("**NewParameter**", 0);
                            buildKeyboardParamsView();
                        }
                        else if(type == 1){
                            dspParameters.put("**/NewParameter**", 0);
                            buildDspParamsView();
                        }
                    }
                }
            });
            addView(addKeyboardFieldButton);

            paramsColumn = new ParamsScrollView(context,params,type);
            addView(paramsColumn);
        }

        public void hideColumn(){
            paramsColumn.setVisibility(INVISIBLE);
        }

        public void showColumn(){
            paramsColumn.setVisibility(VISIBLE);
        }

        @Override
        protected void onLayout(boolean b, int left, int top, int right, int bottom) {
            int width = right-left;
            int height = bottom-top;
            int showButtonXOffset = width-columnLabelHeight*2+borderSize;
            int addButtonXOffset = showButtonXOffset + columnLabelHeight;
            paramsLabel.layout(0,0,width,columnLabelHeight);
            showKeyboardParametersButton.layout(showButtonXOffset,borderSize,showButtonXOffset+columnLabelHeight-borderSize*2,columnLabelHeight-borderSize);
            addKeyboardFieldButton.layout(addButtonXOffset,borderSize,addButtonXOffset+columnLabelHeight-borderSize*2,columnLabelHeight-borderSize);
            paramsColumn.layout(0,columnLabelHeight,width,height);
        }

    }

    class ParamsScrollView extends ScrollView{
        private ParamsList paramsList;
        private Map<String,Object> currentParams;
        private int type;

        public ParamsScrollView(Context context, Map<String,Object> params, int t) {
            super(context);

            type = t;
            currentParams = params;

            paramsList = new ParamsList(context);
            addView(paramsList);
        }

        class ParamsList extends ViewGroup {
            private ArrayList<String> keys;
            private ArrayList<Button> deleteButtons;
            private ArrayList<FramedEditText> keyFields;
            private ArrayList<FramedEditText> keyValueFields;

            public ParamsList(Context context) {
                super(context);

                keys = new ArrayList<String>();
                // retrieve the existing parameter keys and order alphabetically
                for (String key : currentParams.keySet()) {
                    keys.add(key);
                }
                Collections.sort(keys, String.CASE_INSENSITIVE_ORDER);

                deleteButtons = new ArrayList<>();
                keyFields = new ArrayList<>();
                keyValueFields = new ArrayList<>();

                for(int i=0; i<keys.size(); i++){
                    // delete button
                    deleteButtons.add(new Button(context,0));
                    if(!keys.get(i).contains("Number of Keyboards") &&
                            !keys.get(i).contains("Max Fingers") &&
                            !keys.get(i).contains("Max Keyboard Polyphony") &&
                            !keys.get(i).contains("Mono Mode") &&
                            !keys.get(i).contains("Rounding Mode") &&
                            !keys.get(i).contains("Inter-Keyboard Slide") &&
                            !keys.get(i).contains("Rounding Update Speed") &&
                            !keys.get(i).contains("Rounding Smooth") &&
                            !keys.get(i).contains("Rounding Threshold") &&
                            !keys.get(i).contains("Rounding Cycles")){
                        if(i%2 == 0){
                            deleteButtons.get(i).setOffColor(evenFieldsColor0);
                            deleteButtons.get(i).setOnColor(evenFieldsColor0);
                        }
                        else{
                            deleteButtons.get(i).setOffColor(oddFieldsColor0);
                            deleteButtons.get(i).setOnColor(oddFieldsColor0);
                        }
                        deleteButtons.get(i).setTextBold();
                        deleteButtons.get(i).setTextSize(titlesButtonsFontSize);
                        deleteButtons.get(i).setTextColor(textWhiteColor);
                        deleteButtons.get(i).setText("-");
                        deleteButtons.get(i).tag = i;
                        deleteButtons.get(i).setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                            @Override
                            public void OnButtonStatusChanged(Button source) {
                                if(source.on){
                                    if(type == 0) {
                                        deleteActionType = 0;
                                        paramToDelete = keys.get(source.tag);
                                        popupWindow.bringToFront();
                                        popupWindow.setVisibility(VISIBLE);
                                    }
                                    else if(type == 1){
                                        deleteActionType = 1;
                                        paramToDelete = keys.get(source.tag);
                                        popupWindow.bringToFront();
                                        popupWindow.setVisibility(VISIBLE);
                                    }
                                }
                            }
                        });
                    }
                    else{
                        deleteButtons.get(i).setOffColor(lockedButtonColor);
                        deleteButtons.get(i).setOnColor(lockedButtonColor);
                    }
                    addView(deleteButtons.get(i));

                    // key name
                    keyFields.add(new FramedEditText(context));
                    if(i%2 == 0){
                        keyFields.get(i).setBackgroundColor(evenFieldsColor1);
                    }
                    else{
                        keyFields.get(i).setBackgroundColor(oddFieldsColor1);
                    }
                    keyFields.get(i).text.setTextSize(defaultTextFontSize);
                    keyFields.get(i).text.setText(keys.get(i));
                    keyFields.get(i).text.setId(i);
                    keyFields.get(i).text.setOnEditorActionListener(new TextView.OnEditorActionListener() {
                        @Override
                        public boolean onEditorAction(TextView textView, int actionId, KeyEvent keyEvent) {
                            if (actionId == EditorInfo.IME_ACTION_DONE) {
                                Object currentValue = currentParams.get(keys.get(textView.getId()));
                                currentParams.remove(keys.get(textView.getId()));
                                currentParams.put(textView.getText().toString(), currentValue);
                                if(type == 0) {
                                    buildKeyboardParamsView();
                                }
                                else if(type == 1){
                                    buildDspParamsView();
                                }
                                return false;
                            }
                            return false;
                        }
                    });
                    addView(keyFields.get(i));

                    // key value
                    keyValueFields.add(new FramedEditText(context));
                    if(i%2 == 0){
                        keyValueFields.get(i).setBackgroundColor(evenFieldsColor0);
                    }
                    else{
                        keyValueFields.get(i).setBackgroundColor(oddFieldsColor0);
                    }
                    keyValueFields.get(i).text.setTextSize(defaultTextFontSize);
                    keyValueFields.get(i).text.setText(currentParams.get(keys.get(i)).toString());
                    keyValueFields.get(i).text.setId(i);
                    keyValueFields.get(i).text.setOnEditorActionListener(new TextView.OnEditorActionListener() {
                        @Override
                        public boolean onEditorAction(TextView textView, int actionId, KeyEvent keyEvent) {
                            if (actionId == EditorInfo.IME_ACTION_DONE) {
                                String currentKey = keys.get(textView.getId());

                                if(type == 0) {
                                    if(currentKey.contains("Number of Keyboards") ||
                                            currentKey.contains("Max Fingers") ||
                                            currentKey.contains("Max Keyboard Polyphony") ||
                                            currentKey.contains("Mono Mode") ||
                                            currentKey.contains("Rounding Mode") ||
                                            currentKey.contains("Inter-Keyboard Slide") ||
                                            currentKey.contains("Rounding Cycles") ||
                                            currentKey.contains("keyb")) {
                                        currentParams.put(keys.get(textView.getId()), Integer.valueOf(textView.getText().toString()));
                                    }
                                    else{
                                        currentParams.put(keys.get(textView.getId()), Float.valueOf(textView.getText().toString()));
                                    }
                                    buildKeyboardParamsView();
                                }
                                else if(type == 1){
                                    currentParams.put(keys.get(textView.getId()), Float.valueOf(textView.getText().toString()));
                                    buildDspParamsView();
                                }
                                return false;
                            }
                            return false;
                        }
                    });
                    addView(keyValueFields.get(i));
                }

            }

            @Override
            protected void onLayout(boolean b, int left, int top, int right, int bottom) {
                int width = right-left;
                int addButtonWidth = columnLabelHeight;
                int keyFieldWidth = (int)(width*0.8);
                for(int i=0; i<keys.size(); i++){
                    deleteButtons.get(i).layout(0,columnLabelHeight*i,addButtonWidth,columnLabelHeight*(i+1));
                    keyFields.get(i).layout(addButtonWidth,columnLabelHeight*i,keyFieldWidth,columnLabelHeight*(i+1));
                    keyValueFields.get(i).layout(keyFieldWidth,columnLabelHeight*i,width,columnLabelHeight*(i+1));
                }
            }
        }


        @Override
        protected void onLayout(boolean b, int left, int top, int right, int bottom) {
            int width = right-left;
            paramsList.layout(0,0,width,currentParams.size()*columnLabelHeight);
        }
    }

    class PopupWindow extends ViewGroup {
        private TextView popupMessage;
        private Button buttons[];

        public PopupWindow(Context context) {
            super(context);

            setBackgroundColor(popupWindowColor);

            popupMessage = new TextView(context);
            popupMessage.setGravity(Gravity.CENTER);
            popupMessage.setTextSize(defaultTextFontSize);
            // TODO missing line number set to 2 here
            popupMessage.setText("Are you sure you want to delete this parameter?");
            addView(popupMessage);

            String popupWindowButtonsLabels[] = {"No", "Yes"};
            buttons = new Button[2];
            for (int i = 0; i < 2; i++) {
                buttons[i] = new Button(context,0);
                buttons[i].setOnColor(titleButtonsColor);
                buttons[i].setOffColor(titleButtonsColor);
                buttons[i].setTextColor(textWhiteColor);
                buttons[i].setTextSize(defaultTextFontSize);
                buttons[i].setText(popupWindowButtonsLabels[i]);
                buttons[i].tag = i;
                buttons[i].setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                    @Override
                    public void OnButtonStatusChanged(Button source) {
                        if (source.on) {
                            // when adding a new preset, the current preset files are copied
                            if (source.tag == 1) { // yes
                                if (deleteActionType == 0) {
                                    keyboardParameters.remove(paramToDelete);
                                    buildKeyboardParamsView();
                                }
                                else if(deleteActionType == 1){
                                    dspParameters.remove(paramToDelete);
                                    buildDspParamsView();
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
            int width = right - left;
            int height = bottom - top;
            int buttonsWidth = width / 2 - borderSize * 2;
            popupMessage.layout(0, 0, width, height - columnLabelHeight - borderSize * 2);
            for (int i = 0; i < 2; i++) {
                // TODO doesn't look perfectly right but same problem on iOS
                buttons[i].layout(borderSize + (buttonsWidth + borderSize) * i,
                        height - columnLabelHeight - borderSize,
                        (buttonsWidth + borderSize) * (i + 1),
                        height - borderSize);
            }
        }
    }
}
