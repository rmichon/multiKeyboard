package com.ccrma.romain.faust;

import android.content.Context;
import android.graphics.Color;
import android.graphics.PointF;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;
import android.util.SparseArray;
import android.view.MotionEvent;
import android.view.ViewGroup;

import com.DspFaust.DspFaust;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class MultiKeyboard extends ViewGroup {
    // GRAPHICAL ELEMENTS
    private ArrayList<ArrayList<Zone>> zones;
    private int viewWidth;
    private int viewHeight;
    private int zoneWidths[];
    private int zoneHeight;
    private int borderSize;
    private int zoneCenterXOffset[]; // necessary on android because sizes are ints
    private int zoneCenterYOffset;
    private Boolean UIon; // true when UI is built (used to secure the rounding thread when there's no UI on the screen)

    // TOUCH TRACKING
    private SparseArray<PointF> mActivePointers;
    private float currentContinuousKey; // key number of the current keyboard as a float
    private float currentKeyboardY; // y position of finger on key (corresponds to the "y" parameter in Faust)
    private int fingersOnKeyboardsCount[]; // number of fingers present on each keyboard (used to limit polyphony)
    private int previousTouchedKeyboards[]; // the last keyboard touched by a specific finger on the screen
    private int previousTouchedKeys[]; // the last key touched by a specific finger on the screen
    private int monoMode_previousActiveFinger[]; // last active finger in mono mode (in case touch needs to canceled)
    private int fingersOnScreenCount;

    // PITCH ROUNDING
    private float touchDiff[]; // distance between 2 distinct touch events
    private boolean rounding[]; // tell if the current pitch should be rounded
    private Smooth smooth[]; // integrators for rounding detection
    private int moveCount[]; // counts the number of movements outside the threshold for each touch
    private long roundingUpdateSpeed; // the speed at which the rounding thread is updated

    // FAUST
    private DspFaust dspFaust;
    private long voices[];

    // OTHER
    private Context context;
    private String currentPresetName;
    private String documentsDirectory;
    private SensorManager mSensorManager;

    // Public variables
    public Map<String,Object> keyboardParameters;
    public Map<String,Object> dspParameters;

    public MultiKeyboard(Context c, DspFaust dsp, String presetName) {
        super(c);

        context = c;
        dspFaust = dsp;
        currentPresetName = presetName;
        borderSize = 2; // TODO this parameter should be updated in function of screen width as well as the fonts
        setBackgroundColor(Color.BLACK);

        documentsDirectory = context.getFilesDir().toString();

        keyboardParameters = new HashMap<String,Object>();

        if(currentPresetName == null) {
            keyboardParameters.put("nKeyb", 4);
            keyboardParameters.put("maxFingers", 10);
            keyboardParameters.put("maxKeybPoly", 16);
            keyboardParameters.put("monoMode", 1);
            keyboardParameters.put("quantizationMode", 0);
            keyboardParameters.put("interKeybSlideAllowed", 1);
            keyboardParameters.put("sendCurrentKey", 1);
            keyboardParameters.put("sendCurrentKeyboard", 1);
            keyboardParameters.put("sendX", 1);
            keyboardParameters.put("sendY", 1);
            keyboardParameters.put("sendAccel", 1);
            keyboardParameters.put("roundingUpdateSpeed", (float) 0.06);
            keyboardParameters.put("roundingSmoothPole", (float) 0.9);
            keyboardParameters.put("roundingThreshold", (float) 3.0);
            keyboardParameters.put("roundingDeactCycles", 5);


            String JSONInterface = dspFaust.getJSONMeta();
            if (JSONInterface.indexOf("SmartKeyboard{") != -1) {
                String JSONSmartKeyboard = JSONInterface.substring(JSONInterface.indexOf("SmartKeyboard{") + 14);
                JSONSmartKeyboard = JSONSmartKeyboard.substring(0, JSONSmartKeyboard.indexOf("}"));

                while (JSONSmartKeyboard.indexOf("'") != -1) {
                    JSONSmartKeyboard = JSONSmartKeyboard.substring(JSONSmartKeyboard.indexOf("'") + 1);
                    String currentKey = JSONSmartKeyboard.substring(0, JSONSmartKeyboard.indexOf("'"));
                    JSONSmartKeyboard = JSONSmartKeyboard.substring(JSONSmartKeyboard.indexOf("'") + 1);
                    JSONSmartKeyboard = JSONSmartKeyboard.substring(JSONSmartKeyboard.indexOf("'") + 1);
                    String currentValue = JSONSmartKeyboard.substring(0, JSONSmartKeyboard.indexOf("'"));
                    JSONSmartKeyboard = JSONSmartKeyboard.substring(JSONSmartKeyboard.indexOf("'") + 1);

                    // TODO: currently only saves to int
                    keyboardParameters.put(currentKey, Integer.parseInt(currentValue));
                }
            } else {
                Log.e("Faust MultiKeyboard", "No valid SmartKeyboard description in Faust code");
            }
            dspParameters = new HashMap<String,Object>(); // empty dictionary in that case
        }
        else {
            try {
                loadPreset();
            } catch (IOException e) {
                e.printStackTrace();
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            }
        }

        // TODO: missing cancelOnce

        mActivePointers = new SparseArray<PointF>();
        mSensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);

        buildInterface();

        if((int)keyboardParameters.get("quantizationMode") == 2){
            Thread t = new Thread(new PitchRounding());
            t.start();
        }
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

    public void buildInterface(){
        //cleanInterface();
        UIon = true;

        if((int)keyboardParameters.get("sendAccel") == 1){
            mSensorManager.registerListener(mSensorListener, mSensorManager.getDefaultSensor(
                    Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_FASTEST);
        }

        // keyboard dependent default parameters
        for(int i=0; i<(int)keyboardParameters.get("nKeyb") ; i++){
            if(keyboardParameters.get(String.format("keyb%d_nKeys",i)) == null) {
                keyboardParameters.put(String.format("keyb%d_nKeys", i), 7);
            }
            if(keyboardParameters.get(String.format("keyb%d_lowestKey",i)) == null) {
                keyboardParameters.put(String.format("keyb%d_lowestKey", i), (48 + i * 12) % 127);
            }
            if(keyboardParameters.get(String.format("keyb%d_scale",i)) == null) {
                keyboardParameters.put(String.format("keyb%d_scale", i), 0);
            }
            if(keyboardParameters.get(String.format("keyb%d_showNotesName",i)) == null) {
                keyboardParameters.put(String.format("keyb%d_showNotesName", i), 1);
            }
            if(keyboardParameters.get(String.format("keyb%d_rootPos",i)) == null) {
                keyboardParameters.put(String.format("keyb%d_rootPos", i), 0);
            }
            if(keyboardParameters.get(String.format("keyb%d_orientation",i)) == null) {
                keyboardParameters.put(String.format("keyb%d_orientation", i), 0);
            }
            if(keyboardParameters.get(String.format("keyb%d_keybMode",i)) == null) {
                keyboardParameters.put(String.format("keyb%d_keybMode", i), 1);
            }
        }

        touchDiff = new float[(int)keyboardParameters.get("maxFingers")];
        moveCount = new int[(int)keyboardParameters.get("maxFingers")];
        rounding = new boolean[(int)keyboardParameters.get("maxFingers")];
        previousTouchedKeys = new int[(int)keyboardParameters.get("maxFingers")];
        previousTouchedKeyboards = new int[(int)keyboardParameters.get("maxFingers")];
        smooth = new Smooth[(int)keyboardParameters.get("maxFingers")];
        voices = new long[(int)keyboardParameters.get("maxFingers")];

        for(int i=0; i<(int)keyboardParameters.get("maxFingers"); i++){
            touchDiff[i] = 0;
            previousTouchedKeys[i] = -1;
            previousTouchedKeyboards[i] = -1;
            moveCount[i] = 0;
            smooth[i] = new Smooth();
            smooth[i].setSmooth((float)keyboardParameters.get("roundingSmoothPole"));
            rounding[i] = true;
            voices[i] = -1;
        }

        fingersOnScreenCount = 0;
        roundingUpdateSpeed = (long)((float)keyboardParameters.get("roundingUpdateSpeed")*1000);

        zoneWidths = new int[(int)keyboardParameters.get("nKeyb")];
        zoneCenterXOffset = new int[(int)keyboardParameters.get("nKeyb")];
        fingersOnKeyboardsCount = new int[(int)keyboardParameters.get("nKeyb")];
        monoMode_previousActiveFinger = new int[(int)keyboardParameters.get("nKeyb")];

        // TODO: skipping a big block here

        // initializing the different keyboards
        zones = new ArrayList<>();
        for(int i=0; i<(int)keyboardParameters.get("nKeyb") ; i++) {
            // if no poly mode, then no keyboard mode is automatically activated
            if((int)keyboardParameters.get("maxKeybPoly") <= 0) {
                keyboardParameters.put(String.format("keyb%d_keybMode", i), 0);
            }
            zones.add(new ArrayList<Zone>());
            fingersOnKeyboardsCount[i] = 0;
            monoMode_previousActiveFinger[i] = 0;
            for(int j=0; j<(int)keyboardParameters.get(String.format("keyb%d_nKeys",i)); j++) {
                zones.get(i).add(new Zone(context));
                zones.get(i).get(j).setKeyboardMode((int)keyboardParameters.get(String.format("keyb%d_keybMode", i)) == 1);
                if (((int)keyboardParameters.get(String.format("keyb%d_keybMode", i)) == 1) &&
                        ((int) keyboardParameters.get(String.format("keyb%d_scale", i)) < 1) &&
                        ((int) keyboardParameters.get(String.format("keyb%d_showNotesName", i)) > 0)) {
                    if ((int)keyboardParameters.get(String.format("keyb%d_orientation", i)) == 1) {
                        zones.get(i).get(j).setNote((int) applyScale((int) keyboardParameters
                                .get(String.format("keyb%d_lowestKey", i)) + (int) keyboardParameters.get(String.format("keyb%d_nKeys", i)) - j - 1, i));
                    } else {
                        zones.get(i).get(j).setNote((int) applyScale(j + (int)
                                keyboardParameters.get
                                (String.format("keyb%d_lowestKey", i)), i));
                    }
                }
                zones.get(i).get(j).drawBackground();
                addView(zones.get(i).get(j));
            }

        }
        // case where no pitch keyboard is on: we trigger the main voice on startup
        if((int)keyboardParameters.get("maxKeybPoly") == 0){
            voices[0] = dspFaust.newVoice();
        }

        // TODO: missing some stuff here too
    }

    /*
    public void cleanInterface(){
        if((int)keyboardParameters.get("sendAccel") == 1) {
            mSensorManager.unregisterListener(mSensorListener);
        }
        if((int)keyboardParameters.get("nKeyb") == 0 && UIon){
            dspFaust.deleteVoice(voices[0]);
            voices[0] = -1;
        }
        UIon = false;
        if((zones != null)){
            removeAllViews();
            for(int i=0; i<zones.size(); i++){
                zones.get(i).clear();
            }
            zones.clear();
        }
        zones = null;
        touchDiff = null;
        smooth = null;
        previousTouchedKeyboards = null;
        previousTouchedKeys = null;
        zoneWidths = null;
        monoMode_previousActiveFinger = null;
        moveCount = null;
        voices = null;
        zoneWidths = null;
        fingersOnKeyboardsCount = null;
        rounding = null;
        zoneCenterXOffset = null;
        System.gc(); // don't know if this is actually needed...
    }
    */

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int pointerIndex = event.getActionIndex();
        int pointerId = event.getPointerId(pointerIndex);
        int maskedAction = event.getActionMasked();

        switch (maskedAction) {

            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_POINTER_DOWN: {
                // We have a new pointer. Lets add it to the list of pointers
                PointF point = new PointF();
                point.x = event.getX(pointerIndex);
                point.y = event.getY(pointerIndex);
                mActivePointers.put(pointerId, point);
                touchDiff[pointerId] = 0; // TODO: note sure about this
                processTouchEvent(1,point,pointerId,event);
                break;
            }
            case MotionEvent.ACTION_MOVE: { // a pointer was moved
                for (int size = event.getPointerCount(), i = 0; i < size; i++) {
                    int localPointerId = event.getPointerId(i);
                    PointF point = mActivePointers.get(localPointerId);
                    if (point != null && ((point.x != event.getX(i)) || (point.y != event.getY(i)))) {
                        point.x = event.getX(i);
                        point.y = event.getY(i);
                        if(event.getHistorySize()>0){
                            touchDiff[localPointerId] = Math.abs(point.x - event.getHistoricalX(event.findPointerIndex(localPointerId),0));
                        }
                        else {
                            touchDiff[localPointerId] = 0;
                        }
                        processTouchEvent(2,point,localPointerId,event);
                    }
                }
                break;
            }
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_POINTER_UP:
            case MotionEvent.ACTION_CANCEL: {
                PointF point = new PointF();
                point.x = event.getX(pointerIndex);
                point.y = event.getY(pointerIndex);
                mActivePointers.remove(pointerId);
                touchDiff[pointerId] = -10000;
                processTouchEvent(0,point,pointerId,event);
                break;
            }
        }
        invalidate();

        return true;
    }

    private void processTouchEvent(int eventType, PointF touchPoint, int fingerId, MotionEvent event){
        // we calculate the position of the touch on the keyboards matrix
        int currentKeyboard = Math.min((int)(touchPoint.y/zoneHeight),((int)keyboardParameters.get("nKeyb")-1));
        // clipping the x/y positions to frme size, could potentially be improved
        currentContinuousKey = Math.min(Math.max(0f,touchPoint.x),(float)viewWidth)/(float)zoneWidths[currentKeyboard];
        currentKeyboardY = (Math.min(Math.max(0f,touchPoint.y),(float)viewHeight)/(float)zoneHeight)%1f;
        int currentKeyIdInRow = Math.min((int)currentContinuousKey,((int)keyboardParameters.get(String.format("keyb%d_nKeys",currentKeyboard))-1));
        fingersOnScreenCount = event.getPointerCount();

        // we make sure that the touch happened inside the keyboards matrix area
        if(currentKeyboard >= 0){
            // first we track fingers in the different keyboards (this is necessary to control the number of voices of polyphony of each keybaords)
            if(eventType == 0){ // if touch up
                fingersOnKeyboardsCount[currentKeyboard] = Math.max(0,fingersOnKeyboardsCount[currentKeyboard]-1);
            }
            else if(eventType == 1){ // if touch down
                fingersOnKeyboardsCount[currentKeyboard]++;
            }
            else if(eventType == 2 && currentKeyboard != previousTouchedKeyboards[fingerId]){ // if move
                // counting fingers on the keyboard...
                fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]] = Math.max(0,fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]]-1);
                fingersOnKeyboardsCount[currentKeyboard]++;
            }

            // no poly mode
            if((int)keyboardParameters.get("maxKeybPoly") <= 0){
                sendSynthControlAction(currentKeyboard, currentKeyIdInRow, fingerId);
            }
            // poly mode
            else{
                // deffault mode if poly keyboards
                if((int)keyboardParameters.get("monoMode") == 0 || (int)keyboardParameters.get("maxKeybPoly")>1){
                    // if touch up
                    if(eventType == 0){
                        sendKeyboardAction(0,currentKeyboard,currentKeyIdInRow,fingerId);
                    }
                    // if touch down
                    else if(eventType == 1 && fingersOnKeyboardsCount[currentKeyboard] <= (int)keyboardParameters.get("maxKeybPoly")){
                        sendKeyboardAction(1,currentKeyboard,currentKeyIdInRow,fingerId);
                    }
                    // if move
                    else if(eventType == 2){
                        // moved to another keyboard
                        if(currentKeyboard != previousTouchedKeyboards[fingerId]){
                            // cancel key in previous keyboard
                            sendKeyboardAction(0, previousTouchedKeyboards[fingerId], previousTouchedKeys[fingerId], fingerId);
                            // initiate new event only if there are keys available
                            if(fingersOnKeyboardsCount[currentKeyboard] <= (int)keyboardParameters.get("maxKeybPoly") &&
                                    (int)keyboardParameters.get("interKeybSlideAllowed") == 1){
                                sendKeyboardAction(1, currentKeyboard, currentKeyIdInRow, fingerId);
                            }
                        }
                        // moved to another key within the same keyboard
                        else if(currentKeyIdInRow != previousTouchedKeys[fingerId] &&
                        zones.get(previousTouchedKeyboards[fingerId]).get(previousTouchedKeys[fingerId]).getStatus() == 1){
                            // cancel previous key
                            sendKeyboardAction(3, previousTouchedKeyboards[fingerId], previousTouchedKeys[fingerId], fingerId);
                            // inititate new event
                            sendKeyboardAction(4, currentKeyboard,currentKeyIdInRow, fingerId);
                        }
                        // move within the same key
                        else{
                            sendKeyboardAction(2, currentKeyboard, currentKeyIdInRow, fingerId);
                        }
                    }
                }

                else if((int)keyboardParameters.get("monoMode") == 1){
                    int currentKeyDown = -1;
                    for(int i=0; i<(int)keyboardParameters.get(String.format("keyb%d_nKeys",currentKeyboard)); i++){
                        if(zones.get(currentKeyboard).get(i).getStatus() == 1){
                            currentKeyDown = i;
                        }
                    }

                    // if touch up
                    if(eventType == 0){
                        // cancel corresponding previous key (in case of fast move event)
                        if(previousTouchedKeyboards[fingerId] != currentKeyboard || previousTouchedKeys[fingerId] != currentKeyIdInRow){
                            sendKeyboardAction(0, previousTouchedKeyboards[fingerId], previousTouchedKeys[fingerId], fingerId);
                        }
                        // cancel corresponding key
                        sendKeyboardAction(0, currentKeyboard, currentKeyIdInRow, fingerId);
                        if(fingersOnKeyboardsCount[currentKeyboard]>0 && monoMode_previousActiveFinger[currentKeyboard] == fingerId){
                            float kb = currentKeyboard*zoneHeight;
                            for(int i=0; i<event.getPointerCount(); i++){
                                if(event.getY(i) >= kb &&
                                        event.getY(i) < zoneHeight+kb &&
                                        event.getY(i) != touchPoint.y &&
                                        i != monoMode_previousActiveFinger[currentKeyboard]){
                                    currentContinuousKey = event.getX(i)/zoneWidths[currentKeyboard];
                                    currentKeyIdInRow = Math.min((int)currentContinuousKey,(int)keyboardParameters.get(String.format("keyb%d_nKeys",currentKeyboard))-1);
                                    currentKeyboardY = (Math.min(Math.max(0f,event.getY(i)),(float)viewHeight)/(float)zoneHeight)%1f; // TODO: added on android only
                                    sendKeyboardAction(1, currentKeyboard, currentKeyIdInRow, i);
                                    monoMode_previousActiveFinger[currentKeyboard] = i;
                                    break;
                                }
                            }
                        }
                        else{
                            currentKeyboard = -1;
                            currentKeyIdInRow = -1;
                        }
                    }
                    // if touch down
                    else if(eventType == 1){
                        if(currentKeyDown>=0){
                            sendKeyboardAction(0, currentKeyboard, currentKeyDown, monoMode_previousActiveFinger[currentKeyboard]);
                        }
                        sendKeyboardAction(1, currentKeyboard, currentKeyIdInRow, fingerId);
                        monoMode_previousActiveFinger[currentKeyboard] = fingerId;
                    }
                    // if move
                    else if(eventType == 2){
                        // moved to another keyboard
                        if(currentKeyboard != previousTouchedKeyboards[fingerId]){
                            // cancel key in previous keyboard
                            sendKeyboardAction(0, previousTouchedKeyboards[fingerId], previousTouchedKeys[fingerId], fingerId);

                            if((int)keyboardParameters.get("interKeybSlideAllowed") == 1){
                                // new note if remaining finger in previous keyboard
                                if(previousTouchedKeyboards[fingerId] != -1 &&
                                        fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]]>0 &&
                                        previousTouchedKeys[fingerId] == previousTouchedKeys[monoMode_previousActiveFinger[previousTouchedKeyboards[fingerId]]]){
                                    float kb = previousTouchedKeyboards[fingerId]*zoneHeight;
                                    for(int i=0; i<event.getPointerCount(); i++){
                                        if(event.getY(i) >= kb &&
                                                event.getY(i) < zoneHeight+kb &&
                                                event.getY(i) != touchPoint.y &&
                                                i != monoMode_previousActiveFinger[previousTouchedKeyboards[fingerId]]){
                                            currentContinuousKey = event.getX(i)/zoneWidths[previousTouchedKeyboards[fingerId]];
                                            int localKeyIdInRow = Math.min((int)currentContinuousKey,(int)keyboardParameters.get(String.format("keyb%d_nKeys",previousTouchedKeyboards[fingerId]))-1);
                                            currentKeyboardY = (Math.min(Math.max(0f,event.getY(i)),(float)viewHeight)/(float)zoneHeight)%1f; // TODO: added on android only
                                            sendKeyboardAction(1, previousTouchedKeyboards[fingerId], localKeyIdInRow, i);
                                            monoMode_previousActiveFinger[previousTouchedKeyboards[fingerId]] = i;
                                            break;
                                        }
                                    }
                                }
                                if(currentKeyDown>=0){
                                    sendKeyboardAction(0, currentKeyboard, currentKeyDown, monoMode_previousActiveFinger[currentKeyboard]);
                                }
                                sendKeyboardAction(1, currentKeyboard, currentKeyIdInRow, fingerId);
                                fingersOnKeyboardsCount[currentKeyboard]++; // TODO: added on android only...
                                monoMode_previousActiveFinger[currentKeyboard] = fingerId;
                            }
                        }
                        // moved to another key within the same keyboard
                        else if(currentKeyIdInRow != previousTouchedKeys[fingerId] &&
                                zones.get(previousTouchedKeyboards[fingerId]).get(previousTouchedKeys[fingerId]).getStatus() == 1){
                            if(fingersOnKeyboardsCount[currentKeyboard]>1 && monoMode_previousActiveFinger[currentKeyboard] != fingerId){
                                if(currentKeyDown>=0){
                                    sendKeyboardAction(0, currentKeyboard, currentKeyDown, monoMode_previousActiveFinger[currentKeyboard]);
                                }
                                sendKeyboardAction(1, currentKeyboard, currentKeyIdInRow, fingerId);
                                monoMode_previousActiveFinger[currentKeyboard] = fingerId;
                            }
                            else{
                                // cancel previous key
                                sendKeyboardAction(3, previousTouchedKeyboards[fingerId], previousTouchedKeys[fingerId], fingerId);
                                // inititate new event
                                sendKeyboardAction(4, currentKeyboard, currentKeyIdInRow, fingerId);
                            }
                        }
                        // move within the same key
                        else{
                            sendKeyboardAction(2, currentKeyboard, currentKeyIdInRow, fingerId);
                        }
                    }
                }
            }

            // updating previous data for comparison
            previousTouchedKeyboards[fingerId] = currentKeyboard;
            previousTouchedKeys[fingerId] = currentKeyIdInRow;
        }
        // if touch is outside the keyboards matrix area
        else if(eventType == 2){
            zones.get(previousTouchedKeyboards[fingerId]).get(previousTouchedKeys[fingerId]).setStatus(0);
            fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]] = Math.max(0,fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]]-1);
        }
    }

    private void sendKeyboardAction(int eventType, int keyboardId, int keyId, int fingerId){
        // key up
        if(eventType == 0 || eventType == 3){
            // make sure that the corresponding key is active
            if(zones.get(keyboardId).get(keyId).getStatus() == 1){
                // check if another finger is present in the zone
                boolean otherFingerInKey = false;
                if((int)keyboardParameters.get("monoMode") == 0 || (int)keyboardParameters.get("maxKeybPoly")>1){
                    for(int i=0; i<(int)keyboardParameters.get("maxFingers"); i++){
                        if(keyboardId == previousTouchedKeyboards[i] && keyId == previousTouchedKeys[i] && i != fingerId){
                            otherFingerInKey = true;
                            break;
                        };
                    }
                }
                // key physically up only if there are no more fingers in the zone
                if(!otherFingerInKey){
                    zones.get(keyboardId).get(keyId).setStatus(0);
                }
                sendPolySynthControlAction(eventType, keyboardId, keyId, fingerId);
            }
        }
        // key down
        else if(eventType == 1 || eventType == 4){
            zones.get(keyboardId).get(keyId).setStatus(1);
            sendPolySynthControlAction(eventType, keyboardId, keyId, fingerId);
        }
        // move within the same key
        else if(eventType == 2){
            sendPolySynthControlAction(2, keyboardId, keyId, fingerId);
        }
        if(eventType == 0 && fingersOnScreenCount == 1) resetKeyboard(); // TODO: this is kind of a terrible fix but it does the job for now
    }

    private void sendSynthControlAction(int keyboardId, int keyId, int fingerId){
        // TODO: continuous x and y values are always sent: this should be optimized
        // TODO: might need a mechanism to check if voice is on before message gets sent
        if((int)keyboardParameters.get("sendCurrentKeyboard") == 1) dspFaust.setParamValue("keyboard", keyboardId);
        if((int)keyboardParameters.get("sendCurrentKey") == 1) dspFaust.setParamValue("key", keyId);
        if((int)keyboardParameters.get("sendX") == 1) dspFaust.setParamValue(String.format("x%d",fingerId+1), (currentContinuousKey%1f));
        if((int)keyboardParameters.get("sendY") == 1) dspFaust.setParamValue(String.format("y%d",fingerId+1), currentKeyboardY);
    }

    private void sendPolySynthControlAction(int eventType, int keyboardId, int keyId, int fingerId){
        float pitch = 0; // the MIDI pitch of the note
        // delete (note off)
        if((eventType == 0 || (eventType == 3 &&
                (int)keyboardParameters.get("quantizationMode") == 0)) && voices[fingerId] != -1){
            pitch = -1;
            dspFaust.setVoiceParamValue("gate", voices[fingerId], 0);
            dspFaust.deleteVoice(voices[fingerId]);
            voices[fingerId] = -1;
            smooth[fingerId].reset();
        }
        // new (note on)
        else if (eventType == 1 ||
                (eventType == 4 && (int)keyboardParameters.get("quantizationMode") == 0)){
            // allocating new voice to finger
            voices[fingerId] = dspFaust.newVoice();
            if(voices[fingerId] != -1){
                dspFaust.setVoiceParamValue("gate", voices[fingerId], 1);
            }
            else{
                return;
            }

            // setting first pitch (always quantized)
            if((int)keyboardParameters.get("quantizationMode") == 0 ||
                    ((int)keyboardParameters.get("quantizationMode") == 2 &&
                            (int)keyboardParameters.get(String.format("keyb%d_scale",keyboardId)) > 0)){
                // inverted keyboard
                if((int)keyboardParameters.get(String.format("keyb%d_orientation",keyboardId)) == 1){
                    pitch = applyScale((int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))+
                            (int)keyboardParameters.get(String.format("keyb%d_nKeys",keyboardId))-keyId-1, keyboardId);
                }
                // regular keyboard
                else{
                    pitch = applyScale((int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))+keyId, keyboardId);
                }
            }
            else if((int)keyboardParameters.get("quantizationMode") == 1 || (int)keyboardParameters.get("quantizationMode") == 2){
                float pitchShiftCenter = 0;
                // -0.5 is here to center the pitch at the middle of the key
                if((int)keyboardParameters.get("quantizationMode") == 1){
                    pitchShiftCenter = 0.5f;
                }
                // inverted keyboard
                if((int)keyboardParameters.get(String.format("keyb%d_orientation",keyboardId)) == 1){
                    pitch = applyScale((int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))+
                            (int)keyboardParameters.get(String.format("keyb%d_nKeys",keyboardId))-
                            currentContinuousKey-pitchShiftCenter, keyboardId);
                }
                // regular keyboard
                else{
                    pitch = applyScale(currentContinuousKey +
                            (int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))-
                            pitchShiftCenter, keyboardId);
                }
            }
            if(voices[fingerId] != -1){
                if((int)keyboardParameters.get("quantizationMode") == 1){
                    dspFaust.setVoiceParamValue("freq", voices[fingerId], mtof(pitch));
                }
                else{
                    dspFaust.setVoiceParamValue("freq", voices[fingerId], mtof((float)Math.floor(pitch)));
                }
            }
        }
        // update
        else if(eventType == 2 && ((int)keyboardParameters.get("quantizationMode") == 1 || (int)keyboardParameters.get("quantizationMode") == 2)){

            // Formating pitch
            if((int)keyboardParameters.get(String.format("keyb%d_scale",keyboardId)) > 0 &&
                    rounding[fingerId] && (int)keyboardParameters.get("quantizationMode") != 1){
                // inverted keyboard
                if((int)keyboardParameters.get(String.format("keyb%d_orientation",keyboardId)) == 1){
                    pitch = applyScale((int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))+
                            (int)keyboardParameters.get(String.format("keyb%d_nKeys",keyboardId))-keyId-1, keyboardId);
                }
                // regular keyboard
                else{
                    pitch = applyScale((int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))+keyId, keyboardId);
                }
            }
            else {
                float pitchShiftCenter = 0;
                // -0.5 is here to center the pitch at the middle of the key
                if((int)keyboardParameters.get("quantizationMode") == 1){
                    pitchShiftCenter = 0.5f;
                }
                // inverted keyboard
                if((int)keyboardParameters.get(String.format("keyb%d_orientation",keyboardId)) == 1){
                    pitch = applyScale((int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))+
                            (int)keyboardParameters.get(String.format("keyb%d_nKeys",keyboardId))-currentContinuousKey-pitchShiftCenter, keyboardId);
                }
                // regular keyboard
                else{
                    pitch = applyScale(currentContinuousKey+(int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId))-pitchShiftCenter,keyboardId);
                }
            }

            // sending pitch to faust
            if(voices[fingerId] != -1){
                if((int)keyboardParameters.get("quantizationMode") == 1){
                    dspFaust.setVoiceParamValue("freq", voices[fingerId], mtof(pitch));
                }
                else if((int)keyboardParameters.get("quantizationMode") == 2){
                    if(rounding[fingerId]){ // if rounding is activated, pitch is quantized to the nearest integer
                        dspFaust.setVoiceParamValue("freq", voices[fingerId], mtof((float)Math.floor(pitch)));
                    }
                    else{
                        dspFaust.setVoiceParamValue("freq", voices[fingerId], mtof(pitch-0.5f));
                    }
                }
            }
        }

        if(voices[fingerId] != -1){
            if((int)keyboardParameters.get("sendCurrentKeyboard") == 1) dspFaust.setVoiceParamValue("keyboard", voices[fingerId], keyboardId);
            if((int)keyboardParameters.get("sendCurrentKey") == 1) dspFaust.setVoiceParamValue("key", voices[fingerId], keyId);
            if((int)keyboardParameters.get("sendX") == 1) dspFaust.setVoiceParamValue("x", voices[fingerId], (float)currentContinuousKey%1f);
            if((int)keyboardParameters.get("sendY") == 1) dspFaust.setVoiceParamValue("y", voices[fingerId], currentKeyboardY);
        }
    }

    /* TODO: move to config display
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
    */

    private float applyScale(float pitch, int keyboardId){
        int refPitch = (int)keyboardParameters.get(String.format("keyb%d_lowestKey",keyboardId));
        int currentScale = (int)keyboardParameters.get(String.format("keyb%d_scale",keyboardId)) - 1;
        float keyboardPitch = (pitch-refPitch); // float pitch on keyboard (from 0)
        float scaledPitch = 0; // the final scaled pitch

        int scalesCoeff[][] = {
            {1,1,1,1,1,1,1}, // chromatic
            {2,2,1,2,2,2,1}, // major
            {2,1,2,2,1,3,1} // harm minor
        };

        if(currentScale+1 > 0 && currentScale<4){
            int scaleAdd = 0;
            if(scalesCoeff[currentScale][(int)keyboardPitch%7] == 2){
                for(int i=0; i<(int)keyboardPitch; i++){
                    if(scalesCoeff[currentScale][i%7] == 1) scaleAdd--;
                    else if(scalesCoeff[currentScale][i%7] == 3) scaleAdd++;
                }
            }
            else if(scalesCoeff[currentScale][(int)keyboardPitch%7] == 1){
                for(int i=0; i<(int)keyboardPitch; i++){
                    if(scalesCoeff[currentScale][i%7] == 2) scaleAdd++;
                    else if(scalesCoeff[currentScale][i%7] == 3) scaleAdd+=2;
                }
            }
            else if(scalesCoeff[currentScale][(int)keyboardPitch%7] == 3){
                for(int i=0; i<(int)keyboardPitch; i++){
                    if(scalesCoeff[currentScale][i%7] == 2) scaleAdd--;
                    else if(scalesCoeff[currentScale][i%7] == 1) scaleAdd-=2;
                }
            }

            scaledPitch = refPitch+scaleAdd+
                    (keyboardPitch*scalesCoeff[currentScale][(int)keyboardPitch%7]);
        }
        else{
            scaledPitch = pitch;
        }
        return scaledPitch;
    }

    private float mtof(float note){
        return 440.0f * (float)Math.pow(2.0, (note-69.0)/12.0);
    }

    private void resetKeyboard(){
        dspFaust.allNotesOff();
        for(int i=0; i<(int)keyboardParameters.get("nKeyb"); i++){
            fingersOnKeyboardsCount[i] = 0;
            for(int j=0;j<(int)keyboardParameters.get(String.format("keyb%d_nKeys",i));j++){
                zones.get(i).get(j).setStatus(0);
            }
        }
        for(int i=0; i<(int)keyboardParameters.get("maxFingers"); i++){
            voices[i] = -1;
            previousTouchedKeys[i] = -1;
            previousTouchedKeyboards[i] = -1;
            moveCount[i] = 0;
        }
        fingersOnScreenCount = 0;
    }

    class PitchRounding implements Runnable{
        @Override
        public void run() {
            while(UIon){
                for(int i=0; i<(int)keyboardParameters.get("maxFingers"); i++){
                    if(touchDiff[i] != -10000 && voices[i] != -1){
                        if(smooth[i].tick(touchDiff[i])>(float)keyboardParameters.get("roundingThreshold") &&
                                moveCount[i]<(int)keyboardParameters.get("roundingDeactCycles")){
                            rounding[i] = false;
                        }
                        else{
                            rounding[i] = true;
                            moveCount[i] = 0;
                        }

                        if(touchDiff[i]<1){
                            moveCount[i]++;
                        }
                    }
                }
                try {
                    Thread.sleep(60); // TODO: fix that and see where to put things at the right place
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private final SensorEventListener mSensorListener = new SensorEventListener() {
        public void onSensorChanged(SensorEvent se) {
            // TODO: not sure if this is the same mapping as on iOS...
            if (se.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
                // Update mapping at sensor rate
                dspFaust.propagateAcc(0, se.values[0]);
                dspFaust.propagateAcc(1, se.values[1]);
                dspFaust.propagateAcc(2, se.values[2]);
            }

            if (se.sensor.getType() == Sensor.TYPE_GYROSCOPE) {
                // Update mapping at sensor rate
                dspFaust.propagateGyr(0, se.values[0]);
                dspFaust.propagateGyr(1, se.values[1]);
                dspFaust.propagateGyr(2, se.values[2]);
            }
        }
        public void onAccuracyChanged(Sensor sensor, int accuracy) {}
    };

    @Override
    protected void onLayout(boolean b, int left, int top, int right, int bottom) {
        viewWidth = right-left;
        viewHeight = bottom-top;
        zoneHeight = viewHeight/(int)keyboardParameters.get("nKeyb");
        zoneCenterYOffset = (viewHeight-zoneHeight*(int)keyboardParameters.get("nKeyb"))/2;
        for(int i=0; i<(int)keyboardParameters.get("nKeyb") ; i++) {
            zoneWidths[i] = viewWidth/(int)keyboardParameters.get(String.format("keyb%d_nKeys",i));
            zoneCenterXOffset[i] = (viewWidth-zoneWidths[i]*(int)keyboardParameters.get(String.format("keyb%d_nKeys",i)))/2;
            for(int j=0; j<(int)keyboardParameters.get(String.format("keyb%d_nKeys",i)); j++) {
                int currentLeft = borderSize+zoneCenterXOffset[i]+zoneWidths[i]*j;
                int currentTop = borderSize+zoneCenterYOffset+zoneHeight*i;
                int currentRight = currentLeft+zoneWidths[i]-borderSize*2;
                int currentBottom = currentTop+zoneHeight-borderSize*2;
                zones.get(i).get(j).layout(currentLeft,currentTop,currentRight,currentBottom);
            }
        }
    }
}
