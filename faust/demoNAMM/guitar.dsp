declare interface "SmartKeyboard{
	'nKeyb':'5',
	'maxKeybPoly':'1',
	'interKeybSlideAllowed':'1',
	'monoMode':'1',
	'keyb0_nKeys':'13',
	'keyb1_nKeys':'13',
	'keyb2_nKeys':'13',
	'keyb3_nKeys':'13',
	'keyb4_nKeys':'13',
	'keyb0_lowestKey':'72',
	'keyb1_lowestKey':'67',
	'keyb2_lowestKey':'62',
	'keyb3_lowestKey':'57',
	'keyb4_lowestKey':'52',
	'quantizationMode':'2'
}";

import("stdfaust.lib");
	
freq = hslider("v:synth/v:standardParams/freq",300,50,2000,0.01) : si.polySmooth(gate,0.999,1);
gain = hslider("v:synth/v:standardParams/gain",1,0,1,0.01);
gate = button("v:synth/v:standardParams/gate");
x = hslider("v:synth/v:standardParams/x",1,0,1,0.001);
y = hslider("v:synth/v:standardParams/y",1,0,1,0.001);
keyboard = hslider("v:synth/v:standardParams/keyboard",0,0,1,1) : int;
key = hslider("v:synth/v:standardParams/key",0,0,1,1) : int;

// simple ks
ks = excitation : +~(de.fdelay4(delMax,delLength) <: (_+_')/2 : *(damping))
with{
	delMax = 1024;
	delLength = ma.SR/freq;
	noiseburst(g,P) = no.noise : *(g : ba.impulsify : trigger(P))
	with {
  		diffgtz(x) = x!=x'; //'
  		decay(n,x) = x - (x>0)/n;
  		release(n) = + ~ decay(n);
  		trigger(n) = diffgtz : release(n) : > (0.0);
  		ppdel = beta*P; // pick position delay
  		pickposfilter = fi.ffcombfilter(4096,ppdel,-1);
  		baseFreq = freq*(j+1);
	};
	excitation = noiseburst(gate,ma.SR/(300)) : fi.lowpass(2,50+y*4000);
	damping = hslider("v:synth/v:string/damping",0.9,0,1,0.01)*0.1 + 0.9;
};
	
process = ks <: _,_;
