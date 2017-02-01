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
    private TextView hLabel;
    private VerticalTextView vLabel;
    private int orientation;

    public boolean on;
    public boolean polarity;
    public int tag;

    private OnButtonStatusChangedListener mButtonStatusChangedListener = null;

    public interface OnButtonStatusChangedListener {
        void OnButtonStatusChanged(Button source);
    }

    public Button(Context context, int orient) {
        super(context);

        orientation = orient;
        on = false;

        layerOn = new TextView(context);
        layerOn.setBackgroundColor(Color.GREEN);
        layerOn.setVisibility(INVISIBLE);
        addView(layerOn);

        if(orientation == 0) {
            hLabel = new TextView(context);
            hLabel.setTextColor(Color.BLACK);
            addView(hLabel);
        }
        else if(orientation == 1) {
            vLabel = new VerticalTextView(context);
            vLabel.setTextColor(Color.BLACK);
            addView(vLabel);
        }
    }

    @Override
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
    }

    public void setOff(){
        layerOn.setVisibility(INVISIBLE);
        on = false;
        if (mButtonStatusChangedListener != null) {
            mButtonStatusChangedListener.OnButtonStatusChanged(this);
        }
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
        if(orientation == 0) {
            hLabel.setText(t);
        }
        else if(orientation == 1){
            vLabel.setText(t);
        }
    }

    public void setTextColor(int color){
        if(orientation == 0) {
            hLabel.setTextColor(color);
        }
        else if(orientation == 1){
            vLabel.setTextColor(color);
        }
    }

    public void setTextSize(float size){
        if(orientation == 0) {
            hLabel.setTextSize(size);
        }
        else if(orientation == 1){
            vLabel.setTextSize(size);
        }
    }

    public void setTextBold(){
        if(orientation == 0){
            hLabel.setTypeface(null, Typeface.BOLD);
        }
        else if(orientation == 1){
            vLabel.setTypeface(null, Typeface.BOLD);
        }
    }


    @Override
    protected void onLayout(boolean b, int i, int i1, int i2, int i3) {
        int width = i2-i;
        int height = i3-i1;
        layerOn.layout(0,0,width,height);
        if(orientation == 0) {
            hLabel.measure(0, 0);
            int measuredTextHeight = hLabel.getMeasuredHeight();
            int measuredTextWidth = hLabel.getMeasuredWidth();
            hLabel.layout((width - measuredTextWidth) / 2,
                    (height - measuredTextHeight) / 2,
                    (width + measuredTextWidth) / 2,
                    (height + measuredTextHeight) / 2);
        }
        else if(orientation == 1) {
            vLabel.measure(0, 0);
            int measuredTextHeight = vLabel.getMeasuredHeight();
            int measuredTextWidth = vLabel.getMeasuredWidth();
            vLabel.layout((width - measuredTextWidth) / 2,
                    (height - measuredTextHeight) / 2,
                    (width + measuredTextWidth) / 2,
                    (height + measuredTextHeight) / 2);
        }
    }
}
