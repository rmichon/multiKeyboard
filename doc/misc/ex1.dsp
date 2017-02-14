//###################################### ex1.dsp ########################################
// Simple Faust instrument specifically designed with `faust2smartkeyb` where 2
// parallel piano keyboards are used to control a polyphonic synthesizer.
//
// ## Compilation Instructions
//
// This Faust code will compile fine with any of the standard Faust targets. However
// it was specifically designed to be used with `faust2smartkeyb`. For best results,
// we recommend to use the following parameters to compile it:
//
// ```
// faust2smartkeyb [-ios/-android] ex1.dsp
// ```
//
// ## Version/Licence
//
// Version 0.0, Feb. 2017
// Copyright Romain Michon CCRMA (Stanford University)/GRAME 2017: https://ccrma.stanford.edu/~rmichon
// MIT Licence: https://opensource.org/licenses/MIT
//########################################################################################

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// INTERFACE DECLARATION
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// Interface with 2 keyboards of 13 keys, one octave appart from each other
declare interface "SmartKeyboard{
    'Number of Keyboards':'2',
    'Keyboard 0 - Number of Keys':'13',
    'Keyboard 1 - Number of Keys':'13',
    'Keyboard 0 - Lowest Key':'72',
    'Keyboard 1 - Lowest Key':'60'
}";

import("stdfaust.lib");

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// STANDARD PARAMETERS
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
freq = nentry("freq",200,40,2000,0.01);
gain = nentry("gain",1,0,1,0.01);
gate = button("gate");
y = nentry("y",0.5,0,1,0.01) : si.smoo; // y is always normalized between 0 and 1

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// MAPPING
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cutoff = y*1960+40;
envelope = gate*gate : si.smoo;

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// SYNTHESIS
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
process = os.sawtooth(freq)*envelope : fi.lowpass(3,cutoff) <: _,_;