//
//  MultiKeyboard.m
//  MultiXYTest
//
//  Created by Romain Michon on 4/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//
//  DESCRIPTION:
//  Build a "MultiKeyboard" interface around a mydsp_poly object.

// TODOs
// - In very rare cases, note-off events are not triggered: this should be fixed
// - If only one cell, should make sure that we use monoMode 0...
// - We believe that MIDI is operational but it needs to be tested
// NOTEs
// - The default mode in any case is that if current finger goes away the note is not transfered to another finger on the keyboard: this might have to be fixed
// - For monoMode, slides between keyboards don't get priority over a finger already on the keyboard in any case
// - Later, glissandi should be handled using pitch bend directly from poly-dsp, but we can take care of that later
// - It would have been nice to have a system to automatically add new midi devices when they are connected but it seems to be more complicated than what we think...

#import "MultiKeyboard.h"
#include <string>

// Accelerometer useful parameters
#define kMotionUpdateRate 30
#define ONE_G 9.81

@implementation MultiKeyboard{
    
    // GRAPHICAL ELEMENTS
    NSMutableArray *zones; // the "keys" of the keyboard matrix (2D)
    CGFloat *zoneWidths; // the width of the different zones of each keyboards
    CGFloat zoneHeight; // the global height of each keyboard (same for all of them)
    Boolean UIon; // true when UI is built (used to secure the rounding thread when there's no UI on the screen)
    
    // TOUCH TRACKING
    int touchDel;
    float currentContinuousKey; // key number of the current keyboard as a float
    float currentKeyboardY; // y position of finger on key (corresponds to the "y" parameter in Faust)
    CGPoint **previousTouchPoints; // previous touch points for each finger
    // delayed previous touch points for each finger
    // NOTE: we think that this is necessary to properly dealocate touches when touchesEnded is called. This might have to be checked but it works very well for now.
    int *previousTouchedKeys; // the last key touched by a specific finger on the screen
    int *previousTouchedKeyboards; // the last keyboard touched by a specific finger on the screen
    int *fingersOnKeyboardsCount; // number of fingers present on each keyboard (used to limit polyphony)
    int fingersOnScreenCount;
    int *monoMode_previousActiveFinger; // last active finger in mono mode (in case touch needs to canceled)
    Boolean cancelOnce; // used to cancel a touch event only once
    
    // PITCH ROUNDING
    float *touchDiff; // distance between 2 distinct touch events
    Boolean *rounding; // tell if the current pitch should be rounded
    Smooth *smooth; // integrators for rounding detection
    int *moveCount; // counts the number of movements outside the threshold for each touch
    
    // FAUST
    DspFaust *faustDsp;
    long *voices;
}

