/*
 * drums.dsp
 * 
 * Faust instrument specifically designed for faust2smartkeyb where
 * 3 drums can controlled using pads.
 * The SmartKeyboard interface is configured to only have 3 keys,
 * each of them implementing a drum pad. Every time one of the pads
 * is touched, a new note is instanciated. The base frequency of each
 * drum is computed in function of the key ID in the interface. X
 * and Y finger positions are used to compute the strike position
 * on the virtual membrane. Drum sounds are computed with a simple
 * physical model.
 * 
 * Version 0.0, Feb. 2017
 * Copyright Romain Michon GRAME/CCRMA (Stanford University) 2017
 * MIT Licence: https://opensource.org/licenses/MIT
 * 
 */

// Interface with 2 keyboards of 2 and 1 keys (3 pads)
// Mode 1 is used so that key names are not diplayed and the
// color of the key doesn't change when touching it.
declare interface "SmartKeyboard{
	'Number of Keyboards':'2',
	'Keyboard 0 - Number of Keys':'2',
	'Keyboard 1 - Number of Keys':'1',
	'Keyboard 0 - Mode':'1',
	'Keyboard 1 - Mode':'1'
}";

import("stdfaust.lib");

// standard parameters
gate = button("gate");
x = hslider("x",1,0,1,0.001);
y = hslider("y",1,0,1,0.001);
keyboard = hslider("keyboard",0,0,1,1) : int;
key = hslider("key",0,0,1,1) : int;

// other parameters
outGain = hslider("outGain",0.1,0,1,0.01);
theta = hslider("angle",0,-1*ma.PI,ma.PI,0.001);
t60Scaler = hslider("t60Scaler",1,0,1,0.01);
bFreq = hslider("baseFreq",60,40,500,0.01);

// drum modal physical model
// TODO: eventually, should use the Faust physical modeling library
// for this...
drum = excitation <: par(i,N,mode(i,baseFreq,t60Scaler)) :> *(outGain)
with{
	// number of modes
	N = 20;
	// excitation position
	exPos = min((x*2-1 : abs),(y*2-1 : abs));
	// retrieving pad number (0-2)
	j = 2-(keyboard*2+key);
	// drum root freq is computed in function of pad number
	baseFreq = bFreq*(j+1);

	// biquad taking freq and t60 as arguments
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

	// computing the gain of each filter
	inGains(i) = cos((i+1)*theta)/float(i+1);
	// computing each modes, why is this done like this, cus it sounds goooood...
	mode(i,baseFreq,t60) = *(inGains(i)) : modeFilter(baseFreq+(200*i),(N-i)*t60*0.03)*(1/(i+1));
	// noise excitation
	noiseburst = no.noise : *(gate : ba.impulsify : trigger(P))
	with {
		 P = ma.SR/300;
  		 diffgtz(x) = x != x';
  		 decay(n,x) = x - (x>0)/n;
  		 release(n) = + ~ decay(n);
  		 trigger(n) = diffgtz : release(n) : > (0.0);
	};

	// excitation: filtered noise burst. filters change in function of x/y position
	excitation = noiseburst : fi.highpass(2,40+exPos*500) : fi.lowpass(2,500+exPos*15000);
};

process = drum <: _,_; // stereo for effect chain