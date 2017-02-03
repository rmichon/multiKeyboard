//
//  InstrumentInterface.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "InstrumentInterface.h"

@implementation InstrumentInterface{
    MultiKeyboard *multiKeyboard;
    NavBar *navBar;
    ConfigDisplay *configDisplay;
    CGFloat viewsRatio; // the size of multikeyboard compared to navbar
    CGFloat multiKeyboardHeight, multiKeyboardWidth, multiKeyboardXOffset, multikeyboardYOffset;
    DspFaust* dspFaust;
    Boolean configDisplayOn; // true if config display is visible
    NSString *currentPresetName;
    NSMutableArray *presetsList;
    NSString *localSettingsFile; // names of the file storing the local settings of InstrInterface (e.g. position of NavBar)
    NSDictionary *localSettings; // dictionary storing the local settings and reflecting the content of localSettingsFile
}

- (id)initWithFrame:(CGRect)frame withFaustDSP:(DspFaust*)faustDsp withPresetId:(NSInteger)presetId{
    self = [super initWithFrame:frame];
    if(self){
        presetsList = [[NSMutableArray alloc] init];
        
        dspFaust = faustDsp;
        configDisplayOn = false;
        viewsRatio = 0.92;
        currentPreset = presetId;
        
        // Retrieving the list of preset files
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSArray *documentsDirectoryContent = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        for(int i=0; i<[documentsDirectoryContent count]; i++){
            if([[documentsDirectoryContent objectAtIndex:i] containsString:@"_keyb"]){
                [presetsList addObject:[[documentsDirectoryContent objectAtIndex:i] stringByReplacingOccurrencesOfString:@"_keyb" withString:@""]];
            }
        }
        
        currentPresetName = [presetsList objectAtIndex:currentPreset];
        
        // retrieving saved local settings
        localSettingsFile = [documentsDirectory stringByAppendingPathComponent:@"instrIntSettings"];
        localSettings = [[NSDictionary alloc] initWithContentsOfFile:localSettingsFile];
        
        // if there are no saved local settings, then creating default local settings
        if([localSettings count] == 0){
            localSettings = [NSMutableDictionary dictionaryWithDictionary:
                             @{
                               @"navBarPos":[NSNumber numberWithInt:2] // 0: bottom, 1: left, etc.
                               }];
            [localSettings writeToFile:localSettingsFile atomically:YES];
        }
        
        [self buildUI];
    }
    return self;
}

- (void)buildUI{
    // cleaning first
    [self cleanUI];
    
    // UI is built in function of the position of the navbar
    if([localSettings[@"navBarPos"] intValue] == 0){ // navbar is at the bottom
        CGFloat navBarHeight = self.frame.size.height*(1-viewsRatio);
        multiKeyboardXOffset = 0;
        multikeyboardYOffset = 0;
        multiKeyboardWidth = self.frame.size.width;
        multiKeyboardHeight = self.frame.size.height*viewsRatio;
        navBar = [[NavBar alloc] initWithFrame:CGRectMake(0.0, multiKeyboardHeight, self.frame.size.width, navBarHeight) withOrientation:true];
    }
    else if([localSettings[@"navBarPos"] intValue] == 1){ // navbar is on the left
        CGFloat navBarWidth = self.frame.size.width*(1-viewsRatio);
        multiKeyboardXOffset = navBarWidth;
        multikeyboardYOffset = 0;
        multiKeyboardWidth = self.frame.size.width*viewsRatio;
        multiKeyboardHeight = self.frame.size.height;
        navBar = [[NavBar alloc] initWithFrame:CGRectMake(0.0, 0.0f, navBarWidth, self.frame.size.height) withOrientation:false];
    }
    else if([localSettings[@"navBarPos"] intValue] == 2){ // navbar is at the top
        CGFloat navBarHeight = self.frame.size.height*(1-viewsRatio);
        multiKeyboardXOffset = 0;
        multikeyboardYOffset = navBarHeight;
        multiKeyboardWidth = self.frame.size.width;
        multiKeyboardHeight = self.frame.size.height*viewsRatio;
        navBar = [[NavBar alloc] initWithFrame:CGRectMake(0.0, 0.0f, self.frame.size.width, navBarHeight) withOrientation:true];
    }
    else if([localSettings[@"navBarPos"] intValue] == 3){ // navbar is on the right
        CGFloat navBarWidth = self.frame.size.width*(1-viewsRatio);
        multiKeyboardXOffset = 0;
        multikeyboardYOffset = 0;
        multiKeyboardWidth = self.frame.size.width*viewsRatio;;
        multiKeyboardHeight = self.frame.size.height;
        navBar = [[NavBar alloc] initWithFrame:CGRectMake(multiKeyboardWidth, 0.0f, navBarWidth, self.frame.size.height) withOrientation:false];
    }
    multiKeyboard = [[MultiKeyboard alloc] initWithFrame:CGRectMake(multiKeyboardXOffset, multikeyboardYOffset, multiKeyboardWidth, multiKeyboardHeight) withFaustDSP:dspFaust withPreset:currentPresetName];
    [navBar addTarget:self action:@selector(newEventOnNavBar:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:multiKeyboard];
    [self addSubview:navBar];
}

// deallocate the UI elements
- (void) cleanUI{
    if(multiKeyboard != nil){
        [multiKeyboard clean]; // necessary because of acceleremoeters (wont get dealloc otherwise)
        [multiKeyboard removeFromSuperview];
        multiKeyboard = nil;
    }
    if(navBar != nil){
        [navBar removeFromSuperview];
        navBar = nil;
    }
}

- (IBAction)newEventOnNavBar:(NavBar*)sender{
    if(sender->touchedButton == 0){ // going back to home
        [multiKeyboard savePreset]; // saving the current preset
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else if(sender->touchedButton == 1){
        if(!configDisplayOn){ // opening config display
            configDisplay = [[ConfigDisplay alloc] initWithFrame:CGRectMake(multiKeyboardXOffset, multikeyboardYOffset, multiKeyboardWidth, multiKeyboardHeight) withKeyboardParams:multiKeyboard->keyboardParameters withDspParamas:multiKeyboard->dspParameters withDspFaust:dspFaust];
            [self addSubview:configDisplay];
            configDisplayOn = true;
        }
        else{ // closing config window
            [multiKeyboard savePreset]; // saving modifications to file
            [configDisplay removeFromSuperview]; // dealloc config display
            configDisplay = nil;
            configDisplayOn = false;
            [multiKeyboard buildInterface]; // rebuilding multikeyboard taking previous changes into account
        }
    }
    else if(sender->touchedButton == 2){ // loading previous preset
        if(currentPreset>0 && !configDisplay){
            currentPreset--;
            currentPresetName = [[presetsList objectAtIndex:currentPreset] stringByReplacingOccurrencesOfString:@"_keyb" withString:@""];
            [self buildUI];
        }
    }
    else if(sender->touchedButton == 3 && !configDisplay){ // loading next preset
        if(currentPreset < [presetsList count]-1){
            currentPreset++;
            currentPresetName = [[presetsList objectAtIndex:currentPreset] stringByReplacingOccurrencesOfString:@"_keyb" withString:@""];
            [self buildUI];
        }
    }
    else if(sender->touchedButton == 4 && !configDisplay){ // changing position of navbar
        [localSettings setValue:[NSNumber numberWithInteger:([localSettings[@"navBarPos"] intValue]+1)%4] forKey:@"navBarPos"];
        [localSettings writeToFile:localSettingsFile atomically:YES];
        [self buildUI];
    }
}

-(void)dealloc{
    [self cleanUI];
}

@end