- (id)initWithFrame:(CGRect)frame withFaustDSP:(DspFaust*)dsp{
    self = [super initWithFrame:frame];
    if(self){
        faustDsp = dsp;
        self.multipleTouchEnabled = YES;
        [self setBackgroundColor:[UIColor blackColor]];
         
        // Declaring default parameters
        parameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                     @"nKeyb":[NSNumber numberWithInt:4],
                                                                     @"maxFingers":[NSNumber numberWithInt:10],
                                                                     @"maxKeybPoly":[NSNumber numberWithInt:16],
                                                                     @"monoMode":[NSNumber numberWithInt:1],
                                                                     @"quantizationMode":[NSNumber numberWithInt:0],
                                                                     @"interKeybSlideAllowed":[NSNumber numberWithInt:1],
                                                                     @"arpegiatorOn":[NSNumber numberWithInt:0], // TODO
                                                                     @"roundingUpdateSpeed":[NSNumber numberWithFloat:0.06],
                                                                     @"roundingSmoothPole":[NSNumber numberWithFloat:0.9],
                                                                     @"roundingThreshold":[NSNumber numberWithFloat:3],
                                                                     @"roundingDeactCycles":[NSNumber numberWithInt:5]
                                                                     }];
        // keyboard dependent parameters
        for(int i=0; i<[parameters[@"nKeyb"] intValue]; i++){
            if([parameters[[NSString stringWithFormat:@"keyb%d_nKeys",i]] intValue] == 0){
                parameters[[NSString stringWithFormat:@"keyb%d_nKeys",i]] = [NSNumber numberWithInt:7];
            }
            if(parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",i]] == 0){
                parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",i]] = [NSNumber numberWithInt:(48 + i*12)];
            }
            if(parameters[[NSString stringWithFormat:@"keyb%d_scale",i]] == 0){
                parameters[[NSString stringWithFormat:@"keyb%d_scale",i]] = [NSNumber numberWithInt:0];
            }
            if(parameters[[NSString stringWithFormat:@"keyb%d_showNotesName",i]] == 0){
                parameters[[NSString stringWithFormat:@"keyb%d_showNotesName",i]] = [NSNumber numberWithInt:1];
            }
            if(parameters[[NSString stringWithFormat:@"keyb%d_rootPos",i]] == 0){
                parameters[[NSString stringWithFormat:@"keyb%d_rootPos",i]] = [NSNumber numberWithInt:0];
            }
            if(parameters[[NSString stringWithFormat:@"keyb%d_orientation",i]] == 0){
                parameters[[NSString stringWithFormat:@"keyb%d_orientation",i]] = [NSNumber numberWithInt:0];
            }
            if(parameters[[NSString stringWithFormat:@"keyb%d_keybMode",i]] == 0){
                parameters[[NSString stringWithFormat:@"keyb%d_keybMode",i]] = [NSNumber numberWithInt:1];
            }
        }
         
        NSString *JSONInterface = [NSString stringWithUTF8String:faustDsp->getJSONMeta()];
        // isolating the parameters of SmartKeyboard from the JSON description and checking if the key exist
        NSRange r1 = [JSONInterface rangeOfString:@"SmartKeyboard{"];
        
        // processing the metadata and updating the global parameters with the configuration from the Faust file
        if(r1.length>0){
            NSRange r2 = [[JSONInterface substringFromIndex:r1.location] rangeOfString:@"}"];
            NSRange rSub = NSMakeRange(r1.location + r1.length-1, r2.location-r1.length+2);
            NSString *JSONSmartKeyboard = [[JSONInterface substringWithRange:rSub] stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
            NSError *error;
            NSDictionary *userParameters = [NSJSONSerialization JSONObjectWithData:[JSONSmartKeyboard dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            // updating default parameters with user defined parameters
            if(error == nil){
                for(int i=0; i<[userParameters count]; i++){
                    parameters[[userParameters allKeys][i]] = [NSNumber numberWithInt:[[userParameters valueForKey:[userParameters allKeys][i]] intValue]];
                }
            }
            else{
                printf("Error in the JSON interface descriptiom\n");
            }
        }
        
        touchDel = 2; // we just need a "2 samples delay" but we can add more if necessary
        [self buildInterface]; // screen interface is built based on the description contained in "parameters"
        [self startMotion]; // starting to retrieve sensor data
        
        if([parameters[@"quantizationMode"] intValue] == 2){
            [NSThread detachNewThreadSelector:@selector(pitchRounding) toTarget:self withObject:nil];
        }
        cancelOnce = true;
    }
    return self;
}

/***************************************************************************
 BUILDS THE KEYBOARD INTERFACE
    This is done based on what is indicated in the parameters dictionnary.
    This method can be called everytime the parameters of the interface have
    changed.
 ***************************************************************************/
- (void)buildInterface{
    [self clean]; // dealocate previous instances first
    UIon = true;
    
    // allocate memory and initialize the different elements
    touchDiff = new float [[parameters[@"maxFingers"] intValue]];
    previousTouchPoints = new CGPoint*[touchDel];
    for(int i=0; i<touchDel; i++){
        previousTouchPoints[i] = new CGPoint [[parameters[@"maxFingers"] intValue]];
    }
    previousTouchedKeys = new int[[parameters[@"maxFingers"] intValue]];
    previousTouchedKeyboards = new int[[parameters[@"maxFingers"] intValue]];
    moveCount = new int[[parameters[@"maxFingers"] intValue]];
    rounding = new Boolean[[parameters[@"maxFingers"] intValue]];
    smooth = new Smooth[[parameters[@"maxFingers"] intValue]];
    voices = new long[[parameters[@"maxFingers"] intValue]];
    for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
        touchDiff[i] = 0;
        for(int j=0; j<touchDel; j++){
            previousTouchPoints[j][i].x = -1;
            previousTouchPoints[j][i].y = -1;
        }
        previousTouchedKeys[i] = -1;
        previousTouchedKeyboards[i] = -1;
        moveCount[i] = 0;
        smooth[i].setSmooth([parameters[@"roundingSmoothPole"] floatValue]);
        rounding[i] = true;
        voices[i] = -1;
    }
    
    fingersOnScreenCount = 0;
    
    zoneWidths = new CGFloat [[parameters[@"nKeyb"] intValue]];
    fingersOnKeyboardsCount = new int [[parameters[@"nKeyb"] intValue]];
    monoMode_previousActiveFinger = new int [[parameters[@"nKeyb"] intValue]];
    
    // dimension of the zones, zones cover the entire view
    zoneHeight = (self.frame.size.height)/[parameters[@"nKeyb"] intValue];
    
    // initializing the different keyboards
    zones = [[NSMutableArray alloc] init];
    for(int i=0; i<[parameters[@"nKeyb"] intValue]; i++){
        // if no poly mode, then no keyboard mode is automatically activated
        if([parameters[@"maxKeybPoly"] intValue] <= 0){
            parameters[[NSString stringWithFormat:@"keyb%d_keybMode",i]] = [NSNumber numberWithInt:0];
        }
        // initializing the zones (keys) of the different keyboards
        [zones insertObject:[[NSMutableArray alloc] init] atIndex:i];
        zoneWidths[i] = self.frame.size.width/[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",i]] intValue];
        fingersOnKeyboardsCount[i] = 0;
        monoMode_previousActiveFinger[i] = -1;
        for(int j=0;j<[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",i]] intValue];j++){
            // Zones have 1 pt on each side but touch detection happens on the entire screen. With this strategy we lose 1 pt on the 2 extermities of the interface but it makes things much easier
            [[zones objectAtIndex:i] insertObject:[[Zone alloc] initWithFrame:CGRectMake(zoneWidths[i]*j+1, zoneHeight*i+1, zoneWidths[i]-2, zoneHeight-2)] atIndex:j];
            [[[zones objectAtIndex:i] objectAtIndex:j] setImageOn:[UIImage imageNamed:@"keyDown.png"]];
            [[[zones objectAtIndex:i] objectAtIndex:j] setImageOff:[UIImage imageNamed:@"keyUp.png"]];
            // set/display note name in the key only in keyboard mode and when scale is chromatic
            if([parameters[[NSString stringWithFormat:@"keyb%d_keybMode",i]] boolValue] &&
               [parameters[[NSString stringWithFormat:@"keyb%d_scale",i]] intValue]<1 &&
               [parameters[[NSString stringWithFormat:@"keyb%d_showNotesName",i]] intValue]>0){
                if([parameters[[NSString stringWithFormat:@"keyb%d_orientation",i]] boolValue]){
                    [[[zones objectAtIndex:i] objectAtIndex:j] setNote:[self applyScale:[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",i]] intValue]+[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",i]] intValue]-j-1 withKeyboardId:i]];
                }
                else{
                    [[[zones objectAtIndex:i] objectAtIndex:j] setNote:[self applyScale:j+[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",i]] intValue] withKeyboardId:i]];
                }
            }
            [[[zones objectAtIndex:i] objectAtIndex:j] setKeyboardMode:[parameters[[NSString stringWithFormat:@"keyb%d_keybMode",i]] boolValue]];
            [self addSubview:[[zones objectAtIndex:i] objectAtIndex:j]];
        }
    }
    
    // case where no pitch keyboard is on: we trigger the main voice on startup
    if([parameters[@"maxKeybPoly"] intValue] == 0){
        voices[0] = faustDsp->newVoice();
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    cancelOnce = true;
    if ([touches count] > 0) {
        for (UITouch *touch in touches) {
            for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
                // we look for the first available "touch tracker"
                if(previousTouchPoints[0][i].x == -1){
                    touchDiff[i] = 0;
                    [self processTouchEvent:1 withTouchPoint:[touch locationInView: self] withFingerId:i];
                    // updating finger tracking
                    previousTouchPoints[0][i] = [touch locationInView: self];
                    break;
                }
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if ([touches count] > 0) {
        for (UITouch *touch in touches) {
            CGPoint touchPoint = [touch locationInView: self];
            CGPoint systemPreviousTouchPoint = [touch previousLocationInView: self];
            for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
                if(previousTouchPoints[0][i].x == systemPreviousTouchPoint.x && previousTouchPoints[0][i].y == systemPreviousTouchPoint.y){
                    touchDiff[i] = abs(touchPoint.x - previousTouchPoints[0][i].x);
                    [self processTouchEvent:2 withTouchPoint:[touch locationInView: self] withFingerId:i];
                    //cout << abs(currentTouchPoints[i].x - previousTouchPoints[0][i].x) << "\n";
                    // updating the finger tracking system
                    previousTouchPoints[1][i] = previousTouchPoints[0][i];
                    previousTouchPoints[0][i] = [touch locationInView: self];
                    break;
                }
            }
        }
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if ([touches count] > 0) {
        for (UITouch *touch in touches) {
            CGPoint systemPreviousTouchPoint = [touch previousLocationInView: self];
            for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
                if((previousTouchPoints[0][i].x == systemPreviousTouchPoint.x && previousTouchPoints[0][i].y == systemPreviousTouchPoint.y) || (previousTouchPoints[1][i].x == systemPreviousTouchPoint.x && previousTouchPoints[1][i].y == systemPreviousTouchPoint.y)){
                    touchDiff[i] = -10000;
                    [self processTouchEvent:0 withTouchPoint:[touch locationInView: self] withFingerId:i];
                    // updating the finger tracking system
                    previousTouchPoints[0][i].x = -1;
                    previousTouchPoints[0][i].y = -1;
                    break;
                }
            }
        }
    }
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(cancelOnce){
        [self resetKeyboard];
        cancelOnce = false;
    }
}

/***************************************************************************
 PROCESS TOUCH EVENT
    Process touch events by tracking the position of each finger on
    the screen and sending keyboard actions. Thus it takes care
    of handling polyphony.
 ***************************************************************************/

-(void)processTouchEvent:(int)eventType withTouchPoint:(CGPoint)touchPoint withFingerId:(int)fingerId{
    // we calculate the position of the touch on the keyboards matrix
    int currentKeyboard = fmin(int(touchPoint.y/zoneHeight),([parameters[@"nKeyb"] intValue]-1));
    currentContinuousKey = touchPoint.x/zoneWidths[currentKeyboard];
    currentKeyboardY = fmod(touchPoint.y/zoneHeight,1);
    int currentKeyIdInRow = fmin(int(currentContinuousKey),([parameters[[NSString stringWithFormat:@"keyb%d_nKeys",currentKeyboard]] intValue]-1));
    
    // we make sure that the touch happened inside the keyboards matrix area
    if(currentKeyboard >= 0){
        
        // first we track fingers in the different keyboards (this is necessary to control the number of voices of polyphony of each keybaords)
        // if touch up
        if(eventType == 0){
            // counting fingers on the keyboard...
            fingersOnKeyboardsCount[currentKeyboard] = fmax(0,fingersOnKeyboardsCount[currentKeyboard]-1);
            fingersOnScreenCount = fmax(0,fingersOnScreenCount-1);
        }
        // if touch down
        else if(eventType == 1){
            // counting fingers on the keyboard...
            fingersOnKeyboardsCount[currentKeyboard]++;
            fingersOnScreenCount++;
        }
        // if move
        else if(eventType == 2 && currentKeyboard != previousTouchedKeyboards[fingerId]){
            // counting fingers on the keyboard...
            fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]] = fmax(0,fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]]-1);
            fingersOnKeyboardsCount[currentKeyboard]++;
        }
        
        // no poly mode
        if([parameters[@"maxKeybPoly"] intValue] <= 0){
            [self sendSynthControlAction:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
        }
        // poly mode
        else{
            // deffault mode if poly keyboards
            if([parameters[@"monoMode"] intValue] == 0 || [parameters[@"maxKeybPoly"] intValue]>1){
                // if touch up
                if(eventType == 0){
                    // cancel corresponding previous key (in case of fast move event)
                    if(previousTouchedKeyboards[fingerId] != currentKeyboard || previousTouchedKeys[fingerId] != currentKeyIdInRow){
                        [self sendKeyboardAction:0 withKeyboardId:previousTouchedKeyboards[fingerId] withKeyId:previousTouchedKeys[fingerId] withFingerId:fingerId];
                    }
                    // cancel corresponding key
                    [self sendKeyboardAction:0 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                    currentKeyboard = -1;
                    currentKeyIdInRow = -1;
                }
                // if touch down
                else if(eventType == 1 && fingersOnKeyboardsCount[currentKeyboard]<=[parameters[@"maxKeybPoly"] intValue]){
                    [self sendKeyboardAction:1 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                }
                // if move
                else if(eventType == 2){
                    // moved to another keyboard
                    if(currentKeyboard != previousTouchedKeyboards[fingerId]){
                        // cancel key in previous keyboard
                        [self sendKeyboardAction:0 withKeyboardId:previousTouchedKeyboards[fingerId] withKeyId:previousTouchedKeys[fingerId] withFingerId:fingerId];
                        // initiate new event only if there are keys available
                        if(fingersOnKeyboardsCount[currentKeyboard]<=[parameters[@"maxKeybPoly"] intValue] && [parameters[@"interKeybSlideAllowed"] boolValue]){
                            [self sendKeyboardAction:1 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                        }
                    }
                    // moved to another key within the same keyboard
                    else if(currentKeyIdInRow != previousTouchedKeys[fingerId] && [[[zones objectAtIndex:previousTouchedKeyboards[fingerId]] objectAtIndex:previousTouchedKeys[fingerId]] getStatus] == 1){
                        // cancel previous key
                        [self sendKeyboardAction:3 withKeyboardId:previousTouchedKeyboards[fingerId] withKeyId:previousTouchedKeys[fingerId] withFingerId:fingerId];
                        // inititate new event
                        [self sendKeyboardAction:4 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                    }
                    // move within the same key
                    else{
                        [self sendKeyboardAction:2 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                    }
                }
            }
            
            else if([parameters[@"monoMode"] intValue] == 1){
                int currentKeyDown = -1;
                for(int i=0; i<[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",currentKeyboard]] intValue]; i++){
                    if([[[zones objectAtIndex:currentKeyboard] objectAtIndex:i] getStatus] == 1){
                        currentKeyDown = i;
                    }
                }
                
                // if touch up
                if(eventType == 0){
                    // cancel corresponding previous key (in case of fast move event)
                    if(previousTouchedKeyboards[fingerId] != currentKeyboard || previousTouchedKeys[fingerId] != currentKeyIdInRow){
                        [self sendKeyboardAction:0 withKeyboardId:previousTouchedKeyboards[fingerId] withKeyId:previousTouchedKeys[fingerId] withFingerId:fingerId];
                    }
                    // cancel corresponding key
                    [self sendKeyboardAction:0 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                    if(fingersOnKeyboardsCount[currentKeyboard]>0){
                        float kb = currentKeyboard*zoneHeight;
                        for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
                            if(previousTouchPoints[0][i].y >= kb && previousTouchPoints[0][i].y < zoneHeight+kb && previousTouchPoints[0][i].y != touchPoint.y && i != monoMode_previousActiveFinger[currentKeyboard]){
                                currentContinuousKey = previousTouchPoints[0][i].x/zoneWidths[currentKeyboard];
                                currentKeyIdInRow = fmin(int(currentContinuousKey),([parameters[[NSString stringWithFormat:@"keyb%d_nKeys",currentKeyboard]] intValue]-1));
                                [self sendKeyboardAction:1 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:i];
                                monoMode_previousActiveFinger[currentKeyboard] = i;
                                break;
                            }
                        }
                    }
                    else{
                        currentKeyboard = -1;
                        currentKeyIdInRow = -1;
                    }
                }
                // if touch down
                else if(eventType == 1){
                    if(currentKeyDown>=0){
                        [self sendKeyboardAction:0 withKeyboardId:currentKeyboard withKeyId:currentKeyDown withFingerId:monoMode_previousActiveFinger[currentKeyboard]];
                    }
                    [self sendKeyboardAction:1 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                    monoMode_previousActiveFinger[currentKeyboard] = fingerId;
                }
                // if move
                else if(eventType == 2){
                    // moved to another keyboard
                    if(currentKeyboard != previousTouchedKeyboards[fingerId]){
                        // cancel key in previous keyboard
                        [self sendKeyboardAction:0 withKeyboardId:previousTouchedKeyboards[fingerId] withKeyId:previousTouchedKeys[fingerId] withFingerId:fingerId];
                        // initiate new event only if there are keys available
                        if(fingersOnKeyboardsCount[currentKeyboard]<=[parameters[@"maxKeybPoly"] intValue] && [parameters[@"interKeybSlideAllowed"] boolValue]){
                            [self sendKeyboardAction:1 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                        }
                    }
                    // moved to another key within the same keyboard
                    else if(currentKeyIdInRow != previousTouchedKeys[fingerId] && [[[zones objectAtIndex:previousTouchedKeyboards[fingerId]] objectAtIndex:previousTouchedKeys[fingerId]] getStatus] == 1){
                        // cancel previous key
                        [self sendKeyboardAction:3 withKeyboardId:previousTouchedKeyboards[fingerId] withKeyId:previousTouchedKeys[fingerId] withFingerId:fingerId];
                        // inititate new event
                        [self sendKeyboardAction:4 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                    }
                    // move within the same key
                    else{
                        [self sendKeyboardAction:2 withKeyboardId:currentKeyboard withKeyId:currentKeyIdInRow withFingerId:fingerId];
                    }
                }
            }
        }
    
        // updating previous data for comparison
        previousTouchedKeyboards[fingerId] = currentKeyboard;
        previousTouchedKeys[fingerId] = currentKeyIdInRow;
    }
    // if touch is outside the keyboards matrix area
    else if(eventType == 2){
        [[[zones objectAtIndex:previousTouchedKeyboards[fingerId]] objectAtIndex:previousTouchedKeys[fingerId]] setStatus:0];
        fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]] = fmax(0,fingersOnKeyboardsCount[previousTouchedKeyboards[fingerId]]-1);
    }
}

/***************************************************************************
 SEND KEYBOARD ACTION
    Reflects the user's actions on the keyboard and send
    synthControlAction
 ***************************************************************************/
-(void)sendKeyboardAction:(int)eventType withKeyboardId:(int)keyboardId withKeyId:(int)keyId withFingerId:(int)fingerId{
    // key up
    if(eventType == 0 || eventType == 3){
        // make sure that the corresponding key is active
        if([[[zones objectAtIndex:keyboardId] objectAtIndex:keyId] getStatus] == 1){
            // check if another finger is present in the zone
            bool otherFingerInKey = false;
            if([parameters[@"monoMode"] intValue] == 0 || [parameters[@"maxKeybPoly"] intValue]>1){
                for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
                    if(keyboardId == previousTouchedKeyboards[i] && keyId == previousTouchedKeys[i] && i != fingerId){
                        otherFingerInKey = true;
                        break;
                    };
                }
            }
            // key physically up only if there are no more fingers in the zone
            if(!otherFingerInKey){
                [[[zones objectAtIndex:keyboardId] objectAtIndex:keyId] setStatus:0];
            }
            [self sendPolySynthControlAction:eventType withKeyboardId:keyboardId withKeyId:keyId withFingerId:fingerId];
            //if(fingersOnScreenCount == 0) [self resetKeyboard];
        }
    }
    // key down
    else if(eventType == 1 || eventType == 4){
        [[[zones objectAtIndex:keyboardId] objectAtIndex:keyId] setStatus:1];
        [self sendPolySynthControlAction:eventType withKeyboardId:keyboardId withKeyId:keyId withFingerId:fingerId];
    }
    // move within the same key
    else if(eventType == 2){
        [self sendPolySynthControlAction:2 withKeyboardId:keyboardId withKeyId:keyId withFingerId:fingerId];
    }
    if(fingersOnScreenCount == 0) [self resetKeyboard]; // TODO: this is kind of a terrible fix but it does the job for now
}

/***************************************************************************
 SEND SYNTH CONTROL ACTION
 Sends non-polyphonic actions to the Faust process depending on events
 happening on the keyboard. Takes care of applying slides,
 scales, etc.
 ***************************************************************************/

-(void)sendSynthControlAction:(int)keyboardId withKeyId:(int)keyId withFingerId:(int)fingerId{
    // TODO: continuous x and y values are always sent: this should be optimized
    // TODO: might need a mechanism to check if voice is on before message gets sent
    
    faustDsp->setParamValue("keyboard", keyboardId);
    faustDsp->setParamValue("key", keyId);
    faustDsp->setParamValue(("x" + std::to_string(fingerId)).c_str(), fmod(currentContinuousKey,1));
    faustDsp->setParamValue(("y" + std::to_string(fingerId)).c_str(), currentKeyboardY);
}

/***************************************************************************
 SEND POLY SYNTH CONTROL ACTION
    Sends polyphonic actions to the Faust process depending on events
    happening on the keyboard. Takes care of applying slides,
    scales, etc.
 ***************************************************************************/

-(void)sendPolySynthControlAction:(int)eventType withKeyboardId:(int)keyboardId withKeyId:(int)keyId withFingerId:(int)fingerId{
    float pitch = 0; // the MIDI pitch of the note
    // delete (note off)
    if((eventType == 0 || (eventType == 3 && [parameters[@"quantizationMode"] intValue] == 0)) && voices[fingerId] != -1){
        pitch = -1;
        faustDsp->setVoiceParamValue("gate", voices[fingerId], 0);
        faustDsp->deleteVoice(voices[fingerId]);
        voices[fingerId] = -1;
        smooth[fingerId].reset();
    }
    // new (note on)
    else if (eventType == 1 || (eventType == 4 && [parameters[@"quantizationMode"] intValue] == 0)){
        // allocating new voice to finger
        voices[fingerId] = faustDsp->newVoice();
        if(voices[fingerId] != -1){
            faustDsp->setVoiceParamValue("gate", voices[fingerId], 1);
        }
        else{
            return;
        }
        
        // setting first pitch (always quantized)
        if([parameters[@"quantizationMode"] intValue] == 0 || ([parameters[@"quantizationMode"] intValue] == 2 && [parameters[[NSString stringWithFormat:@"keyb%d_scale",keyboardId]] intValue] > 0)){
            // inverted keyboard
            if([parameters[[NSString stringWithFormat:@"keyb%d_orientation",keyboardId]] boolValue]){
                pitch = [self applyScale:[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]+[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",keyboardId]] intValue]-keyId-1 withKeyboardId:keyboardId];
            }
            // regular keyboard
            else{
                pitch = [self applyScale:[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]+keyId withKeyboardId:keyboardId];
            }
        }
        else if([parameters[@"quantizationMode"] intValue] == 1 || [parameters[@"quantizationMode"] intValue] == 2){
            float pitchShiftCenter = 0;
            // -0.5 is here to center the pitch at the middle of the key
            if([parameters[@"quantizationMode"] intValue] == 1){
                pitchShiftCenter = 0.5;
            }
            // inverted keyboard
            if([parameters[[NSString stringWithFormat:@"keyb%d_orientation",keyboardId]] boolValue]){
                pitch = [self applyScale:[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]+[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",keyboardId]] intValue]-currentContinuousKey-pitchShiftCenter withKeyboardId:keyboardId];
            }
            // regular keyboard
            else{
                pitch = [self applyScale:currentContinuousKey+[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]-pitchShiftCenter withKeyboardId:keyboardId];
            }
        }
        if(voices[fingerId] != -1){
            if([parameters[@"quantizationMode"] intValue] == 1){
                faustDsp->setVoiceParamValue("freq", voices[fingerId], [self mtof:pitch]);
            }
            else{
                faustDsp->setVoiceParamValue("freq", voices[fingerId], [self mtof:floor(pitch)]);
            }
        }
    }
    // update
    else if(eventType == 2 && ([parameters[@"quantizationMode"] intValue] == 1 || [parameters[@"quantizationMode"] intValue] == 2)){
        
        // Formating pitch
        if([parameters[[NSString stringWithFormat:@"keyb%d_scale",keyboardId]] intValue] > 0 && rounding[fingerId] && [parameters[@"quantizationMode"] intValue] != 1){
            // inverted keyboard
            if([parameters[[NSString stringWithFormat:@"keyb%d_orientation",keyboardId]] boolValue]){
                pitch = [self applyScale:[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]+[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",keyboardId]] intValue]-keyId-1 withKeyboardId:keyboardId];
            }
            // regular keyboard
            else{
                pitch = [self applyScale:[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]+keyId withKeyboardId:keyboardId];
            }
        }
        else {
            float pitchShiftCenter = 0;
            // -0.5 is here to center the pitch at the middle of the key
            if([parameters[@"quantizationMode"] intValue] == 1){
                pitchShiftCenter = 0.5;
            }
            // inverted keyboard
            if([parameters[[NSString stringWithFormat:@"keyb%d_orientation",keyboardId]] boolValue]){
                pitch = [self applyScale:[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]+[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",keyboardId]] intValue]-currentContinuousKey-pitchShiftCenter withKeyboardId:keyboardId];
            }
            // regular keyboard
            else{
                pitch = [self applyScale:currentContinuousKey+[parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue]-pitchShiftCenter withKeyboardId:keyboardId];
            }
        }
        
        // sending pitch to faust
        if(voices[fingerId] != -1){
            if([parameters[@"quantizationMode"] intValue] == 1){
                faustDsp->setVoiceParamValue("freq", voices[fingerId], [self mtof:pitch]);
            }
            else if([parameters[@"quantizationMode"] intValue] == 2){
                if(rounding[fingerId]){ // if rounding is activated, pitch is quantized to the nearest integer
                    faustDsp->setVoiceParamValue("freq", voices[fingerId], [self mtof:floor(pitch)]);
                }
                else{
                    faustDsp->setVoiceParamValue("freq", voices[fingerId], [self mtof:pitch-0.5]);
                }
            }
        }
    }
    
    // TODO: continuous x and y values are always sent: this should be optimized
    if(voices[fingerId] != -1) faustDsp->setVoiceParamValue("keyboard", voices[fingerId], keyboardId);
    if(voices[fingerId] != -1) faustDsp->setVoiceParamValue("key", voices[fingerId], keyId);
    if(voices[fingerId] != -1) faustDsp->setVoiceParamValue("x", voices[fingerId], fmod(currentContinuousKey,1));
    if(voices[fingerId] != -1) faustDsp->setVoiceParamValue("y", voices[fingerId], currentKeyboardY);
}

-(float)applyScale:(float)pitch withKeyboardId:(int)keyboardId{
    int refPitch = [parameters[[NSString stringWithFormat:@"keyb%d_lowestKey",keyboardId]] intValue];
    float keyboardPitch = (pitch-refPitch); // float pitch on keyboard (from 0)
    float scaledPitch = 0; // the final scaled pitch
    
    if([parameters[[NSString stringWithFormat:@"keyb%d_scale",keyboardId]] intValue] == 1){ // major key
        int scaleCoeff[] = {2,2,1,2,2,2,1};
        int scaleAdd = 0;
        if(scaleCoeff[(int)keyboardPitch%7] == 2){
            for(int i=0; i<(int)keyboardPitch; i++){
                if(scaleCoeff[i%7] == 1) scaleAdd--;
            }
        }
        else if(scaleCoeff[(int)keyboardPitch%7] == 1){
            for(int i=0; i<(int)keyboardPitch; i++){
                if(scaleCoeff[i%7] == 2) scaleAdd++;
            }
        }
    
        scaledPitch = refPitch+scaleAdd+
            (keyboardPitch*scaleCoeff[(int)keyboardPitch%7]);
    }
    else{
        scaledPitch = pitch;
    }
    return scaledPitch;
}

-(float)mtof:(float)note{
    return 440.0 * pow(2.0, (note-69.0)/12.0);
}

-(void)resetKeyboard{
    faustDsp->allNotesOff();
    for(int i=0; i<[parameters[@"nKeyb"] intValue]; i++){
        fingersOnKeyboardsCount[i] = 0;
        for(int j=0;j<[parameters[[NSString stringWithFormat:@"keyb%d_nKeys",i]] intValue];j++){
            [[[zones objectAtIndex:i] objectAtIndex:j] setStatus:0];
        }
    }
    for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
        voices[i] = -1;
        for(int j=0; j<touchDel; j++){
            previousTouchPoints[j][i].x = -1;
            previousTouchPoints[j][i].y = -1;
        }
        previousTouchedKeys[i] = -1;
        previousTouchedKeyboards[i] = -1;
        moveCount[i] = 0;
    }
    fingersOnScreenCount = 0;
}

- (void)startMotion
{
    // Motion
    if (_motionManager == nil)
    {
        _motionManager = [[CMMotionManager alloc] init];
        [_motionManager startAccelerometerUpdates];
        [_motionManager startGyroUpdates];
    }
    _motionTimer = [NSTimer scheduledTimerWithTimeInterval:1./kMotionUpdateRate
                                                    target:self
                                                  selector:@selector(updateMotion)
                                                  userInfo:nil
                                                   repeats:YES];
}

// Stop updating sensors
- (void)stopMotion
{
    // Motion
    if (_motionManager != nil)
    {
        [_motionManager stopAccelerometerUpdates];
        [_motionManager stopGyroUpdates];
        //[_motionManager release];
        _motionManager = nil;
        [_motionTimer invalidate];
    }
}

- (void)updateMotion
{
    faustDsp->propagateAcc(0, _motionManager.accelerometerData.acceleration.x * ONE_G);
    faustDsp->propagateAcc(1, _motionManager.accelerometerData.acceleration.y * ONE_G);
    faustDsp->propagateAcc(2, _motionManager.accelerometerData.acceleration.z * ONE_G);
    
    faustDsp->propagateGyr(0, _motionManager.gyroData.rotationRate.x);
    faustDsp->propagateGyr(1, _motionManager.gyroData.rotationRate.y);
    faustDsp->propagateGyr(2, _motionManager.gyroData.rotationRate.z);
}

- (void) pitchRounding{
    while(UIon){
        for(int i=0; i<[parameters[@"maxFingers"] intValue]; i++){
            if(touchDiff[i] != -10000 && voices[i] != -1){
                //
                if(smooth[i].tick(touchDiff[i])>[parameters[@"roundingThreshold"] floatValue] && moveCount[i]<[parameters[@"roundingDeactCycles"] intValue]){
                    rounding[i] = false;
                }
                else{
                    rounding[i] = true;
                    moveCount[i] = 0;
                }
                
                if(touchDiff[i]<1){
                    moveCount[i]++;
                }
            }
        }
        [NSThread sleepForTimeInterval:[parameters[@"roundingUpdateSpeed"] floatValue]];
    }
}

-(void)clean{
    // case where no pitch keyboard is on: we stop the main voice before cleaning
    if([parameters[@"maxKeybPoly"] intValue] == 0 && UIon){
        faustDsp->deleteVoice(voices[0]);
        voices[0] = -1;
    }
    UIon = false;
    if([zones count] > 0){
        for(int i=0; i<[zones count]; i++){
            for(int j=0;j<[[zones objectAtIndex:i] count];j++){
                [[[zones objectAtIndex:i] objectAtIndex:j] removeFromSuperview] ;
            }
        }
        [zones removeAllObjects];
    }
    if(touchDiff){
        delete [] touchDiff;
        touchDiff = NULL;
    }
    if(smooth){
        delete [] smooth;
        smooth = NULL;
    }
    if(previousTouchPoints){
        for(int i=0; i<touchDel; i++){
            delete [] previousTouchPoints[i];
        }
        delete[] previousTouchPoints;
        previousTouchPoints = NULL;
    }
    if(previousTouchedKeyboards){
        delete[] previousTouchedKeyboards;
        previousTouchedKeyboards = NULL;
    }
    if(previousTouchedKeys){
        delete[] previousTouchedKeys;
        previousTouchedKeys = NULL;
    }
    if(zoneWidths){
        delete[] zoneWidths;
        zoneWidths = NULL;
    }
    if(monoMode_previousActiveFinger){
        delete[] monoMode_previousActiveFinger;
        monoMode_previousActiveFinger = NULL;
    }
    if(moveCount){
        delete[] moveCount;
        moveCount = NULL;
    }
    if(voices){
        delete[] voices;
        voices = NULL;
    }
}

// TODO: for now, we assume that memory is deallocated here but we're not 100% sure about that: this has to be checked
-(void)dealloc{
    [self clean];
    [self stopMotion];
}

@end
