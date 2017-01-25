package com.ccrma.romain.faust;

import android.content.Context;
import android.graphics.Color;
import android.view.ViewGroup;
import android.widget.ScrollView;

import com.DspFaust.DspFaust;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Map;

class ConfigDisplay extends ViewGroup{
    private Map<String,Object> keyboardParameters;
    private Map<String,Object> dspParameters;
    private DspFaust dspFaust;

    public ConfigDisplay(Context context) {
        super(context);

        setBackgroundColor(Color.GREEN);
    }

    @Override
    protected void onLayout(boolean b, int left, int top, int right, int bottom) {

    }

    class KeyboardParams extends ScrollView{
        private ParamsList paramsList;

        public KeyboardParams(Context context) {
            super(context);

            paramsList = new ParamsList(context);
            addView(paramsList);
        }

        class ParamsList extends ViewGroup {
            private ArrayList<String> keyboardKeys;

            public ParamsList(Context context) {
                super(context);

                // retrieve the existing parameter keys and order alphabetically
                /*
                for (String key : keyboardParameters.keySet()) {
                    keyboardKeys.add(key);
                }
                Collections.sort(keyboardKeys, String.CASE_INSENSITIVE_ORDER);
                */

            }

            @Override
            protected void onLayout(boolean b, int left, int top, int right, int bottom) {

            }
        }

        @Override
        protected void onLayout(boolean b, int left, int top, int right, int bottom) {
            //paramsList.layout();
        }
    }
}
