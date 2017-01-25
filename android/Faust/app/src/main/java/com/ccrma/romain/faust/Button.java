package com.ccrma.romain.faust;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class Button extends ViewGroup {
    private View layerOn;
    private TextView label;

    public boolean on;
    public boolean polarity;
    public int tag;

    private OnButtonStatusChangedListener mButtonStatusChangedListener = null;

    public interface OnButtonStatusChangedListener {
        void OnButtonStatusChanged(Button source);
    }

    public Button(Context context) {
        super(context);

        on = false;

        layerOn = new TextView(context);
        layerOn.setBackgroundColor(Color.GREEN);
        layerOn.setVisibility(INVISIBLE);
        addView(layerOn);

        label = new TextView(context);
        label.setTextAlignment(TEXT_ALIGNMENT_CENTER);
        label.setTextColor(Color.BLACK);
        addView(label);

    }

    @Override // TODO: this has to be checked
    public boolean onTouchEvent(MotionEvent e) {
        switch (e.getAction()) {
            case MotionEvent.ACTION_DOWN:
                setOn();
                return true;
            case MotionEvent.ACTION_UP:
                setOff();
                return true;
        }
        return true;
    }

    public void setOnButtonStatusChangedListener(OnButtonStatusChangedListener listener) {
        mButtonStatusChangedListener = listener;
    }

    public void setOn(){
        layerOn.setVisibility(VISIBLE);
        on = true;
        if(polarity) polarity = false;
        else polarity = true;
        if (mButtonStatusChangedListener != null) {
            mButtonStatusChangedListener.OnButtonStatusChanged(this);
        }
        // TODO sender action goes here
    }

    public void setOff(){
        layerOn.setVisibility(INVISIBLE);
        on = false;
        if (mButtonStatusChangedListener != null) {
            mButtonStatusChangedListener.OnButtonStatusChanged(this);
        }
        // TODO sender action goes here
    }

    public void setOffColor(int offColor){
        setBackgroundColor(offColor);
    }

    public void setOnColor(int onColor){
        layerOn.setBackgroundColor(onColor);
    }

    public void setOnImage(Drawable image){
        layerOn.setBackground(image);
    }

    public void setOffImage(Drawable image){
        setBackground(image);
    }

    public boolean getPolarity(){
        return polarity;
    }

    public void setText(String t){
        label.setText(t);
    }

    public void setTextColor(int color){
        label.setTextColor(color);
    }

    public void setTextSize(float size){
        label.setTextSize(size);
    }

    public void setTextBold(){ label.setTypeface(null, Typeface.BOLD); }


    @Override
    protected void onLayout(boolean b, int i, int i1, int i2, int i3) {
        layerOn.layout(0,0,i2-i,i3-i1);
        label.layout(0,0,i2-i,i3-i1);
    }
}
