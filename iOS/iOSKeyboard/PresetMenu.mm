//
//  PresetMenu.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/27/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "PresetMenu.h"

@implementation PresetMenu{
    NSMutableArray *presetsList;
    UIScrollView *presetsView;
    NSMutableArray *selectButtons;
    NSMutableArray *presetsNameFields;
    UIColor *selectedColor;
    NSString *documentsDirectory;
    
    CGFloat borderSize;
    CGFloat presetsListMargin;
    CGFloat presetsListWidth;
    CGFloat presetsListHeight;
    CGFloat fieldsHeight;
    
    NSInteger nButtons;
    CGFloat buttonsWidth;
    CGFloat buttonsHeight;
}

- (id)initWithFrame:(CGRect)frame withCurrentPreset:(int)preset{
    self = [super initWithFrame:frame];
    if(self){
        [self setBackgroundColor:[UIColor blackColor]];
        
        currentPreset = preset;
        
        selectButtons = [[NSMutableArray alloc] init];
        presetsNameFields = [[NSMutableArray alloc] init];
        presetsList = [[NSMutableArray alloc] init];
        
        selectedColor = [UIColor colorWithRed:1 green:0.5 blue:0.5 alpha:1];
        
        borderSize = 1;
        presetsListMargin = 100;
        presetsListWidth = frame.size.width;
        presetsListHeight = frame.size.height*0.95;
        fieldsHeight = 50;
        
        nButtons = 3;
        buttonsWidth = frame.size.width/nButtons;
        buttonsHeight = frame.size.height-presetsListHeight;
        
        presetsView = [[UIScrollView alloc] initWithFrame:CGRectMake(borderSize+presetsListMargin, borderSize+presetsListMargin, presetsListWidth-borderSize*2-presetsListMargin*2, presetsListHeight-borderSize*2-presetsListMargin*2)];
        [presetsView setBackgroundColor:[UIColor whiteColor]];
        [self addSubview:presetsView];
        
        // Retrieving the list of preset files
        documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        [self updatePresetsList];
        
        // If no preset file, then create one
        if([presetsList count] == 0){
            NSMutableDictionary *keyboardParameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                     @"nKeyb":[NSNumber numberWithInt:4],
                                                                     @"maxFingers":[NSNumber numberWithInt:10],
                                                                     @"maxKeybPoly":[NSNumber numberWithInt:16],
                                                                     @"monoMode":[NSNumber numberWithInt:1],
                                                                     @"quantizationMode":[NSNumber numberWithInt:0],
                                                                     @"interKeybSlideAllowed":[NSNumber numberWithInt:1],
                                                                     @"sendCurrentKey":[NSNumber numberWithInt:1],
                                                                     @"sendCurrentKeyboard":[NSNumber numberWithInt:1],
                                                                     @"sendX":[NSNumber numberWithInt:1],
                                                                     @"sendY":[NSNumber numberWithInt:1],
                                                                     @"roundingUpdateSpeed":[NSNumber numberWithFloat:0.06],
                                                                     @"roundingSmoothPole":[NSNumber numberWithFloat:0.9],
                                                                     @"roundingThreshold":[NSNumber numberWithFloat:3],
                                                                     @"roundingDeactCycles":[NSNumber numberWithInt:5]
                                                                     }];
            NSString *keyboardFilePath = [documentsDirectory stringByAppendingPathComponent:@"Preset 0_keyb"];
            [keyboardParameters writeToFile:keyboardFilePath atomically:YES];
            
            NSMutableDictionary *dspParameters = [NSMutableDictionary dictionary];
            NSString *dspFilePath = [documentsDirectory stringByAppendingPathComponent:@"Preset 0_dsp"];
            [dspParameters writeToFile:dspFilePath atomically:YES];
        }
        
        [self updatePresetsList];
        
        [self buildPresetsTable];
        
        for(int i=0; i<3; i++){
            Button *menuButton = [[Button alloc] initWithFrame:CGRectMake(borderSize+buttonsWidth*i, borderSize+presetsListHeight, buttonsWidth-borderSize*2, buttonsHeight-borderSize*2)];
            menuButton->ID = i;
            [menuButton setOnColor:[UIColor greenColor]];
            [menuButton setOffColor:[UIColor redColor]];
            [menuButton addTarget:self action:@selector(newEventOnMenu:) forControlEvents:UIControlEventValueChanged];
            [self addSubview:menuButton];
        }
    }
    return self;
}

- (void)updatePresetsList{
    NSArray *documentsDirectoryContent = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [presetsList removeAllObjects];
    for(int i=0; i<[documentsDirectoryContent count]; i++){
        if([[documentsDirectoryContent objectAtIndex:i] containsString:@"_keyb"]){
            [presetsList addObject:[[documentsDirectoryContent objectAtIndex:i] stringByReplacingOccurrencesOfString:@"_keyb" withString:@""]];
        }
    }
}

