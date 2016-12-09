//
//  ViewController.m
//  iOSKeyboard
//
//  Created by Romain Michon on 6/6/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#define POLY2 1

#import "ViewController.h"

// TODO: this is so dirty plus we don't know what this does
std::list<GUI*> GUI::fGuiList;
ztimedmap GUI::gTimedZoneMap;

@interface ViewController ()

@end

@implementation ViewController{
    audio* audioDevice;
    mydsp* faustDSP;
    mydsp_poly* synthDSP;
    dsp* mainDSP;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    const int SR = 44100;
    const int bufferSize = 256;
    const int nPoly = 10; // TODO: the number of voices of polyphony is static here and decoralted from what is declared later in MultiKeyboard: perhaps should find a way to fix that... Same problem if no poly keyboard mode
    audioDevice = new iosaudio(SR, bufferSize);
    faustDSP = new mydsp;
    synthDSP = new mydsp_poly(faustDSP,nPoly,true,false);
    
    #if POLY2
    mainDSP = new dsp_sequencer(synthDSP,new effect());
    audioDevice->init("Faust", mainDSP);
    #else
    audioDevice->init("Faust", synthDSP);
    #endif
    
    audioDevice->start();
    
    // For now, just interface...
    //KeyboardView *myZone = [[KeyboardView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withPolyDSP:DSP];
    
    MultiKeyboard *myZone = [[MultiKeyboard alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withPolyDSP:synthDSP];
    [self.view addSubview:myZone];
    
    /*
    MapUI mapUI;
    faustDSP->buildUserInterface(&mapUI);
    mapUI.setParamValue("y1", 0.01);
    */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if(audioDevice) {
        audioDevice->stop();
        delete audioDevice;
        audioDevice = NULL;
    }
    if(synthDSP){
        delete synthDSP;
        synthDSP = NULL;
    }
    if(mainDSP){
        delete mainDSP;
        mainDSP = NULL;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL) shouldAutorotate{
    return NO;
}

@end
