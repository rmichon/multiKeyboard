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
}

- (id)initWithFrame:(CGRect)frame withFaustDSP:(DspFaust*)faustDsp{
    self = [super initWithFrame:frame];
    if(self){
        dspFaust = faustDsp;
        navBarPos = 0;
        configDisplayOn = false;
        viewsRatio = 0.95;
        [self buildUI];
    }
    return self;
}

- (void)buildUI{
    if(multiKeyboard != nil){
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
    multiKeyboard = [[MultiKeyboard alloc] initWithFrame:CGRectMake(multiKeyboardXOffset, multikeyboardYOffset, multiKeyboardWidth, multiKeyboardHeight) withFaustDSP:dspFaust];
    [navBar addTarget:self action:@selector(newEventOnNavBar:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:multiKeyboard];
    [self addSubview:navBar];
}

- (IBAction)newEventOnNavBar:(NavBar*)sender{
    if(sender->touchedButton == 1){
        [multiKeyboard saveParameters]; // TODO: might be a better place for that
        
        if(!configDisplayOn){
            configDisplay = [[ConfigDisplay alloc] initWithFrame:CGRectMake(multiKeyboardXOffset, multikeyboardYOffset, multiKeyboardWidth, multiKeyboardHeight) withParams:multiKeyboard->parameters withDspFaust:dspFaust];
            [self addSubview:configDisplay];
            configDisplayOn = true;
        }
        else{
            [configDisplay saveState];
            [configDisplay removeFromSuperview];
            configDisplay = nil;
            configDisplayOn = false;
            [multiKeyboard buildInterface];
        }
    }
    else if(sender->touchedButton == 4){
        navBarPos = (navBarPos+1)%4;
        [self buildUI];
    }
}

@end
