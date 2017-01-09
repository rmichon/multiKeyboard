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
    NSInteger currentPreset;
    NSString *audioSettingsFile; // TODO: note sure if it needs to be global
    NSDictionary *audioSettings;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentPreset = 0;
    
    // initializing audio settings
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    audioSettingsFile = [documentsDirectory stringByAppendingPathComponent:@"audioSettings"];
    audioSettings = [[NSDictionary alloc] initWithContentsOfFile:audioSettingsFile];
    
    // if no saved settings then create defaults
    if([audioSettings count] == 0){
        [self createDefaultAudioSettings];
    }
    
    [self startFaustDsp];
    
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

// creates default audio settings
- (void)createDefaultAudioSettings{
    audioSettings = [NSMutableDictionary dictionaryWithDictionary:
                     @{
                       @"SR":[NSNumber numberWithInt:44100],
                       @"bufferLength":[NSNumber numberWithInt:256]
                       }];
    [audioSettings writeToFile:audioSettingsFile atomically:YES];
}

// start the faust dsp object and its associated elements
- (void)startFaustDsp{
    if(!faustDsp){
        faustDsp = new DspFaust([audioSettings[@"SR"] intValue],[audioSettings[@"bufferLength"] intValue]);
        faustDsp->start();
    }
}

// stop the faust dsp object and its associated elements
- (void)stopFaustDsp{
    if(faustDsp){
        faustDsp->stop();
        delete faustDsp;
        faustDsp = NULL;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self stopFaustDsp];
}

- (IBAction)newEventOnPresetMenu:(PresetMenu*)sender{
    // lauching the keyboard interface with the selected preset
    if(sender->actionType == 0){
        currentPreset = sender->currentPreset;
        instrumentInterface = [[InstrumentInterface alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height) withFaustDSP:faustDsp withPresetId:currentPreset];
        [presetMenu removeFromSuperview];
        presetMenu = nil;
        [instrumentInterface addTarget:self action:@selector(newEventOnInstrumentInterface:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:instrumentInterface];
    }
    // reloading the audio settings and restarting audio
    else if(sender->actionType == 1){
        audioSettings = [[NSDictionary alloc] initWithContentsOfFile:audioSettingsFile];
        [self stopFaustDsp];
        [self startFaustDsp];
    }
}

// user pressed home button on keyboard interface...
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
