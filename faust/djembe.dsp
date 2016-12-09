declare interface "SmartKeyboard{
	'nKeyb':'2',
	'keyb0_nKeys':'2',
	'keyb1_nKeys':'1',
	'keyb0_keybMode':'false',
	'keyb1_keybMode':'false'
}";

import("stdfaust.lib");

N = 20;

topGroup(x) = vgroup("SmartKeyboard",x);
theta = topGroup(hslider("angle",0,-1*ma.PI,ma.PI,0.001)) : si.smoo;
exGain = topGroup(hslider("exGain",1,0,1,0.01));
x = topGroup(hslider("x",0.5,0,1,0.01)*2-1 : abs);
y = topGroup(hslider("y",0.5,0,1,0.01)*2-1 : abs);
exPos = min(x,y);
gate = topGroup(button("gate")) : ba.impulsify;
keyboard = topGroup(hslider("keyboard",0,0,1,1)) : int;
key = topGroup(hslider("key",0,0,1,1)) : int;
freq = topGroup(hslider("baseFreq",60,40,500,0.01));
t60Scaler = topGroup(hslider("t60Scaler",1,0,1,0.01));

filter(f,t60) = fi.tf2(b0,b1,b2,a1,a2)
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

mode(i,baseFreq,t60) = *(inGains(i)) : filter(baseFreq+(200*i),(N-i)*t60*0.03)*(1/(i+1));
impulsify = _ <: _,mem : - : >(0);


offset = *(cond1) : +~*(cond2) : /(i)
with{
	cond1 = status==0;
	cond2 = 1-((status'==1) & (status==0)); //'
	i = *(cond2)+(1-cond2)~+(cond1); //'
};

noiseburst(g,P) = no.noise : *(g : trigger(P))
with {
  //diffgtz(x) = (x-x') > 0; //'
  diffgtz(x) = x!=x'; //'
  decay(n,x) = x - (x>0)/n;
  release(n) = + ~ decay(n);
  trigger(n) = diffgtz : release(n) : > (0.0);
  ppdel = beta*P; // pick position delay
  pickposfilter = fi.ffcombfilter(4096,ppdel,-1);
};

djembe(j) = (noiseburst(gate,ma.SR/(300)))*exGain : fi.highpass(2,40+exPos*500) : fi.lowpass(2,500+exPos*15000) <: 
	par(i,N,mode(i,baseFreq,t60Scaler)) :> _
with{
	baseFreq = freq*(j+1);
};


process = djembe(2-(keyboard*2+key))*0.1 ;
	


