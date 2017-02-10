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
	'Number of Keyboards':'4',
	'Rounding Mode':'2',
	'Keyboard 0 - Number of Keys':'13',
	'Keyboard 1 - Number of Keys':'13',
	'Keyboard 2 - Number of Keys':'13',
	'Keyboard 3 - Number of Keys':'13',
	'Keyboard 0 - Lowest Key':'60',
	'Keyboard 1 - Lowest Key':'60',
	'Keyboard 2 - Lowest Key':'60',
	'Keyboard 3 - Lowest Key':'60'
}";

import("stdfaust.lib");

// standard parameters
f = hslider("freq",300,50,2000,0.01);
// smoothAndH is necessary here since bend is set back to 0 when gate = 0
bend = hslider("bend[midi:pitchwheel]",1,0,10,0.01) : si.smoothAndH(gate,0.999);
gain = hslider("gain",1,0,1,0.01);
s = hslider("sustain[midi:ctrl 64]",0,0,1,1); // for sustain pedal
t = button("gate");
y = hslider("y[midi:ctrl 1]",1,0,1,0.001) : si.smoo;
keyboard = hslider("keyboard",0,0,1,1) : int;
key = hslider("key",0,0,1,1) : int;

// fomating parameters
gate = t+s : min(1);
freq = f*bend;
cutoff = y*4000+50;

// oscillators
oscilators(0) = os.sawtooth(freq);
oscilators(1) = os.triangle(freq);
oscilators(2) = os.square(freq);
oscilators(3) = os.osc(freq);

// Put osc in parallel, choose them in function of keyboard
// and apply filter, envelope and gain
synths = par(i,4,select2(keyboard == i,0,oscilators(i))) :> fi.lowpass(3,cutoff) : *(envelope)
with{
	envelope = gate*gain : si.smoo;	
};

process = synths <: _,_; // stereo for effect