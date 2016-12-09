//----------------------------------------------------------
//
// Code generated with Faust 0.9.92 (http://faust.grame.fr)
//----------------------------------------------------------

/* link with  */
#include <math.h>
#ifndef FAUSTPOWER
#define FAUSTPOWER
#include <cmath>
template <int N> inline int faustpower(int x)              { return faustpower<N/2>(x) * faustpower<N-N/2>(x); } 
template <> 	 inline int faustpower<0>(int x)            { return 1; }
template <> 	 inline int faustpower<1>(int x)            { return x; }
template <> 	 inline int faustpower<2>(int x)            { return x*x; }
template <int N> inline float faustpower(float x)            { return faustpower<N/2>(x) * faustpower<N-N/2>(x); } 
template <> 	 inline float faustpower<0>(float x)          { return 1; }
template <> 	 inline float faustpower<1>(float x)          { return x; }
template <> 	 inline float faustpower<2>(float x)          { return x*x; }
#endif
/************************************************************************
 ************************************************************************
    FAUST Architecture File
    Copyright (C) 2003-2011 GRAME, Centre National de Creation Musicale
    ---------------------------------------------------------------------

    This is sample code. This file is provided as an example of minimal
    FAUST architecture file. Redistribution and use in source and binary
    forms, with or without modification, in part or in full are permitted.
    In particular you can create a derived work of this FAUST architecture
    and distribute that work under terms of your choice.

    This sample code is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 ************************************************************************
 ************************************************************************/
 
#include <math.h>
#include <algorithm>

/************************************************************************
    FAUST Architecture File
    Copyright (C) 2003-2016 GRAME, Centre National de Creation Musicale
    ---------------------------------------------------------------------
    This Architecture section is free software; you can redistribute it
    and/or modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 3 of
    the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; If not, see <http://www.gnu.org/licenses/>.

    EXCEPTION : As a special exception, you may create a larger work
    that contains this FAUST architecture section and distribute
    that work under terms of your choice, so long as this FAUST
    architecture section is not modified.


 ************************************************************************
 ************************************************************************/
 
#ifndef FAUST_UI_H
#define FAUST_UI_H

#ifndef FAUSTFLOAT
#define FAUSTFLOAT float
#endif

/*******************************************************************************
 * UI : Faust User Interface
 * This abstract class contains only the method that the faust compiler can
 * generate to describe a DSP interface.
 ******************************************************************************/

class UI
{

    public:

        UI() {}

        virtual ~UI() {}

        // -- widget's layouts

        virtual void openTabBox(const char* label) = 0;
        virtual void openHorizontalBox(const char* label) = 0;
        virtual void openVerticalBox(const char* label) = 0;
        virtual void closeBox() = 0;

        // -- active widgets

        virtual void addButton(const char* label, FAUSTFLOAT* zone) = 0;
        virtual void addCheckButton(const char* label, FAUSTFLOAT* zone) = 0;
        virtual void addVerticalSlider(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step) = 0;
        virtual void addHorizontalSlider(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step) = 0;
        virtual void addNumEntry(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step) = 0;

        // -- passive widgets

        virtual void addHorizontalBargraph(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max) = 0;
        virtual void addVerticalBargraph(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max) = 0;

        // -- metadata declarations

        virtual void declare(FAUSTFLOAT*, const char*, const char*) {}
};

//----------------------------------------------------------------
//  Generic decorator
//----------------------------------------------------------------

class DecoratorUI : public UI
{
    protected:
    
        UI* fUI;

    public:
    
        DecoratorUI(UI* ui = 0):fUI(ui)
        {}

        virtual ~DecoratorUI() { delete fUI; }

        // -- widget's layouts
        virtual void openTabBox(const char* label)          { fUI->openTabBox(label); }
        virtual void openHorizontalBox(const char* label)   { fUI->openHorizontalBox(label); }
        virtual void openVerticalBox(const char* label)     { fUI->openVerticalBox(label); }
        virtual void closeBox()                             { fUI->closeBox(); }

        // -- active widgets
        virtual void addButton(const char* label, FAUSTFLOAT* zone)         { fUI->addButton(label, zone); }
        virtual void addCheckButton(const char* label, FAUSTFLOAT* zone)    { fUI->addCheckButton(label, zone); }
        virtual void addVerticalSlider(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
            { fUI->addVerticalSlider(label, zone, init, min, max, step); }
        virtual void addHorizontalSlider(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step) 	
            { fUI->addHorizontalSlider(label, zone, init, min, max, step); }
        virtual void addNumEntry(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step) 			
            { fUI->addNumEntry(label, zone, init, min, max, step); }

        // -- passive widgets	
        virtual void addHorizontalBargraph(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max) 
            { fUI->addHorizontalBargraph(label, zone, min, max); }
        virtual void addVerticalBargraph(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max)
            { fUI->addVerticalBargraph(label, zone, min, max); }

        virtual void declare(FAUSTFLOAT* zone, const char* key, const char* val) { fUI->declare(zone, key, val); }

};

#endif
/************************************************************************
 ************************************************************************
    FAUST Architecture File
	Copyright (C) 2003-2011 GRAME, Centre National de Creation Musicale
    ---------------------------------------------------------------------
    This Architecture section is free software; you can redistribute it
    and/or modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 3 of
	the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
	along with this program; If not, see <http://www.gnu.org/licenses/>.

 ************************************************************************
 ************************************************************************/
 
#ifndef __meta__
#define __meta__

struct Meta
{
    virtual void declare(const char* key, const char* value) = 0;
    virtual ~Meta() {};
};

#endif
/************************************************************************
    IMPORTANT NOTE : this file contains two clearly delimited sections :
    the ARCHITECTURE section (in two parts) and the USER section. Each section
    is governed by its own copyright and license. Please check individually
    each section for license and copyright information.
*************************************************************************/

/*******************BEGIN ARCHITECTURE SECTION (part 1/2)****************/

/************************************************************************
    FAUST Architecture File
    Copyright (C) 2003-2011 GRAME, Centre National de Creation Musicale
    ---------------------------------------------------------------------
    This Architecture section is free software; you can redistribute it
    and/or modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 3 of
    the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; If not, see <http://www.gnu.org/licenses/>.

    EXCEPTION : As a special exception, you may create a larger work
    that contains this FAUST architecture section and distribute
    that work under terms of your choice, so long as this FAUST
    architecture section is not modified.

 ************************************************************************
 ************************************************************************/
 
/******************************************************************************
*******************************************************************************

								FAUST DSP

*******************************************************************************
*******************************************************************************/

#ifndef __dsp__
#define __dsp__

#ifndef FAUSTFLOAT
#define FAUSTFLOAT float
#endif

class UI;
struct Meta;

/**
* Signal processor definition.
*/

class dsp {

