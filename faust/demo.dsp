declare interface "SmartKeyboard{
	'Number of Keyboards':'2',
	'Max Keyboard Polyphony':'10',
	'Keyboard 0 - Number of Keys':'1',
	'Keyboard 0 - Mode':'2',
	'Keyboard 1 - Number of Keys':'13',
	'Keyboard 1 - Send X':'0'
}";

import("stdfaust.lib");

keyboard = nentry("keyboard",0,0,1,1);

freq = nentry("freq",200,40,2000,0.01) : si.polySmooth(gate,0.999,2);
gain = nentry("gain",1,0,1,0.01) : si.polySmooth(gate,0.999,2);
gate = button("gate") : si.smoo;
//gate = 1;
//cutoff = nentry("cutoff",5000,40,2000,0.01) : si.polySmooth(gate,0.999,2);

x0 = nentry("x",0.5,0,1,0.01) : ba.sAndH(keyboard != 0) : si.smoo;
cutoff = x0*5000+100;

//x0 = nentry("x0",0.5,0,1,0.01) : si.smoo;
//freq = x0*2000+80;

process = os.sawtooth(freq)*gain*gate : fi.lowpass(3,cutoff) <: _,_;
