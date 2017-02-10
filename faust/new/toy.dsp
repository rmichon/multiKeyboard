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
	'Max Keyboard Polyphony':'0',
	'Keyboard 0 - Number of Keys':'1'
}";

import("stdfaust.lib");

x0 = hslider("x0",0.5,0,1,0.01);
y0 = hslider("y0",0.5,0,1,0.01);
y1 = hslider("y1",0,0,1,0.01);
q = hslider("q[acc: 0 0 -10 0 10]",30,10,50,0.01) : si.smoo;
del = hslider("del[acc: 0 0 -10 0 10]",0.5,0.01,1,0.01) : si.smoo;
fb = hslider("fb[acc: 1 0 -10 0 10]",0.5,0,1,0.01) : si.smoo;

impFreq = 2 + x0*20;
resFreq = y0*3000+300;

echo = +~(de.delay(65536,del*ma.SR)*fb);

process = os.lf_imptrain(impFreq) : fi.resonlp(resFreq,q,1) : echo : ef.cubicnl(y1,0)*0.95 <: _,_;