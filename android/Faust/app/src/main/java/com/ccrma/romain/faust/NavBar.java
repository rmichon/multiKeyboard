package com.ccrma.romain.faust;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.support.v4.content.ContextCompat;
import android.view.ViewGroup;

class NavBar extends ViewGroup{
    private Button buttons[];
    private int orientation;
    private Context context;
    private int textOnColor;
    private int textOffColor;

    private OnNavBarStatusChangedListener mNavBarStatusChangedListener = null;

    public interface OnNavBarStatusChangedListener {
        void OnNavBarButtonTouched(int buttonID);
    }

    public NavBar(Context c, int orient) {
        super(c);

        context = c;
        setBackgroundColor(Color.BLACK);

        orientation = orient;
        buttons = new Button[5];

        textOffColor = Color.argb((int)(255*1), (int)(255*0), (int)(255*0.0), (int)(255*0.0));
        textOnColor = Color.argb((int)(255*1), (int)(255*0.9), (int)(255*0.9), (int)(255*0.9));

        float fontSize = 24;

        String buttonsLabel[] = {"Home", "Settings", "- Preset", "+ Preset", "Flip"};

        for(int i=0; i<buttons.length; i++) {
            buttons[i] = new Button(context,orientation);
            buttons[i].tag = i;
            buttons[i].setOnImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_on));
            buttons[i].setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_off));
            buttons[i].setTextColor(textOffColor);
            buttons[i].setTextSize(fontSize);
            buttons[i].setText(buttonsLabel[i]);
            buttons[i].setOnButtonStatusChangedListener(new Button.OnButtonStatusChangedListener() {
                @Override
                public void OnButtonStatusChanged(Button source) {
                    if (source.on) {
                        if(source.tag == 1){
                            if(source.polarity){
                                source.setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_on));
                                buttons[2].setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_on));
                                buttons[3].setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_on));
                                buttons[4].setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_on));
                                source.setTextColor(textOnColor);
                            }
                            else{
                                source.setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_off));
                                buttons[2].setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_off));
                                buttons[3].setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_off));
                                buttons[4].setOffImage(ContextCompat.getDrawable(context, R.drawable.nav_bar_buttons_off));
                                source.setTextColor(textOffColor);
                            }
                        }
                        if (mNavBarStatusChangedListener != null) {
                            mNavBarStatusChangedListener.OnNavBarButtonTouched(source.tag);
                        }
                    }
                }
            });
            addView(buttons[i]);
        }
    }

    public void setOnNavBarStatusChangedListener(OnNavBarStatusChangedListener listener) {
        mNavBarStatusChangedListener = listener;
    }

    @Override
    protected void onLayout(boolean b, int left, int top, int right, int bottom) {
        int borderSize = 2; // TODO might have to be adjusted
        int width = right-left;
        int height = bottom-top;
        int buttonsWidth = width/buttons.length;
        int buttonsHeight = height/buttons.length;
        for(int i=0; i<buttons.length; i++){
            if(orientation == 0) {
                buttons[i].layout(borderSize+buttonsWidth*i,borderSize,buttonsWidth*(1+i)-borderSize*2,height-borderSize*2);
            }
            else{
                buttons[i].layout(borderSize,borderSize+buttonsHeight*i,width-borderSize*2,buttonsHeight*(1+i)-borderSize*2);
            }
        }
    }
}