    public:

        dsp() {}
        virtual ~dsp() {}

        /* Return instance number of audio inputs */
        virtual int getNumInputs() = 0;
    
        /* Return instance number of audio outputs */
        virtual int getNumOutputs() = 0;
    
        /**
         * Trigger the UI* parameter with instance specific calls
         * to 'addBtton', 'addVerticalSlider'... in order to build the UI.
         *
         * @param ui_interface - the UI* user interface builder
         */
        virtual void buildUserInterface(UI* ui_interface) = 0;
    
        /* Returns the sample rate currently used by the instance */
        virtual int getSampleRate() = 0;
    
        /** Global init, calls the following methods :
         * - static class 'classInit' : static table initialisation
         * - 'instanceInit' : constants and instance table initialisation
         *
         * @param samplingRate - the sampling rate in Herz
         */
        virtual void init(int samplingRate) = 0;
    
        /** Init instance state
         *
         * @param samplingRate - the sampling rate in Herz
         */
        virtual void instanceInit(int samplingRate) = 0;
    
        /** Init instance constant state
         *
         * @param samplingRate - the sampling rate in Herz
         */
        virtual void instanceConstants(int samplingRate) = 0;
    
        /* Init default control parameters values */
        virtual void instanceResetUserInterface() = 0;
    
        /* Init instance state (delay lines...) */
        virtual void instanceClear() = 0;
    
        /**  
         * Return a clone of the instance.
         *
         * @return a copy of the instance on success, otherwise a null pointer.
         */
        virtual dsp* clone() = 0;
    
        /**
         * Trigger the Meta* parameter with instance specific calls to 'declare' (key, value metadata).
         *
         * @param m - the Meta* meta user
         */
        virtual void metadata(Meta* m) = 0;
    
        /**
         * DSP instance computation, to be called with sucessive in/out audio buffers.
         *
         * @param count - the nomber of frames to compute
         * @param inputs - the input audio buffers as an array of non-interleaved FAUSTFLOAT samples (eiher float, doucbe or quad)
         * @param outputs - the output audio buffers as an array of non-interleaved FAUSTFLOAT samples (eiher float, doucbe or quad)
         *
         */
        virtual void compute(int count, FAUSTFLOAT** inputs, FAUSTFLOAT** outputs) = 0;
    
        /**
         * DSP instance computation : alternative method to be used by subclasses.
         *
         * @param date_usec - the timestamp in microsec given by audio driver.
         * @param count - the nomber of frames to compute
         * @param inputs - the input audio buffers as an array of non-interleaved FAUSTFLOAT samples (eiher float, doucbe or quad)
         * @param outputs - the output audio buffers as an array of non-interleaved FAUSTFLOAT samples (eiher float, doucbe or quad)
         *
         */
        virtual void compute(double date_usec, int count, FAUSTFLOAT** inputs, FAUSTFLOAT** outputs) { compute(count, inputs, outputs); }
       
};

/**
 * Generic DSP decorator.
 */

class decorator_dsp : public dsp {

    protected:

        dsp* fDSP;

    public:

        decorator_dsp(dsp* dsp = 0):fDSP(dsp) {}
        virtual ~decorator_dsp() { delete fDSP; }

        virtual int getNumInputs() { return fDSP->getNumInputs(); }
        virtual int getNumOutputs() { return fDSP->getNumOutputs(); }
        virtual void buildUserInterface(UI* ui_interface) { fDSP->buildUserInterface(ui_interface); }
        virtual int getSampleRate() { return fDSP->getSampleRate(); }
        virtual void init(int samplingRate) { fDSP->init(samplingRate); }
        virtual void instanceInit(int samplingRate) { fDSP->instanceInit(samplingRate); }
        virtual void instanceConstants(int samplingRate) { fDSP->instanceConstants(samplingRate); }
        virtual void instanceResetUserInterface() { fDSP->instanceResetUserInterface(); }
        virtual void instanceClear() { fDSP->instanceClear(); }
        virtual decorator_dsp* clone() { return new decorator_dsp(fDSP->clone()); }
        virtual void metadata(Meta* m) { return fDSP->metadata(m); }
        virtual void compute(int count, FAUSTFLOAT** inputs, FAUSTFLOAT** outputs) { fDSP->compute(count, inputs, outputs); }
        virtual void compute(double date_usec, int count, FAUSTFLOAT** inputs, FAUSTFLOAT** outputs) { fDSP->compute(date_usec, count, inputs, outputs); }
       
};

/**
 * On Intel set FZ (Flush to Zero) and DAZ (Denormals Are Zero)
 * flags to avoid costly denormals.
 */

#ifdef __SSE__
    #include <xmmintrin.h>
    #ifdef __SSE2__
        #define AVOIDDENORMALS _mm_setcsr(_mm_getcsr() | 0x8040)
    #else
        #define AVOIDDENORMALS _mm_setcsr(_mm_getcsr() | 0x8000)
    #endif
#else
    #define AVOIDDENORMALS
#endif

#endif

using std::max;
using std::min;

/******************************************************************************
*******************************************************************************

							       VECTOR INTRINSICS

*******************************************************************************
*******************************************************************************/


/******************************************************************************
*******************************************************************************

			ABSTRACT USER INTERFACE

*******************************************************************************
*******************************************************************************/

//----------------------------------------------------------------------------
//  FAUST generated signal processor
//----------------------------------------------------------------------------

#ifndef FAUSTFLOAT
#define FAUSTFLOAT float
#endif  


#ifndef FAUSTCLASS 
#define FAUSTCLASS effect
#endif

class effect : public dsp {
  private:
	FAUSTFLOAT 	fslider0;
	float 	fRec0[2];
	FAUSTFLOAT 	fslider1;
	float 	fRec1[2];
	int 	IOTA;
	float 	fVec0[8192];
	float 	fConst0;
	float 	fConst1;
	FAUSTFLOAT 	fslider2;
	FAUSTFLOAT 	fslider3;
	float 	fConst2;
	FAUSTFLOAT 	fslider4;
	float 	fConst3;
	FAUSTFLOAT 	fslider5;
	float 	fConst4;
	float 	fConst5;
	FAUSTFLOAT 	fslider6;
	FAUSTFLOAT 	fslider7;
	float 	fConst6;
	FAUSTFLOAT 	fslider8;
	float 	fRec14[2];
	float 	fRec13[2];
	float 	fVec1[8192];
	float 	fConst7;
	int 	iConst8;
	float 	fVec2[1024];
	int 	iConst9;
	float 	fRec11[2];
	float 	fConst10;
	float 	fConst11;
	float 	fRec18[2];
	float 	fRec17[2];
	float 	fVec3[8192];
	float 	fConst12;
	int 	iConst13;
	float 	fVec4[2048];
	int 	iConst14;
	float 	fRec15[2];
	float 	fConst15;
	float 	fConst16;
	float 	fRec22[2];
	float 	fRec21[2];
	float 	fVec5[8192];
	float 	fConst17;
	int 	iConst18;
	float 	fVec6[2048];
	int 	iConst19;
	float 	fRec19[2];
	float 	fConst20;
	float 	fConst21;
	float 	fRec26[2];
	float 	fRec25[2];
	float 	fVec7[8192];
	float 	fConst22;
	int 	iConst23;
	float 	fVec8[1024];
	int 	iConst24;
	float 	fRec23[2];
	float 	fConst25;
	float 	fConst26;
	float 	fRec30[2];
	float 	fRec29[2];
	float 	fVec9[16384];
	float 	fConst27;
	int 	iConst28;
	float 	fVec10[2048];
	int 	iConst29;
	float 	fRec27[2];
	float 	fConst30;
	float 	fConst31;
	float 	fRec34[2];
	float 	fRec33[2];
	float 	fVec11[8192];
	float 	fConst32;
	int 	iConst33;
	float 	fVec12[2048];
	int 	iConst34;
	float 	fRec31[2];
	float 	fConst35;
	float 	fConst36;
	float 	fRec38[2];
	float 	fRec37[2];
	float 	fVec13[16384];
	float 	fConst37;
	int 	iConst38;
	float 	fVec14[2048];
	int 	iConst39;
	float 	fRec35[2];
	float 	fConst40;
	float 	fConst41;
	float 	fRec42[2];
	float 	fRec41[2];
	float 	fVec15[16384];
	float 	fConst42;
	int 	iConst43;
	float 	fVec16[1024];
	int 	iConst44;
	float 	fRec39[2];
	float 	fRec3[3];
	float 	fRec4[3];
	float 	fRec5[3];
	float 	fRec6[3];
	float 	fRec7[3];
	float 	fRec8[3];
	float 	fRec9[3];
	float 	fRec10[3];
	float 	fRec2[3];
	FAUSTFLOAT 	fslider9;
	FAUSTFLOAT 	fslider10;
	float 	fRec43[3];
	float 	fRec45[3];
	float 	fRec44[3];
	int fSamplingFreq;

