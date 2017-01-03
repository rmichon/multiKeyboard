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
    PresetMenu *presetMenu;
    InstrumentInterface *instrumentInterface;
    int currentPreset;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    currentPreset = 0;
    
    const int SR = 44100;
    const int bufferSize = 256;
    
    faustDsp = new DspFaust(SR,bufferSize);
    faustDsp->start();
    
    if(MULTI_KEYBOARD_ONLY == 0){
        presetMenu = [[PresetMenu alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withCurrentPreset:currentPreset];
        [presetMenu addTarget:self action:@selector(newEventOnPresetMenu:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:presetMenu];
    }
    else{
        MultiKeyboard *multiKeyboard = [[MultiKeyboard alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withFaustDSP:faustDsp withPreset:nil];
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

- (IBAction)newEventOnPresetMenu:(PresetMenu*)sender{
    currentPreset = sender->currentPreset;
    instrumentInterface = [[InstrumentInterface alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withFaustDSP:faustDsp withPresetId:currentPreset];
    [presetMenu removeFromSuperview];
    presetMenu = nil;
    [instrumentInterface addTarget:self action:@selector(newEventOnInstrumentInterface:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:instrumentInterface];
}

- (IBAction)newEventOnInstrumentInterface:(InstrumentInterface*)sender{
    currentPreset = sender->currentPreset;
    [instrumentInterface removeFromSuperview];
    instrumentInterface = nil;
    presetMenu = [[PresetMenu alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withCurrentPreset:currentPreset];
    [presetMenu addTarget:self action:@selector(newEventOnPresetMenu:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:presetMenu];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL) shouldAutorotate{
    return NO;
}

@end
