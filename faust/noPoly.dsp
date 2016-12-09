declare interface "SmartKeyboard{
	'nKeyb':'1',
	'maxKeybPoly':'0',
	'keyb0_nKeys':'1'
}";

import("stdfaust.lib");
	
freq = hslider("x0",0,0,1,0.01)*1000+50 : si.smoo;
//freq = hslider("[midi:ctrl 42]frequency",60,0,127,1)/127*1000+50 : si.smoo;
gain = hslider("y0",1,0,1,0.01) : si.smoo;
cutoff = hslider("y1",1,0,1,0.001)*5000+50 : si.smoo;

process = os.sawtooth(freq)*gain : fi.lowpass(3,cutoff);