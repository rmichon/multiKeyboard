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
	'quantizationMode':'2'
}";

import("stdfaust.lib");

polySmooth(g,s) = si.smooth(s*((g==g') | (g == 0))); //'
	
freq = hslider("freq",300,50,2000,0.01) : si.polySmooth(gate,0.999,1);
gain = hslider("gain",1,0,1,0.01);
gate = button("gate");
cutoff = hslider("y",1,0,1,0.001)*5000+50 : si.smoo;

process = os.sawtooth(freq)*(gate : si.smoo)*gain : fi.lowpass(3,cutoff);