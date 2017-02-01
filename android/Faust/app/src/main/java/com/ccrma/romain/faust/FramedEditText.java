package com.ccrma.romain.faust;

import android.content.Context;
import android.view.Gravity;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;

public class FramedEditText extends ViewGroup {
    public EditText text;

    public FramedEditText(Context context) {
        super(context);

        text = new EditText(context);
        text.setGravity(Gravity.CENTER);
        text.setSingleLine(true);
        text.setImeOptions(EditorInfo.IME_ACTION_DONE);
        text.setBackground(null);
        addView(text);
    }

    @Override
    protected void onLayout(boolean b, int i, int i1, int i2, int i3) {
        int width = i2-i;
        int height = i3-i1;
        text.measure(0,0);
        int measuredTextHeight = text.getMeasuredHeight();
        int measuredTextWidth = text.getMeasuredWidth();
        text.layout(0,
                (height-measuredTextHeight)/2,
                width,
                (height+measuredTextHeight)/2);
    }
}
