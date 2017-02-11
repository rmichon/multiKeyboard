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
	'Number of Keyboards':'5',
	'Max Keyboard Polyphony':'0',
	'Mono Mode':'1',
	'Rounding Mode':'1',
	'Keyboard 0 - Number of Keys':'19',
	'Keyboard 1 - Number of Keys':'19',
	'Keyboard 2 - Number of Keys':'19',
	'Keyboard 3 - Number of Keys':'19',
	'Keyboard 4 - Number of Keys':'1',
	'Keyboard 4 - Send Freq':'0',
	'Keyboard 0 - Send X':'0',
	'Keyboard 1 - Send X':'0',
	'Keyboard 2 - Send X':'0',
	'Keyboard 3 - Send X':'0',
	'Keyboard 0 - Send Y':'0',
	'Keyboard 1 - Send Y':'0',
	'Keyboard 2 - Send Y':'0',
	'Keyboard 3 - Send Y':'0',
	'Keyboard 0 - Lowest Key':'55',
	'Keyboard 1 - Lowest Key':'62',
	'Keyboard 2 - Lowest Key':'69',
	'Keyboard 3 - Lowest Key':'76',
	'Keyboard 4 - Piano Keyboard':'0'
}";

import("stdfaust.lib");

f = hslider("freq",400,50,2000,0.01);
bend = hslider("bend",1,0,10,0.01);
keyboard = hslider("keyboard",0,0,5,1) : int;
key = hslider("key",0,0,18,1) : int;
x = hslider("x",0.5,0,1,0.01) : si.smoo;
y = hslider("y",0,0,1,0.01) : si.smoo;

freq = f*bend;

velocity = x-x' : abs : an.amp_follower_ar(0.1,1) : *(8000) : min(1);

synth(freq,velocity) = sy.fm((freq,freq + freq*modFreqRatio),index*velocity)*velocity
with{
	index = 1000;
	modFreqRatio = y*0.3;
};

synthSet = par(i,4,synth(localFreq(i),velocity)) :> _
with{
	localFreq(i) = freq : ba.sAndH(keyboard == i) : si.smoo;
};

process = synthSet <: _,_;