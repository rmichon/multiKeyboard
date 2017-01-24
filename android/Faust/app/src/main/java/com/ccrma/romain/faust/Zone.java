package com.ccrma.romain.faust;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.support.v7.app.ActionBar;
import android.util.AttributeSet;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class Zone extends ViewGroup {
    // TODO: remove
    /*
    private OnCurrentItemChangedListener mCurrentItemChangedListener = null;

    public interface OnCurrentItemChangedListener {
        void OnCurrentItemChanged(Zone source);
    }
    */

    private Context context;

    private TextView text;
    private View layerOn;
    private String[] notes = {"C","C#","D","Eb","E","F","F#","G","G#","A","Bb","B"};
    private Bitmap darkImageOn, darkImageOff, brightImageOn, brightImageOff;

    private int keyNote;
    public int status;
    public boolean keyboardMode;

    public Zone(Context c) {
        super(c);
        // TODO: something here was required for multitouch on iOS

        // setting defaults
        context = c;
        keyboardMode = true;
        status = 0;
        darkImageOn = BitmapFactory.decodeResource(context.getResources(),R.drawable.key_down_dark);
        darkImageOff = BitmapFactory.decodeResource(context.getResources(),R.drawable.key_up_dark);
        brightImageOn = BitmapFactory.decodeResource(context.getResources(),R.drawable.key_down_bright);
        brightImageOff = BitmapFactory.decodeResource(context.getResources(),R.drawable.key_up_bright);
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
        text.setTextAlignment(TEXT_ALIGNMENT_CENTER);
        text.setTextColor(Color.BLACK);
        addView(text);
    }

    @Override
    protected void onLayout(boolean b, int i, int i1, int i2, int i3) {
        layerOn.layout(0,0,i2-i,i3-i1);
        text.layout(0,0,i2-i,i3-i1);
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
            layerOn.setBackground(new BitmapDrawable(context.getResources(),darkImageOn));
            setBackground(new BitmapDrawable(context.getResources(),darkImageOff));
        }
        else{
            layerOn.setBackground(new BitmapDrawable(context.getResources(),brightImageOn));
            setBackground(new BitmapDrawable(context.getResources(),brightImageOff));
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
