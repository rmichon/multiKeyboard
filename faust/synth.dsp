declare interface "SmartKeyboard{
	'nKeyb':'4',
	'maxKeybPoly':'10',
	'keyb0_nKeys':'13',
	'keyb1_nKeys':'13',
	'keyb2_nKeys':'13',
	'keyb3_nKeys':'13',
	'keyb0_lowestKey':'72',
	'keyb1_lowestKey':'67',
	'keyb2_lowestKey':'62',
	'keyb3_lowestKey':'57',
	'keyb0_scale':'1',
	'quantizationMode':'2'
}";

/*
declare interface "SmartKeyboard{
	'nKeyb':'1',
	'maxKeybPoly':'-1',
	'keyb0_nKeys':'1'
}";
*/

import("stdfaust.lib");
	
topGroup(x) = vgroup("SmartKeyboard",x);
freq = topGroup(hslider("freq",300,50,2000,0.01)) : si.polySmooth(gate,0.999,2);
//freq = topGroup(hslider("freq",300,50,2000,0.01)) : si.smoo;
// gain = topGroup(hslider("gain [acc: 1 0 -10 0 10]",1,0,1,0.01));
gain = topGroup(hslider("gain",1,0,1,0.01));
gate = topGroup(button("gate"));
//cutoff = topGroup(hslider("y1",1,0,1,0.001))*5000+50 : si.smoo;
cutoff = topGroup(hslider("y",1,0,1,0.001))*5000+50 : si.smoo;

process = os.sawtooth(freq)*(gate*gain : si.smoo) : fi.lowpass(3,cutoff) <: _,_;