declare interface "SmartKeyboard{
	'nKeyb':'1',
	'maxKeybPoly':'-1',
	'keyb0_nKeys':'1'
}";

import("stdfaust.lib");
	
topGroup(x) = vgroup("SmartKeyboard",x);
freq = topGroup(hslider("freq",300,50,2000,0.01)) : si.polySmooth(gate,0.999,2);
gain = topGroup(hslider("gain",1,0,1,0.01));
gate = topGroup(button("gate"));
cutoff = topGroup(hslider("x0",1,0,1,0.001))*5000+50 : si.smoo;

process = os.sawtooth(freq)*(gate*gain : si.smoo) : fi.lowpass(3,cutoff) <: _,_;