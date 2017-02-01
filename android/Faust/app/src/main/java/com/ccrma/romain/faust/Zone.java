package com.ccrma.romain.faust;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.ActionBar;
import android.util.AttributeSet;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class Zone extends ViewGroup {

    private Context context;

    private TextView text;
    private View layerOn;
    private String[] notes = {"C","C#","D","Eb","E","F","F#","G","G#","A","Bb","B"};

    private int keyNote;
    public int status;
    public boolean keyboardMode;

    private int measuredTextHeight;

    public Zone(Context c) {
        super(c);
        // TODO: something here was required for multitouch on iOS

        // setting defaults
        context = c;
        keyboardMode = true;
        status = 0;
        setBackgroundColor(Color.GRAY);

        // Status "on" layer
        layerOn = new View(context);
        // TODO: something about making this multitouch here too
        layerOn.setBackgroundColor(Color.WHITE); // default key color when on
        layerOn.setVisibility(INVISIBLE);
        addView(layerOn);

        // Button label placed at the center of the button
        text = new TextView(context);
        text.setTextSize(32); // not sure if this is the same as on iOS...
        text.setTextColor(Color.BLACK);
        text.measure(0,0);
        measuredTextHeight = text.getMeasuredHeight(); // for centering text
        addView(text);
    }

    @Override
    protected void onLayout(boolean b, int i, int i1, int i2, int i3) {
        int width = i2-i;
        int height = i3-i1;
        layerOn.layout(0,0,width,height);
        text.measure(0,0);
        int measuredTextHeight = text.getMeasuredHeight();
        int measuredTextWidth = text.getMeasuredWidth();
        text.layout((width-measuredTextWidth)/2,
                (height-measuredTextHeight)/2,
                (width+measuredTextWidth)/2,
                (height+measuredTextHeight)/2);
    }

    public void setText(String t){
        text.setText(t);
    }

    public void setTextSize(float size){
        text.setTextSize(size);
    }

    public void setNote(int note){
        keyNote = note%12;
        setText(notes[keyNote]);
    }

    public void drawBackground(){
        if(keyboardMode &&
                (keyNote == 1 ||
                        keyNote == 3 ||
                        keyNote == 6 ||
                        keyNote == 8 ||
                        keyNote == 10)){
            layerOn.setBackground(ContextCompat.getDrawable(context, R.drawable.key_down_dark));
            setBackground(ContextCompat.getDrawable(context, R.drawable.key_up_dark));
        }
        else{
            layerOn.setBackground(ContextCompat.getDrawable(context, R.drawable.key_down_bright));
            setBackground(ContextCompat.getDrawable(context, R.drawable.key_up_bright));
        }
    }

    public void setStatus(int s){
        status = s;
        if(keyboardMode){
            if(status == 1){
                layerOn.setVisibility(VISIBLE);
            }
            else{
                layerOn.setVisibility(INVISIBLE);
            }
        }
    }

    public void setKeyboardMode(boolean mode){
        keyboardMode = mode;
    }

    public int getStatus(){
        return status;
    }
}
