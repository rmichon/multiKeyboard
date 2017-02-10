/*
 * multiSynth.dsp
 * 
 * An instrument with 4 keyboards implementing different
 * synthesizers. This code demonstrates how a keyboard can be
 * assigned to a specific synth.
 * 
 * Version 0.0, Feb. 2017
 * Copyright Romain Michon GRAME/CCRMA (Stanford University) 2017
 * MIT Licence: https://opensource.org/licenses/MIT
 * 
 */

// Interface with 4 polyphnic keyboards of 13 keys with the same config
declare interface "SmartKeyboard{
	'Number of Keyboards':'6',
	'Max Keyboard Polyphony':'1',
	'Mono Mode':'1',
	'Keyboard 0 - Number of Keys':'13',
	'Keyboard 1 - Number of Keys':'13',
	'Keyboard 2 - Number of Keys':'13',
	'Keyboard 3 - Number of Keys':'13',
	'Keyboard 4 - Number of Keys':'13',
	'Keyboard 5 - Number of Keys':'13',
	'Keyboard 0 - Lowest Key':'72',
	'Keyboard 1 - Lowest Key':'67',
	'Keyboard 2 - Lowest Key':'62',
	'Keyboard 3 - Lowest Key':'57',
	'Keyboard 4 - Lowest Key':'52',
	'Keyboard 5 - Lowest Key':'47',
	'Rounding Mode':'2'
}";

import("stdfaust.lib");

// standard parameters
f = hslider("freq",300,50,2000,0.01);
// smoothAndH is necessary here since bend is set back to 0 when gate = 0
bend = hslider("bend[midi:pitchwheel]",1,0,10,0.01) : si.smoothAndH(gate+os.impulse,0.999);
gain = hslider("gain",1,0,1,0.01);
s = hslider("sustain[midi:ctrl 64]",0,0,1,1); // for sustain pedal
gate = button("gate");
y = hslider("y[midi:ctrl 1]",1,0,1,0.001) : si.smoo;
keyboard = hslider("keyboard",0,0,1,1) : int;
key = hslider("key",0,0,1,1) : int;

freq = f*bend : max(60);

noiseburst = no.noise : *(gate : ba.impulsify : trigger(P))
with {
	 P = ma.SR/(freq+300);
  	 diffgtz(x) = x != x';
  	 decay(n,x) = x - (x>0)/n;
  	 release(n) = + ~ decay(n);
  	 trigger(n) = diffgtz : release(n) : > (0.0);
};

bridge(B,t60,x) = dampingFilter(rho,h0,h1,x)
with{
	dampingFilter(rho,h0,h1,x) = rho * (h0 * x' + h1*(x+x''));
	h0 = (1.0 + B)/2;
	h1 = (1.0 - B)/4;
	rho = pow(0.001,1.0/(freq*t60));
};

string = +~(de.fdelay4(2048,n) : bridge(0.5,1))
with{
	n = ma.SR/freq;
};

process = noiseburst : fi.lowpass(2,freq*5) : string <: _,_;