- (void)buildPresetsTable{
    for(int i=0; i<[presetsList count]; i++){
        [selectButtons insertObject:[[Button alloc] initWithFrame:CGRectMake(0, fieldsHeight*i, fieldsHeight, fieldsHeight)] atIndex:i];
        if(i == currentPreset){
            [[selectButtons objectAtIndex:i] setOffColor:selectedColor];
        }
        else{
            [[selectButtons objectAtIndex:i] setOffColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
        }
        [[selectButtons objectAtIndex:i] setID:i];
        [[selectButtons objectAtIndex:i] addTarget:self action:@selector(newEventOnPresetSelect:) forControlEvents:UIControlEventValueChanged];
        [presetsView addSubview:[selectButtons objectAtIndex:i]];
        
        [presetsNameFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(fieldsHeight, fieldsHeight*i, (presetsListWidth-borderSize*2-presetsListMargin*2)-fieldsHeight, fieldsHeight)] atIndex:i];
        [[presetsNameFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.9-(0.1*(i%2)) green:0.9-(0.1*(i%2)) blue:0.9-(0.1*(i%2)) alpha:1]];
        [[presetsNameFields objectAtIndex:i] setTextAlignment:NSTextAlignmentCenter];
        [[presetsNameFields objectAtIndex:i] setText:[presetsList objectAtIndex:i]];
        [[presetsNameFields objectAtIndex:i] setTag:i];
        [[presetsNameFields objectAtIndex:i] addTarget:self action:@selector(newEventOnPresetName:) forControlEvents:UIControlEventEditingDidEnd];
        [presetsView addSubview:[presetsNameFields objectAtIndex:i]];
    }
}

- (void)clearPresetsTable{
    for(int i=0; i<[selectButtons count]; i++){
        [[selectButtons objectAtIndex:i] removeFromSuperview];
    }
    [selectButtons removeAllObjects];
    for(int i=0; i<[presetsNameFields count]; i++){
        [[presetsNameFields objectAtIndex:i] removeFromSuperview];
    }
    [presetsNameFields removeAllObjects];
}

- (IBAction)newEventOnMenu:(Button*)sender{
    if(sender->on){
        if(sender->ID == 0){
            // copying current keyboard preset to new file
            NSString *currentKeyboardPresetFile = [documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:currentPreset] stringByAppendingString:@"_keyb"]];
            [[NSFileManager defaultManager] copyItemAtPath:currentKeyboardPresetFile toPath:[documentsDirectory stringByAppendingPathComponent:@"*New Preset*_keyb"] error:nil];
            
            // copy dsp preset too
            NSString *currentDspPresetFile = [documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:currentPreset] stringByAppendingString:@"_dsp"]];
            [[NSFileManager defaultManager] copyItemAtPath:currentDspPresetFile toPath:[documentsDirectory stringByAppendingPathComponent:@"*New Preset*_dsp"] error:nil];
            
            [self updatePresetsList];
            [self clearPresetsTable];
            [self buildPresetsTable];
        }
        else if(sender->ID == 1 && [presetsList count]>1){
            [[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:currentPreset] stringByAppendingString:@"_keyb"]] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:currentPreset] stringByAppendingString:@"_dsp"]] error:nil];
            currentPreset = 0;
            
            [self updatePresetsList];
            [self clearPresetsTable];
            [self buildPresetsTable];
        }
        else if(sender->ID == 2){
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}

- (IBAction)newEventOnPresetSelect:(Button*)sender{
    if(sender->on){
        if(sender->ID != currentPreset){
            [[selectButtons objectAtIndex:currentPreset] setOffColor:[UIColor colorWithRed:0.7-(0.1*(currentPreset%2)) green:0.7-(0.1*(currentPreset%2)) blue:0.7-(0.1*(currentPreset%2)) alpha:1]];
            [[selectButtons objectAtIndex:sender->ID] setOffColor:selectedColor];
            currentPreset = sender->ID;
        }
    }
}

- (IBAction)newEventOnPresetName:(UITextField*)sender{
    [[NSFileManager defaultManager] moveItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:sender.tag] stringByAppendingString:@"_keyb"]] toPath:[documentsDirectory stringByAppendingPathComponent:[sender.text stringByAppendingString:@"_keyb"]] error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:sender.tag] stringByAppendingString:@"_dsp"]] toPath:[documentsDirectory stringByAppendingPathComponent:[sender.text stringByAppendingString:@"_dsp"]] error:nil];
    
    [self updatePresetsList];
    [self clearPresetsTable];
    [self buildPresetsTable];
}

@end
