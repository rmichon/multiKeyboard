declare interface "SmartKeyboard{
	'nKeyb':'1',
	'maxKeybPoly':'-1',
	'keyb0_nKeys':'1'
}";

import("stdfaust.lib");
	
freq = hslider("v:synth/v:standardParams/freq",300,50,2000,0.01) : si.polySmooth(gate,0.999,1);
gain = hslider("v:synth/v:standardParams/gain",1,0,1,0.01);
gate = button("v:synth/v:standardParams/gate");
x = hslider("v:synth/v:standardParams/x",1,0,1,0.001);
y = hslider("v:synth/v:standardParams/x1",1,0,1,0.001);
keyboard = hslider("v:synth/v:standardParams/keyboard",0,0,1,1) : int;
key = hslider("v:synth/v:standardParams/key",0,0,1,1) : int;

// filtered sawtooth
sawSynth  = os.sawtooth(freq) : fi.lowpass(3,cutoff) : *(envelope)
with{
	cutoff = y*5000+50 : si.smoo;
	envelope = gate*gain : si.smoo;
};
	
process = sawSynth <: _,_;
