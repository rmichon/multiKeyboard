declare interface "SmartKeyboard{
	'Number of Keyboards':'5',
	'Max Keyboard Polyphony':'1',
	'Inter-Keyboard Slide':'1',
	'Mono Mode':'1',
	'Keyboard 0 - Number of Keys':'13',
	'Keyboard 1 - Number of Keys':'13',
	'Keyboard 2 - Number of Keys':'13',
	'Keyboard 3 - Number of Keys':'13',
	'Keyboard 4 - Number of Keys':'13',
	'Keyboard 0 - Scale':'3',
	'Keyboard 0 - Lowest Key':'77',
	'Keyboard 1 - Lowest Key':'72',
	'Keyboard 2 - Lowest Key':'67',
	'Keyboard 3 - Lowest Key':'62',
	'Keyboard 4 - Lowest Key':'57',
	'Rounding Mode':'2'
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
freq = topGroup(hslider("freq",300,50,2000,0.01)) : si.polySmooth(gate,0.999,1);
//freq = topGroup(hslider("freq",300,50,2000,0.01)) : si.smoo;
// gain = topGroup(hslider("gain [acc: 1 0 -10 0 10]",1,0,1,0.01));
gain = topGroup(hslider("gain",1,0,1,0.01));
gate = topGroup(button("gate"));
//cutoff = topGroup(hslider("y1",1,0,1,0.001))*5000+50 : si.smoo;
//cutoff = topGroup(hslider("yu[acc: 0 0 -10 0 10]",1,0,1,0.001))*5000+50 : si.smoo;
cutoff = topGroup(hslider("y",1,0,1,0.001))*5000+50 : si.smoo;

process = os.sawtooth(freq) : fi.lowpass(3,cutoff)*(gate*gain : si.smoo) <: _,_;
