//#################################### mySynth.dsp #######################################
// Simple Faust instruments specifically designed for `faust2smartkeyb` where 2
// parallel keyboards are used to control a simple synth based on a sawtooth
// oscillator.
//
// ## `SmartKeyboard` Use Strategy
//
// `SmartKeyboard` is used in a very simple way here simply to control the pitch
// the gain and the note-off/on events of the synth. Continuous pitch control is
// enabled and a sustain pedal can be used if a MIDI keyboard is connected to
// the device.
//
// ## Compilation Instructions
//
// This Faust code will compile fine with any of the standard Faust targets. However
// it was specifically designed to be used with `faust2smartkeyb`. For best results,
// we recommend to use the following parameters to compile it:
//
// ```
// faust2smartkeyb [-ios/-android] -effect myEffect.dsp mySynth.dsp
// ```
//
// ## Version/Licence
//
// Version 0.0, Feb. 2017
// Copyright Romain Michon CCRMA (Stanford University)/GRAME 2017:
// https://ccrma.stanford.edu/~rmichon
// MIT Licence: https://opensource.org/licenses/MIT
//########################################################################################

// 2 polyphonic keyboards of one octave in parallel
declare interface "SmartKeyboard{
    'Number of Keyboards':'2',
	'Rounding Mode':'2',
    'Keyboard 0 - Number of Keys':'13',
    'Keyboard 1 - Number of Keys':'13',
    'Keyboard 0 - Lowest Key':'72',
    'Keyboard 1 - Lowest Key':'60'
}";

import("stdfaust.lib");

// parameters
f = nentry("freq",200,40,2000,0.01);
bend = nentry("bend[midi:pitchwheel]",1,0,10,0.01) : si.polySmooth(gate,0.999,1);
s = nentry("sustain[midi:ctrl 64]",0,0,1,1);
g = nentry("gain",1,0,1,0.01);
t = button("gate");
y = nentry("y",0.5,0,1,0.01);

// trigger signal is a mix of the sustain pedal and note-on/off
gate = t+s : min(1);
// freq is continuous thanks to bend
freq = f*bend;
// MIDI gain and y position of the finger on the keyboard
gain = y*g;
// exponential envelope
envelope = gate*gain : si.smoo;

// synth...
process = os.sawtooth(freq)*envelope <: _,_;