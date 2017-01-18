declare interface "SmartKeyboard{
	'nKeyb':'2',
	'keyb0_nKeys':'2',
	'keyb1_nKeys':'1',
	'keyb0_keybMode':'0',
	'keyb1_keybMode':'0'
}";

import("stdfaust.lib");
	
freq = hslider("v:synth/v:standardParams/freq",300,50,2000,0.01) : si.polySmooth(gate,0.999,1);
gain = hslider("v:synth/v:standardParams/gain",1,0,1,0.01);
gate = button("v:synth/v:standardParams/gate");
x = hslider("v:synth/v:standardParams/x",1,0,1,0.001);
y = hslider("v:synth/v:standardParams/y",1,0,1,0.001);
keyboard = hslider("v:synth/v:standardParams/keyboard",0,0,1,1) : int;
key = hslider("v:synth/v:standardParams/key",0,0,1,1) : int;

// djembe physical model
djembe = (noiseburst(gate,ma.SR/(300)))*exGain : fi.highpass(2,40+exPos*500) : fi.lowpass(2,500+exPos*15000) <: 
	par(i,N,mode(i,baseFreq,t60Scaler)) :> *(0.1)
with{
	N = 20;
	theta = hslider("v:synth/v:djembe/angle",0,-1*ma.PI,ma.PI,0.001);
	exGain = hslider("v:synth/v:djembe/exGain",1,0,1,0.01);
	t60Scaler = hslider("v:synth/v:djembe/t60Scaler",1,0,1,0.01);
	bFreq = hslider("v:synth/v:djembe/baseFreq",60,40,500,0.01);
	exPos = min((x*2-1 : abs),(y*2-1 : abs));
	j = 2-(keyboard*2+key);
	baseFreq = bFreq*(j+1);
	modeFilter(f,t60) = fi.tf2(b0,b1,b2,a1,a2)
		with{
		b0 = 1;
		b1 = 0;
		b2 = -1;
		w = 2*ma.PI*f/ma.SR;
		r = pow(0.001,1/float(t60*ma.SR));
		a1 = -2*r*cos(w);
		a2 = r^2;
	};
	inGains(i) = cos((i+1)*theta)/float(i+1);
	mode(i,baseFreq,t60) = *(inGains(i)) : modeFilter(baseFreq+(200*i),(N-i)*t60*0.03)*(1/(i+1));
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
};
	
process = djembe <: _,_;
