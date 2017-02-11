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
	'Number of Keyboards':'1',
	'Keyboard 0 - Mode':'2',
	'Keyboard 0 - Number of Keys':'2',
	'Keyboard 0 - Send Freq':'0',
	'Keyboard 0 - Piano Keyboard':'0'
}";

import("stdfaust.lib");

f = hslider("freq",300,50,2000,0.01);
// smoothAndH is necessary here since bend is set back to 0 when gate = 0
bend = hslider("bend[midi:pitchwheel]",1,0,10,0.01) : si.smoothAndH(gate,0.999);
gain = hslider("gain",1,0,1,0.01);
key = hslider("key",0,0,1,1) : int;
x = hslider("x[midi:ctrl 1]",0.5,0,1,0.01) : si.smoo;
y = hslider("y",0.5,0,1,0.01);
s = hslider("sustain[midi:ctrl 64]",0,0,1,1); // for sustain pedal
t = button("gate");

// fomating parameters
gate = t+s : min(1);
freq = f*bend;
index = (x : ba.sAndH(key == 0))*1000;
modFreqRatio = x : ba.sAndH(key == 1);

envelope = gain*gate : si.smoo;

process = sy.fm((freq,freq + freq*modFreqRatio),index*envelope)*envelope <: _,_;