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
	'keyb0_scale':'1',
	'keyb0_lowestKey':'77',
	'keyb1_lowestKey':'72',
	'keyb2_lowestKey':'67',
	'keyb3_lowestKey':'62',
	'keyb4_lowestKey':'57',
	'quantizationMode':'2'
}";


import("stdfaust.lib");
	
fadeDelay(n,d,tau) = _ <: fdelay1(n,delLength1)*(gsmooth),fdelay1(n,delLength2)*(1-gsmooth) :> _
with{
	swit(t) = +(t)~_ : %(2);
	g = (d != d') & (stringsBending < 0.00001) & (stringsBendingDry == 0) & (stringFreqInterpTime(i) == 0) : swit; //'
	gsmooth = g : smooth(tau2pole(tau));
	hold(t,x) = (_*(t)+(x'*(t != t'))~_)*t + x*(1-t);
	delLength1 = hold(1-g,d) : min(15000) : max(1);
	delLength2 = hold(g,d) : min(15000) : max(1);
};



process = os.sawtooth(freq) : fi.lowpass(3,cutoff)*(gate*gain : si.smoo) <: _,_;