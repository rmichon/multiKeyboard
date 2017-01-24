package com.ccrma.romain.faust;

import android.content.Context;
import android.view.ViewGroup;

import com.DspFaust.DspFaust;

public class InstrumentInterface extends ViewGroup {
    public InstrumentInterface(Context context, DspFaust dspFaust, int presetId) {
        super(context);
    }

    @Override
    protected void onLayout(boolean b, int i, int i1, int i2, int i3) {

    }
}
