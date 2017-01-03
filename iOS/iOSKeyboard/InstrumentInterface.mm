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
    CGFloat viewsRatio;
    CGFloat multiKeyboardHeight, multiKeyboardWidth, multiKeyboardXOffset, multikeyboardYOffset;
    int navBarPos;
    DspFaust* dspFaust;
    Boolean configDisplayOn;
    NSString *currentPresetName;
    NSMutableArray *presetsList;
}

- (id)initWithFrame:(CGRect)frame withFaustDSP:(DspFaust*)faustDsp withPresetId:(int)presetId{
    self = [super initWithFrame:frame];
    if(self){
        presetsList = [[NSMutableArray alloc] init];
        
        dspFaust = faustDsp;
        navBarPos = 0;
        configDisplayOn = false;
        viewsRatio = 0.95;
        
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
        
        [self buildUI];
    }
    return self;
}

- (void)buildUI{
    if(multiKeyboard != nil){
        [multiKeyboard clean];
        [multiKeyboard removeFromSuperview];
        multiKeyboard = nil;
    }
    if(navBar != nil){
        [navBar removeFromSuperview];
        navBar = nil;
    }
    if(navBarPos == 0){
        CGFloat navBarHeight = self.frame.size.height*(1-viewsRatio);
        multiKeyboardXOffset = 0;
        multikeyboardYOffset = 0;
        multiKeyboardWidth = self.frame.size.width;
        multiKeyboardHeight = self.frame.size.height*viewsRatio;
        navBar = [[NavBar alloc] initWithFrame:CGRectMake(0.0, multiKeyboardHeight, self.frame.size.width, navBarHeight) withOrientation:true];
    }
    else if(navBarPos == 1){
        CGFloat navBarWidth = self.frame.size.width*(1-viewsRatio);
        multiKeyboardXOffset = navBarWidth;
        multikeyboardYOffset = 0;
        multiKeyboardWidth = self.frame.size.width*viewsRatio;
        multiKeyboardHeight = self.frame.size.height;
        navBar = [[NavBar alloc] initWithFrame:CGRectMake(0.0, 0.0f, navBarWidth, self.frame.size.height) withOrientation:false];
    }
    else if(navBarPos == 2){
        CGFloat navBarHeight = self.frame.size.height*(1-viewsRatio);
        multiKeyboardXOffset = 0;
        multikeyboardYOffset = navBarHeight;
        multiKeyboardWidth = self.frame.size.width;
        multiKeyboardHeight = self.frame.size.height*viewsRatio;
        navBar = [[NavBar alloc] initWithFrame:CGRectMake(0.0, 0.0f, self.frame.size.width, navBarHeight) withOrientation:true];
    }
    else if(navBarPos == 3){
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

- (IBAction)newEventOnNavBar:(NavBar*)sender{
    if(sender->touchedButton == 0){
        [multiKeyboard savePreset];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else if(sender->touchedButton == 1){
        [multiKeyboard savePreset]; // TODO: might be a better place for that
        
        if(!configDisplayOn){
            configDisplay = [[ConfigDisplay alloc] initWithFrame:CGRectMake(multiKeyboardXOffset, multikeyboardYOffset, multiKeyboardWidth, multiKeyboardHeight) withKeyboardParams:multiKeyboard->keyboardParameters withDspParamas:multiKeyboard->dspParameters withDspFaust:dspFaust];
            [self addSubview:configDisplay];
            configDisplayOn = true;
        }
        else{
            [configDisplay removeFromSuperview];
            configDisplay = nil;
            configDisplayOn = false;
            [multiKeyboard buildInterface];
        }
    }
    else if(sender->touchedButton == 2){
        if(currentPreset>0){
            currentPreset--;
            currentPresetName = [[presetsList objectAtIndex:currentPreset] stringByReplacingOccurrencesOfString:@"_keyb" withString:@""];
            [self buildUI];
        }
    }
    else if(sender->touchedButton == 3){
        if(currentPreset < [presetsList count]-1){
            currentPreset++;
            currentPresetName = [[presetsList objectAtIndex:currentPreset] stringByReplacingOccurrencesOfString:@"_keyb" withString:@""];
            [self buildUI];
        }
    }
    else if(sender->touchedButton == 4){
        navBarPos = (navBarPos+1)%4;
        [self buildUI];
    }
}

@end
