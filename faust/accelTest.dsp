import("stdfaust.lib");

f = hslider("f[acc: 0 0 -10 0 10]",500,200,800,0.01) : si.smoo;

process = os.sawtooth(f)*0.8 <: _,_;