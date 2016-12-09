//
//  ViewController.m
//  iOSKeyboard
//
//  Created by Romain Michon on 6/6/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#define POLY2 1

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController{
    DspFaust* faustDsp;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    const int SR = 44100;
    const int bufferSize = 256;
    //const int nPoly = 10; // TODO: the number of voices of polyphony is static here and decoralted from what is declared later in MultiKeyboard: perhaps should find a way to fix that... Same problem if no poly keyboard mode
    
    faustDsp = new DspFaust(SR,bufferSize);
    faustDsp->start();
    
    // For now, just interface...
    //KeyboardView *myZone = [[KeyboardView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withPolyDSP:DSP];
    
    MultiKeyboard *myZone = [[MultiKeyboard alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withFaustDSP:faustDsp];
    [self.view addSubview:myZone];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if(faustDsp){
        faustDsp->stop();
        delete faustDsp;
        faustDsp = NULL;
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