  public:
	virtual void metadata(Meta* m) { 
		m->declare("reverb.lib/name", "Faust Reverb Library");
		m->declare("reverb.lib/version", "0.0");
		m->declare("math.lib/name", "Faust Math Library");
		m->declare("math.lib/version", "2.0");
		m->declare("math.lib/author", "GRAME");
		m->declare("math.lib/copyright", "GRAME");
		m->declare("math.lib/license", "LGPL with exception");
		m->declare("signal.lib/name", "Faust Signal Routing Library");
		m->declare("signal.lib/version", "0.0");
		m->declare("delay.lib/name", "Faust Delay Library");
		m->declare("delay.lib/version", "0.0");
		m->declare("filter.lib/name", "Faust Filter Library");
		m->declare("filter.lib/version", "2.0");
		m->declare("basic.lib/name", "Faust Basic Element Library");
		m->declare("basic.lib/version", "0.0");
		m->declare("route.lib/name", "Faust Signal Routing Library");
		m->declare("route.lib/version", "0.0");
	}

	virtual int getNumInputs() { return 1; }
	virtual int getNumOutputs() { return 2; }
	static void classInit(int samplingFreq) {
	}
	virtual void instanceConstants(int samplingFreq) {
		fSamplingFreq = samplingFreq;
		fConst0 = min(1.92e+05f, max(1.0f, (float)fSamplingFreq));
		fConst1 = (6.2831855f / fConst0);
		fConst2 = (0.001f * fConst0);
		fConst3 = (6.2831855f / float(fConst0));
		fConst4 = floorf(((0.153129f * fConst0) + 0.5f));
		fConst5 = ((0 - (6.9077554f * fConst4)) / fConst0);
		fConst6 = (3.1415927f / fConst0);
		fConst7 = floorf(((0.020346f * fConst0) + 0.5f));
		iConst8 = int((int((fConst4 - fConst7)) & 8191));
		iConst9 = int((int((fConst7 + -1)) & 1023));
		fConst10 = floorf(((0.174713f * fConst0) + 0.5f));
		fConst11 = ((0 - (6.9077554f * fConst10)) / fConst0);
		fConst12 = floorf(((0.022904f * fConst0) + 0.5f));
		iConst13 = int((int((fConst10 - fConst12)) & 8191));
		iConst14 = int((int((fConst12 + -1)) & 2047));
		fConst15 = floorf(((0.127837f * fConst0) + 0.5f));
		fConst16 = ((0 - (6.9077554f * fConst15)) / fConst0);
		fConst17 = floorf(((0.031604f * fConst0) + 0.5f));
		iConst18 = int((int((fConst15 - fConst17)) & 8191));
		iConst19 = int((int((fConst17 + -1)) & 2047));
		fConst20 = floorf(((0.125f * fConst0) + 0.5f));
		fConst21 = ((0 - (6.9077554f * fConst20)) / fConst0);
		fConst22 = floorf(((0.013458f * fConst0) + 0.5f));
		iConst23 = int((int((fConst20 - fConst22)) & 8191));
		iConst24 = int((int((fConst22 + -1)) & 1023));
		fConst25 = floorf(((0.210389f * fConst0) + 0.5f));
		fConst26 = ((0 - (6.9077554f * fConst25)) / fConst0);
		fConst27 = floorf(((0.024421f * fConst0) + 0.5f));
		iConst28 = int((int((fConst25 - fConst27)) & 16383));
		iConst29 = int((int((fConst27 + -1)) & 2047));
		fConst30 = floorf(((0.192303f * fConst0) + 0.5f));
		fConst31 = ((0 - (6.9077554f * fConst30)) / fConst0);
		fConst32 = floorf(((0.029291f * fConst0) + 0.5f));
		iConst33 = int((int((fConst30 - fConst32)) & 8191));
		iConst34 = int((int((fConst32 + -1)) & 2047));
		fConst35 = floorf(((0.256891f * fConst0) + 0.5f));
		fConst36 = ((0 - (6.9077554f * fConst35)) / fConst0);
		fConst37 = floorf(((0.027333f * fConst0) + 0.5f));
		iConst38 = int((int((fConst35 - fConst37)) & 16383));
		iConst39 = int((int((fConst37 + -1)) & 2047));
		fConst40 = floorf(((0.219991f * fConst0) + 0.5f));
		fConst41 = ((0 - (6.9077554f * fConst40)) / fConst0);
		fConst42 = floorf(((0.019123f * fConst0) + 0.5f));
		iConst43 = int((int((fConst40 - fConst42)) & 16383));
		iConst44 = int((int((fConst42 + -1)) & 1023));
	}
	virtual void instanceResetUserInterface() {
		fslider0 = -2e+01f;
		fslider1 = 0.0f;
		fslider2 = 315.0f;
		fslider3 = 0.0f;
		fslider4 = 6e+01f;
		fslider5 = 6e+03f;
		fslider6 = 2.0f;
		fslider7 = 3.0f;
		fslider8 = 2e+02f;
		fslider9 = 1.5e+03f;
		fslider10 = 0.0f;
	}
	virtual void instanceClear() {
		for (int i=0; i<2; i++) fRec0[i] = 0;
		for (int i=0; i<2; i++) fRec1[i] = 0;
		IOTA = 0;
		for (int i=0; i<8192; i++) fVec0[i] = 0;
		for (int i=0; i<2; i++) fRec14[i] = 0;
		for (int i=0; i<2; i++) fRec13[i] = 0;
		for (int i=0; i<8192; i++) fVec1[i] = 0;
		for (int i=0; i<1024; i++) fVec2[i] = 0;
		for (int i=0; i<2; i++) fRec11[i] = 0;
		for (int i=0; i<2; i++) fRec18[i] = 0;
		for (int i=0; i<2; i++) fRec17[i] = 0;
		for (int i=0; i<8192; i++) fVec3[i] = 0;
		for (int i=0; i<2048; i++) fVec4[i] = 0;
		for (int i=0; i<2; i++) fRec15[i] = 0;
		for (int i=0; i<2; i++) fRec22[i] = 0;
		for (int i=0; i<2; i++) fRec21[i] = 0;
		for (int i=0; i<8192; i++) fVec5[i] = 0;
		for (int i=0; i<2048; i++) fVec6[i] = 0;
		for (int i=0; i<2; i++) fRec19[i] = 0;
		for (int i=0; i<2; i++) fRec26[i] = 0;
		for (int i=0; i<2; i++) fRec25[i] = 0;
		for (int i=0; i<8192; i++) fVec7[i] = 0;
		for (int i=0; i<1024; i++) fVec8[i] = 0;
		for (int i=0; i<2; i++) fRec23[i] = 0;
		for (int i=0; i<2; i++) fRec30[i] = 0;
		for (int i=0; i<2; i++) fRec29[i] = 0;
		for (int i=0; i<16384; i++) fVec9[i] = 0;
		for (int i=0; i<2048; i++) fVec10[i] = 0;
		for (int i=0; i<2; i++) fRec27[i] = 0;
		for (int i=0; i<2; i++) fRec34[i] = 0;
		for (int i=0; i<2; i++) fRec33[i] = 0;
		for (int i=0; i<8192; i++) fVec11[i] = 0;
		for (int i=0; i<2048; i++) fVec12[i] = 0;
		for (int i=0; i<2; i++) fRec31[i] = 0;
		for (int i=0; i<2; i++) fRec38[i] = 0;
		for (int i=0; i<2; i++) fRec37[i] = 0;
		for (int i=0; i<16384; i++) fVec13[i] = 0;
		for (int i=0; i<2048; i++) fVec14[i] = 0;
		for (int i=0; i<2; i++) fRec35[i] = 0;
		for (int i=0; i<2; i++) fRec42[i] = 0;
		for (int i=0; i<2; i++) fRec41[i] = 0;
		for (int i=0; i<16384; i++) fVec15[i] = 0;
		for (int i=0; i<1024; i++) fVec16[i] = 0;
		for (int i=0; i<2; i++) fRec39[i] = 0;
		for (int i=0; i<3; i++) fRec3[i] = 0;
		for (int i=0; i<3; i++) fRec4[i] = 0;
		for (int i=0; i<3; i++) fRec5[i] = 0;
		for (int i=0; i<3; i++) fRec6[i] = 0;
		for (int i=0; i<3; i++) fRec7[i] = 0;
		for (int i=0; i<3; i++) fRec8[i] = 0;
		for (int i=0; i<3; i++) fRec9[i] = 0;
		for (int i=0; i<3; i++) fRec10[i] = 0;
		for (int i=0; i<3; i++) fRec2[i] = 0;
		for (int i=0; i<3; i++) fRec43[i] = 0;
		for (int i=0; i<3; i++) fRec45[i] = 0;
		for (int i=0; i<3; i++) fRec44[i] = 0;
	}
	virtual void init(int samplingFreq) {
		classInit(samplingFreq);
		instanceInit(samplingFreq);
	}
	virtual void instanceInit(int samplingFreq) {
		instanceConstants(samplingFreq);
		instanceResetUserInterface();
		instanceClear();
	}
	virtual effect* clone() {
		return new effect();
	}
	virtual int getSampleRate() {
		return fSamplingFreq;
	}
	virtual void buildUserInterface(UI* ui_interface) {
		ui_interface->declare(0, "0", "");
		ui_interface->declare(0, "tooltip", "~ ZITA REV1 FEEDBACK DELAY NETWORK (FDN) & SCHROEDER       ALLPASS-COMB REVERBERATOR (8x8). See Faust's reverb.lib for documentation and       references");
		ui_interface->openHorizontalBox("Zita_Rev1");
		ui_interface->declare(0, "1", "");
		ui_interface->openHorizontalBox("Input");
		ui_interface->declare(&fslider4, "1", "");
		ui_interface->declare(&fslider4, "style", "knob");
		ui_interface->declare(&fslider4, "tooltip", "Delay in ms    before reverberation begins");
		ui_interface->declare(&fslider4, "unit", "ms");
		ui_interface->addVerticalSlider("In Delay", &fslider4, 6e+01f, 2e+01f, 1e+02f, 1.0f);
		ui_interface->closeBox();
		ui_interface->declare(0, "2", "");
		ui_interface->openHorizontalBox("Decay Times in Bands (see tooltips)");
		ui_interface->declare(&fslider8, "1", "");
		ui_interface->declare(&fslider8, "scale", "log");
		ui_interface->declare(&fslider8, "style", "knob");
		ui_interface->declare(&fslider8, "tooltip", "Crossover frequency (Hz) separating low and middle frequencies");
		ui_interface->declare(&fslider8, "unit", "Hz");
		ui_interface->addVerticalSlider("LF X", &fslider8, 2e+02f, 5e+01f, 1e+03f, 1.0f);
		ui_interface->declare(&fslider7, "2", "");
		ui_interface->declare(&fslider7, "scale", "log");
		ui_interface->declare(&fslider7, "style", "knob");
		ui_interface->declare(&fslider7, "tooltip", "T60 = time (in seconds) to decay 60dB in low-frequency band");
		ui_interface->declare(&fslider7, "unit", "s");
		ui_interface->addVerticalSlider("Low RT60", &fslider7, 3.0f, 1.0f, 8.0f, 0.1f);
		ui_interface->declare(&fslider6, "3", "");
		ui_interface->declare(&fslider6, "scale", "log");
		ui_interface->declare(&fslider6, "style", "knob");
		ui_interface->declare(&fslider6, "tooltip", "T60 = time (in seconds) to decay 60dB in middle band");
		ui_interface->declare(&fslider6, "unit", "s");
		ui_interface->addVerticalSlider("Mid RT60", &fslider6, 2.0f, 1.0f, 8.0f, 0.1f);
		ui_interface->declare(&fslider5, "4", "");
		ui_interface->declare(&fslider5, "scale", "log");
		ui_interface->declare(&fslider5, "style", "knob");
		ui_interface->declare(&fslider5, "tooltip", "Frequency (Hz) at which the high-frequency T60 is half the middle-band's T60");
		ui_interface->declare(&fslider5, "unit", "Hz");
		ui_interface->addVerticalSlider("HF Damping", &fslider5, 6e+03f, 1.5e+03f, 2.352e+04f, 1.0f);
		ui_interface->closeBox();
		ui_interface->declare(0, "3", "");
		ui_interface->openHorizontalBox("RM Peaking Equalizer 1");
		ui_interface->declare(&fslider2, "1", "");
		ui_interface->declare(&fslider2, "scale", "log");
		ui_interface->declare(&fslider2, "style", "knob");
		ui_interface->declare(&fslider2, "tooltip", "Center-frequency of second-order Regalia-Mitra peaking equalizer section 1");
		ui_interface->declare(&fslider2, "unit", "Hz");
		ui_interface->addVerticalSlider("Eq1 Freq", &fslider2, 315.0f, 4e+01f, 2.5e+03f, 1.0f);
		ui_interface->declare(&fslider3, "2", "");
		ui_interface->declare(&fslider3, "style", "knob");
		ui_interface->declare(&fslider3, "tooltip", "Peak level    in dB of second-order Regalia-Mitra peaking equalizer section 1");
		ui_interface->declare(&fslider3, "unit", "dB");
		ui_interface->addVerticalSlider("Eq1 Level", &fslider3, 0.0f, -15.0f, 15.0f, 0.1f);
		ui_interface->closeBox();
		ui_interface->declare(0, "4", "");
		ui_interface->openHorizontalBox("RM Peaking Equalizer 2");
		ui_interface->declare(&fslider9, "1", "");
		ui_interface->declare(&fslider9, "scale", "log");
		ui_interface->declare(&fslider9, "style", "knob");
		ui_interface->declare(&fslider9, "tooltip", "Center-frequency of second-order Regalia-Mitra peaking equalizer section 2");
		ui_interface->declare(&fslider9, "unit", "Hz");
		ui_interface->addVerticalSlider("Eq2 Freq", &fslider9, 1.5e+03f, 1.6e+02f, 1e+04f, 1.0f);
		ui_interface->declare(&fslider10, "2", "");
		ui_interface->declare(&fslider10, "style", "knob");
		ui_interface->declare(&fslider10, "tooltip", "Peak level    in dB of second-order Regalia-Mitra peaking equalizer section 2");
		ui_interface->declare(&fslider10, "unit", "dB");
		ui_interface->addVerticalSlider("Eq2 Level", &fslider10, 0.0f, -15.0f, 15.0f, 0.1f);
		ui_interface->closeBox();
		ui_interface->declare(0, "5", "");
		ui_interface->openHorizontalBox("Output");
		ui_interface->declare(&fslider1, "1", "");
		ui_interface->declare(&fslider1, "style", "knob");
		ui_interface->declare(&fslider1, "tooltip", "-1 = dry, 1 = wet");
		ui_interface->addVerticalSlider("Dry/Wet Mix", &fslider1, 0.0f, -1.0f, 1.0f, 0.01f);
		ui_interface->declare(&fslider0, "2", "");
		ui_interface->declare(&fslider0, "style", "knob");
		ui_interface->declare(&fslider0, "tooltip", "Output scale    factor");
		ui_interface->declare(&fslider0, "unit", "dB");
		ui_interface->addVerticalSlider("Level", &fslider0, -2e+01f, -7e+01f, 4e+01f, 0.1f);
		ui_interface->closeBox();
		ui_interface->closeBox();
	}
	virtual void compute (int count, FAUSTFLOAT** input, FAUSTFLOAT** output) {
		float 	fSlow0 = (0.001f * powf(10,(0.05f * float(fslider0))));
		float 	fSlow1 = (0.001f * float(fslider1));
		float 	fSlow2 = float(fslider2);
		float 	fSlow3 = powf(10,(0.05f * float(fslider3)));
		float 	fSlow4 = (fConst1 * (fSlow2 / sqrtf(max((float)0, fSlow3))));
		float 	fSlow5 = ((1.0f - fSlow4) / (fSlow4 + 1.0f));
		int 	iSlow6 = int((int((fConst2 * float(fslider4))) & 8191));
		float 	fSlow7 = cosf((fConst3 * float(fslider5)));
		float 	fSlow8 = float(fslider6);
		float 	fSlow9 = expf((fConst5 / fSlow8));
		float 	fSlow10 = faustpower<2>(fSlow9);
		float 	fSlow11 = (1.0f - (fSlow7 * fSlow10));
		float 	fSlow12 = (1.0f - fSlow10);
		float 	fSlow13 = (fSlow11 / fSlow12);
		float 	fSlow14 = sqrtf(max((float)0, ((faustpower<2>(fSlow11) / faustpower<2>(fSlow12)) + -1.0f)));
		float 	fSlow15 = (fSlow13 - fSlow14);
		float 	fSlow16 = (fSlow9 * (fSlow14 + (1.0f - fSlow13)));
		float 	fSlow17 = float(fslider7);
		float 	fSlow18 = ((expf((fConst5 / fSlow17)) / fSlow9) + -1);
		float 	fSlow19 = (1.0f / tanf((fConst6 * float(fslider8))));
		float 	fSlow20 = (fSlow19 + 1);
		float 	fSlow21 = (1.0f / fSlow20);
		float 	fSlow22 = (0 - ((1 - fSlow19) / fSlow20));
		float 	fSlow23 = expf((fConst11 / fSlow8));
		float 	fSlow24 = faustpower<2>(fSlow23);
		float 	fSlow25 = (1.0f - (fSlow7 * fSlow24));
		float 	fSlow26 = (1.0f - fSlow24);
		float 	fSlow27 = (fSlow25 / fSlow26);
		float 	fSlow28 = sqrtf(max((float)0, ((faustpower<2>(fSlow25) / faustpower<2>(fSlow26)) + -1.0f)));
		float 	fSlow29 = (fSlow27 - fSlow28);
		float 	fSlow30 = (fSlow23 * (fSlow28 + (1.0f - fSlow27)));
		float 	fSlow31 = ((expf((fConst11 / fSlow17)) / fSlow23) + -1);
		float 	fSlow32 = expf((fConst16 / fSlow8));
		float 	fSlow33 = faustpower<2>(fSlow32);
		float 	fSlow34 = (1.0f - (fSlow7 * fSlow33));
		float 	fSlow35 = (1.0f - fSlow33);
		float 	fSlow36 = (fSlow34 / fSlow35);
		float 	fSlow37 = sqrtf(max((float)0, ((faustpower<2>(fSlow34) / faustpower<2>(fSlow35)) + -1.0f)));
		float 	fSlow38 = (fSlow36 - fSlow37);
		float 	fSlow39 = (fSlow32 * (fSlow37 + (1.0f - fSlow36)));
		float 	fSlow40 = ((expf((fConst16 / fSlow17)) / fSlow32) + -1);
		float 	fSlow41 = expf((fConst21 / fSlow8));
		float 	fSlow42 = faustpower<2>(fSlow41);
		float 	fSlow43 = (1.0f - (fSlow7 * fSlow42));
		float 	fSlow44 = (1.0f - fSlow42);
		float 	fSlow45 = (fSlow43 / fSlow44);
		float 	fSlow46 = sqrtf(max((float)0, ((faustpower<2>(fSlow43) / faustpower<2>(fSlow44)) + -1.0f)));
		float 	fSlow47 = (fSlow45 - fSlow46);
		float 	fSlow48 = (fSlow41 * (fSlow46 + (1.0f - fSlow45)));
		float 	fSlow49 = ((expf((fConst21 / fSlow17)) / fSlow41) + -1);
		float 	fSlow50 = expf((fConst26 / fSlow8));
		float 	fSlow51 = faustpower<2>(fSlow50);
		float 	fSlow52 = (1.0f - (fSlow7 * fSlow51));
		float 	fSlow53 = (1.0f - fSlow51);
		float 	fSlow54 = (fSlow52 / fSlow53);
		float 	fSlow55 = sqrtf(max((float)0, ((faustpower<2>(fSlow52) / faustpower<2>(fSlow53)) + -1.0f)));
		float 	fSlow56 = (fSlow54 - fSlow55);
		float 	fSlow57 = (fSlow50 * (fSlow55 + (1.0f - fSlow54)));
		float 	fSlow58 = ((expf((fConst26 / fSlow17)) / fSlow50) + -1);
		float 	fSlow59 = expf((fConst31 / fSlow8));
		float 	fSlow60 = faustpower<2>(fSlow59);
		float 	fSlow61 = (1.0f - (fSlow7 * fSlow60));
		float 	fSlow62 = (1.0f - fSlow60);
		float 	fSlow63 = (fSlow61 / fSlow62);
		float 	fSlow64 = sqrtf(max((float)0, ((faustpower<2>(fSlow61) / faustpower<2>(fSlow62)) + -1.0f)));
		float 	fSlow65 = (fSlow63 - fSlow64);
		float 	fSlow66 = (fSlow59 * (fSlow64 + (1.0f - fSlow63)));
		float 	fSlow67 = ((expf((fConst31 / fSlow17)) / fSlow59) + -1);
		float 	fSlow68 = expf((fConst36 / fSlow8));
		float 	fSlow69 = faustpower<2>(fSlow68);
		float 	fSlow70 = (1.0f - (fSlow69 * fSlow7));
		float 	fSlow71 = (1.0f - fSlow69);
		float 	fSlow72 = (fSlow70 / fSlow71);
		float 	fSlow73 = sqrtf(max((float)0, ((faustpower<2>(fSlow70) / faustpower<2>(fSlow71)) + -1.0f)));
		float 	fSlow74 = (fSlow72 - fSlow73);
		float 	fSlow75 = (fSlow68 * (fSlow73 + (1.0f - fSlow72)));
		float 	fSlow76 = ((expf((fConst36 / fSlow17)) / fSlow68) + -1);
		float 	fSlow77 = expf((fConst41 / fSlow8));
		float 	fSlow78 = faustpower<2>(fSlow77);
		float 	fSlow79 = (1.0f - (fSlow78 * fSlow7));
		float 	fSlow80 = (1.0f - fSlow78);
		float 	fSlow81 = (fSlow79 / fSlow80);
		float 	fSlow82 = sqrtf(max((float)0, ((faustpower<2>(fSlow79) / faustpower<2>(fSlow80)) + -1.0f)));
		float 	fSlow83 = (fSlow81 - fSlow82);
		float 	fSlow84 = (fSlow77 * (fSlow82 + (1.0f - fSlow81)));
		float 	fSlow85 = ((expf((fConst41 / fSlow17)) / fSlow77) + -1);
		float 	fSlow86 = ((0 - cosf((fConst1 * fSlow2))) * (fSlow5 + 1));
		float 	fSlow87 = float(fslider9);
		float 	fSlow88 = powf(10,(0.05f * float(fslider10)));
		float 	fSlow89 = (fConst1 * (fSlow87 / sqrtf(max((float)0, fSlow88))));
		float 	fSlow90 = ((1.0f - fSlow89) / (fSlow89 + 1.0f));
		float 	fSlow91 = ((0 - cosf((fConst1 * fSlow87))) * (fSlow90 + 1));
		FAUSTFLOAT* input0 = input[0];
		FAUSTFLOAT* output0 = output[0];
		FAUSTFLOAT* output1 = output[1];
		for (int i=0; i<count; i++) {
			fRec0[0] = (fSlow0 + (0.999f * fRec0[1]));
			fRec1[0] = (fSlow1 + (0.999f * fRec1[1]));
			float fTemp0 = (fRec1[0] + 1.0f);
			float fTemp1 = (float)input0[i];
			fVec0[IOTA&8191] = fTemp1;
			float fTemp2 = (fTemp0 * fVec0[IOTA&8191]);
			float fTemp3 = (1.0f - (0.5f * fTemp0));
			float fTemp4 = (0.3f * fVec0[(IOTA-iSlow6)&8191]);
			fRec14[0] = ((fSlow21 * (fRec3[1] + fRec3[2])) + (fSlow22 * fRec14[1]));
			fRec13[0] = ((fSlow15 * fRec13[1]) + (fSlow16 * (fRec3[1] + (fSlow18 * fRec14[0]))));
			fVec1[IOTA&8191] = ((0.35355338f * fRec13[0]) + 1e-20f);
			float fTemp5 = ((fTemp4 + fVec1[(IOTA-iConst8)&8191]) - (0.6f * fRec11[1]));
			fVec2[IOTA&1023] = fTemp5;
			fRec11[0] = fVec2[(IOTA-iConst9)&1023];
			float 	fRec12 = (0.6f * fVec2[IOTA&1023]);
			fRec18[0] = ((fSlow21 * (fRec7[1] + fRec7[2])) + (fSlow22 * fRec18[1]));
			fRec17[0] = ((fSlow29 * fRec17[1]) + (fSlow30 * (fRec7[1] + (fSlow31 * fRec18[0]))));
			fVec3[IOTA&8191] = ((0.35355338f * fRec17[0]) + 1e-20f);
			float fTemp6 = ((fTemp4 + fVec3[(IOTA-iConst13)&8191]) - (0.6f * fRec15[1]));
			fVec4[IOTA&2047] = fTemp6;
			fRec15[0] = fVec4[(IOTA-iConst14)&2047];
			float 	fRec16 = (0.6f * fVec4[IOTA&2047]);
			fRec22[0] = ((fSlow21 * (fRec5[1] + fRec5[2])) + (fSlow22 * fRec22[1]));
			fRec21[0] = ((fSlow38 * fRec21[1]) + (fSlow39 * (fRec5[1] + (fSlow40 * fRec22[0]))));
			fVec5[IOTA&8191] = ((0.35355338f * fRec21[0]) + 1e-20f);
			float fTemp7 = (fVec5[(IOTA-iConst18)&8191] - (fTemp4 + (0.6f * fRec19[1])));
			fVec6[IOTA&2047] = fTemp7;
			fRec19[0] = fVec6[(IOTA-iConst19)&2047];
			float 	fRec20 = (0.6f * fVec6[IOTA&2047]);
			fRec26[0] = ((fSlow21 * (fRec9[1] + fRec9[2])) + (fSlow22 * fRec26[1]));
			fRec25[0] = ((fSlow47 * fRec25[1]) + (fSlow48 * (fRec9[1] + (fSlow49 * fRec26[0]))));
			fVec7[IOTA&8191] = ((0.35355338f * fRec25[0]) + 1e-20f);
			float fTemp8 = (fVec7[(IOTA-iConst23)&8191] - (fTemp4 + (0.6f * fRec23[1])));
			fVec8[IOTA&1023] = fTemp8;
			fRec23[0] = fVec8[(IOTA-iConst24)&1023];
			float 	fRec24 = (0.6f * fVec8[IOTA&1023]);
			fRec30[0] = ((fSlow21 * (fRec4[1] + fRec4[2])) + (fSlow22 * fRec30[1]));
			fRec29[0] = ((fSlow56 * fRec29[1]) + (fSlow57 * (fRec4[1] + (fSlow58 * fRec30[0]))));
			fVec9[IOTA&16383] = ((0.35355338f * fRec29[0]) + 1e-20f);
			float fTemp9 = (fVec9[(IOTA-iConst28)&16383] + (fTemp4 + (0.6f * fRec27[1])));
			fVec10[IOTA&2047] = fTemp9;
			fRec27[0] = fVec10[(IOTA-iConst29)&2047];
			float 	fRec28 = (0 - (0.6f * fVec10[IOTA&2047]));
			fRec34[0] = ((fSlow21 * (fRec8[1] + fRec8[2])) + (fSlow22 * fRec34[1]));
			fRec33[0] = ((fSlow65 * fRec33[1]) + (fSlow66 * (fRec8[1] + (fSlow67 * fRec34[0]))));
			fVec11[IOTA&8191] = ((0.35355338f * fRec33[0]) + 1e-20f);
			float fTemp10 = (fVec11[(IOTA-iConst33)&8191] + (fTemp4 + (0.6f * fRec31[1])));
			fVec12[IOTA&2047] = fTemp10;
			fRec31[0] = fVec12[(IOTA-iConst34)&2047];
			float 	fRec32 = (0 - (0.6f * fVec12[IOTA&2047]));
			fRec38[0] = ((fSlow21 * (fRec6[1] + fRec6[2])) + (fSlow22 * fRec38[1]));
			fRec37[0] = ((fSlow74 * fRec37[1]) + (fSlow75 * (fRec6[1] + (fSlow76 * fRec38[0]))));
			fVec13[IOTA&16383] = ((0.35355338f * fRec37[0]) + 1e-20f);
			float fTemp11 = (((0.6f * fRec35[1]) + fVec13[(IOTA-iConst38)&16383]) - fTemp4);
			fVec14[IOTA&2047] = fTemp11;
			fRec35[0] = fVec14[(IOTA-iConst39)&2047];
			float 	fRec36 = (0 - (0.6f * fVec14[IOTA&2047]));
			fRec42[0] = ((fSlow21 * (fRec10[1] + fRec10[2])) + (fSlow22 * fRec42[1]));
			fRec41[0] = ((fSlow83 * fRec41[1]) + (fSlow84 * (fRec10[1] + (fSlow85 * fRec42[0]))));
			fVec15[IOTA&16383] = ((0.35355338f * fRec41[0]) + 1e-20f);
			float fTemp12 = (((0.6f * fRec39[1]) + fVec15[(IOTA-iConst43)&16383]) - fTemp4);
			fVec16[IOTA&1023] = fTemp12;
			fRec39[0] = fVec16[(IOTA-iConst44)&1023];
			float 	fRec40 = (0 - (0.6f * fVec16[IOTA&1023]));
			float fTemp13 = (fRec39[1] + fRec40);
			float fTemp14 = (fRec36 + (fRec35[1] + fTemp13));
			float fTemp15 = (fRec28 + (fRec27[1] + (fRec32 + (fRec31[1] + fTemp14))));
			fRec3[0] = (fRec12 + (fRec11[1] + (fRec16 + (fRec15[1] + (fRec20 + (fRec19[1] + (fRec24 + (fRec23[1] + fTemp15))))))));
			fRec4[0] = ((fRec12 + (fRec11[1] + (fRec16 + (fRec15[1] + (fRec20 + (fRec19[1] + (fRec23[1] + fRec24))))))) - fTemp15);
			float fTemp16 = (fRec28 + (fRec27[1] + (fRec31[1] + fRec32)));
			fRec5[0] = ((fRec12 + (fRec11[1] + (fRec16 + (fRec15[1] + fTemp16)))) - (fRec20 + (fRec19[1] + (fRec24 + (fRec23[1] + fTemp14)))));
			fRec6[0] = ((fRec12 + (fRec11[1] + (fRec16 + (fRec15[1] + fTemp14)))) - (fRec20 + (fRec19[1] + (fRec24 + (fRec23[1] + fTemp16)))));
			float fTemp17 = (fRec35[1] + fRec36);
			float fTemp18 = (fRec28 + (fRec27[1] + fTemp17));
			float fTemp19 = (fRec32 + (fRec31[1] + fTemp13));
			fRec7[0] = ((fRec12 + (fRec11[1] + (fRec20 + (fRec19[1] + fTemp18)))) - (fRec16 + (fRec15[1] + (fRec24 + (fRec23[1] + fTemp19)))));
			fRec8[0] = ((fRec12 + (fRec11[1] + (fRec20 + (fRec19[1] + fTemp19)))) - (fRec16 + (fRec15[1] + (fRec24 + (fRec23[1] + fTemp18)))));
			float fTemp20 = (fRec28 + (fRec27[1] + fTemp13));
			float fTemp21 = (fRec32 + (fRec31[1] + fTemp17));
			fRec9[0] = ((fRec12 + (fRec11[1] + (fRec24 + (fRec23[1] + fTemp20)))) - (fRec16 + (fRec15[1] + (fRec20 + (fRec19[1] + fTemp21)))));
			fRec10[0] = ((fRec12 + (fRec11[1] + (fRec24 + (fRec23[1] + fTemp21)))) - (fRec16 + (fRec15[1] + (fRec20 + (fRec19[1] + fTemp20)))));
			float fTemp22 = (0.37f * (fRec4[0] + fRec5[0]));
			float fTemp23 = (fSlow86 * fRec2[1]);
			fRec2[0] = (fTemp22 - (fTemp23 + (fSlow5 * fRec2[2])));
			float fTemp24 = (fSlow5 * fRec2[0]);
			float fTemp25 = (fTemp23 + fRec2[2]);
			float fTemp26 = (0.5f * ((fTemp24 + (fTemp22 + fTemp25)) + (fSlow3 * ((fTemp24 + fTemp25) - fTemp22))));
			float fTemp27 = (fSlow91 * fRec43[1]);
			fRec43[0] = (fTemp26 - (fTemp27 + (fSlow90 * fRec43[2])));
			float fTemp28 = ((fSlow90 * fRec43[0]) + (fTemp27 + fRec43[2]));
			output0[i] = (FAUSTFLOAT)(0.5f * (fRec0[0] * (fTemp2 + (fTemp3 * ((fTemp26 + fTemp28) + (fSlow88 * (fTemp28 - fTemp26)))))));
			float fTemp29 = (0.37f * (fRec4[0] - fRec5[0]));
			float fTemp30 = (fSlow86 * fRec45[1]);
			fRec45[0] = (fTemp29 - (fTemp30 + (fSlow5 * fRec45[2])));
			float fTemp31 = (fSlow5 * fRec45[0]);
			float fTemp32 = (fTemp30 + fRec45[2]);
			float fTemp33 = (0.5f * ((fTemp31 + (fTemp29 + fTemp32)) + (fSlow3 * ((fTemp31 + fTemp32) - fTemp29))));
			float fTemp34 = (fSlow91 * fRec44[1]);
			fRec44[0] = (fTemp33 - (fTemp34 + (fSlow90 * fRec44[2])));
			float fTemp35 = ((fSlow90 * fRec44[0]) + (fTemp34 + fRec44[2]));
			output1[i] = (FAUSTFLOAT)(0.5f * (fRec0[0] * (fTemp2 + (fTemp3 * ((fSlow88 * (fTemp35 - fTemp33)) + (fTemp33 + fTemp35))))));
			// post processing
			fRec44[2] = fRec44[1]; fRec44[1] = fRec44[0];
			fRec45[2] = fRec45[1]; fRec45[1] = fRec45[0];
			fRec43[2] = fRec43[1]; fRec43[1] = fRec43[0];
			fRec2[2] = fRec2[1]; fRec2[1] = fRec2[0];
			fRec10[2] = fRec10[1]; fRec10[1] = fRec10[0];
			fRec9[2] = fRec9[1]; fRec9[1] = fRec9[0];
			fRec8[2] = fRec8[1]; fRec8[1] = fRec8[0];
			fRec7[2] = fRec7[1]; fRec7[1] = fRec7[0];
			fRec6[2] = fRec6[1]; fRec6[1] = fRec6[0];
			fRec5[2] = fRec5[1]; fRec5[1] = fRec5[0];
			fRec4[2] = fRec4[1]; fRec4[1] = fRec4[0];
			fRec3[2] = fRec3[1]; fRec3[1] = fRec3[0];
			fRec39[1] = fRec39[0];
			fRec41[1] = fRec41[0];
			fRec42[1] = fRec42[0];
			fRec35[1] = fRec35[0];
			fRec37[1] = fRec37[0];
			fRec38[1] = fRec38[0];
			fRec31[1] = fRec31[0];
			fRec33[1] = fRec33[0];
			fRec34[1] = fRec34[0];
			fRec27[1] = fRec27[0];
			fRec29[1] = fRec29[0];
			fRec30[1] = fRec30[0];
			fRec23[1] = fRec23[0];
			fRec25[1] = fRec25[0];
			fRec26[1] = fRec26[0];
			fRec19[1] = fRec19[0];
			fRec21[1] = fRec21[0];
			fRec22[1] = fRec22[0];
			fRec15[1] = fRec15[0];
			fRec17[1] = fRec17[0];
			fRec18[1] = fRec18[0];
			fRec11[1] = fRec11[0];
			fRec13[1] = fRec13[0];
			fRec14[1] = fRec14[0];
			IOTA = IOTA+1;
			fRec1[1] = fRec1[0];
			fRec0[1] = fRec0[0];
		}
	}
};



