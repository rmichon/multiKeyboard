package com.ccrma.romain.faust;

import android.content.Context;
import android.view.ViewGroup;
import android.widget.TextView;

public class FramedTextView extends ViewGroup {
    public TextView text;

    public FramedTextView(Context context) {
        super(context);

        text = new TextView(context);
        addView(text);
    }

    @Override
    protected void onLayout(boolean b, int i, int i1, int i2, int i3) {
        int width = i2-i;
        int height = i3-i1;
        text.measure(0,0);
        int measuredTextHeight = text.getMeasuredHeight();
        int measuredTextWidth = text.getMeasuredWidth();
        text.layout((width-measuredTextWidth)/2,
                (height-measuredTextHeight)/2,
                (width+measuredTextWidth)/2,
                (height+measuredTextHeight)/2);
    }
}
