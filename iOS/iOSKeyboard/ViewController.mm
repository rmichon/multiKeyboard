//
//  ViewController.m
//  iOSKeyboard
//
//  Created by Romain Michon on 6/6/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#define MULTI_KEYBOARD_ONLY 0

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
    
    faustDsp = new DspFaust(SR,bufferSize);
    faustDsp->start();
    
    if(MULTI_KEYBOARD_ONLY == 0){
        InstrumentInterface *instrumentInterface = [[InstrumentInterface alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withFaustDSP:faustDsp];
        [self.view addSubview:instrumentInterface];
    }
    else{
        MultiKeyboard *multiKeyboard = [[MultiKeyboard alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withFaustDSP:faustDsp];
        [self.view addSubview:multiKeyboard];
    }
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
