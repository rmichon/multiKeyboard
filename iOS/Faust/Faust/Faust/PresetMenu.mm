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
    UILabel *presetsTitleLabel;
    UIScrollView *presetsView;
    UIView *audioSettingsView;
    UIView *popupWindow;
    NSMutableArray *selectButtons;
    NSMutableArray *presetsNameFields;
    UIColor *selectedButtonColor, *presetsListTitleColor, *presetsListTitleBackgroundColor, *oddPresetsNameFieldsBackgroundColor, *evenPresetsNameFieldsBackgroundColor, *selectedPresetsNameFieldsBackgroundColor, *menuButtonsTextColor, *menuButtonsBackgroundColor, *presetsNameColor, *oddSelectButtonsColor, *evenSelectButtonsColor;
    NSString *documentsDirectory;
    
    CGFloat borderSize; // space between elements in the UI
    CGFloat presetsListXOffset;
    CGFloat presetsListYOffset;
    CGFloat presetsListWidth; // for the entire zone...
    CGFloat presetsListHeight; // for the entire zone...
    CGFloat fieldsHeight; // in the list...
    CGFloat presetsListFontSize;
    CGFloat presetsListTitleFontSize;
    CGFloat menuButtonsFontSize;
    
    NSInteger nMenuButtons; // number of menu buttons
    CGFloat buttonsWidth;
    CGFloat buttonsHeight;
    CGFloat audioSettingsLabelsWidth;
    CGFloat popupWindowWidth;
    CGFloat popupWindowHeight;
    
    NSString *audioSettingsFile;
    NSDictionary *audioSettings;
}

- (id)initWithFrame:(CGRect)frame withCurrentPreset:(NSInteger)preset{
    self = [super initWithFrame:frame];
    if(self){
        currentPreset = preset;
        
        selectButtons = [[NSMutableArray alloc] init];
        presetsNameFields = [[NSMutableArray alloc] init];
        presetsList = [[NSMutableArray alloc] init];
        
        // Color maps
        selectedButtonColor = [UIColor colorWithRed:1 green:0.3 blue:0.3 alpha:0.7];
        presetsListTitleColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1];
        presetsListTitleBackgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.7];
        oddPresetsNameFieldsBackgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.7];
        evenPresetsNameFieldsBackgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.7];
        selectedPresetsNameFieldsBackgroundColor = [UIColor colorWithRed:1 green:0.7 blue:0.7 alpha:0.7];
        menuButtonsTextColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1];
        menuButtonsBackgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.7];
        presetsNameColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
        oddSelectButtonsColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.7];
        evenSelectButtonsColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.7];
        
        // other parameters
        presetsListTitleFontSize = 24;
        presetsListFontSize = 22;
        menuButtonsFontSize = 20;
        
        // we scale the size of the font in function of the screen size, this is kind of dirty but it works
        CGFloat referenceWidth = 1024;
        presetsListTitleFontSize = presetsListTitleFontSize*frame.size.width/referenceWidth;
        presetsListFontSize = presetsListTitleFontSize*frame.size.width/referenceWidth;
        menuButtonsFontSize = presetsListTitleFontSize*frame.size.width/referenceWidth;
        
        // positions
        nMenuButtons = 4;
        borderSize = 1;
        presetsListXOffset = frame.size.width/12;
        presetsListYOffset = frame.size.height/6;
        presetsListWidth = frame.size.width;
        presetsListHeight = frame.size.height*0.92;
        fieldsHeight = frame.size.height/18;
        buttonsWidth = frame.size.width/nMenuButtons;
        buttonsHeight = frame.size.height-presetsListHeight;
        audioSettingsLabelsWidth = frame.size.width/6;
        popupWindowWidth = frame.size.width/3;
        popupWindowHeight = frame.size.height/4;
        
        // Setting background picture
        UIGraphicsBeginImageContextWithOptions(self.frame.size,NO,2.0f);
        [[UIImage imageNamed:@"mainBackground.jpg"] drawInRect:self.bounds];
        UIImage *picOn = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.backgroundColor = [UIColor colorWithPatternImage:picOn];
        
        // Title of the preset column list
        presetsTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(borderSize+presetsListXOffset+fieldsHeight, borderSize+presetsListYOffset, (presetsListWidth-borderSize*2-presetsListXOffset*2)-fieldsHeight, fieldsHeight)];
        [presetsTitleLabel setBackgroundColor:presetsListTitleBackgroundColor];
        [presetsTitleLabel setTextColor:presetsListTitleColor];
        [presetsTitleLabel setTextAlignment:NSTextAlignmentCenter];
        [presetsTitleLabel setFont:[UIFont boldSystemFontOfSize:presetsListTitleFontSize]];
        presetsTitleLabel.text = @"Presets Name";
        [self addSubview:presetsTitleLabel];
        
        // Where the presets list will be
        presetsView = [[UIScrollView alloc] initWithFrame:CGRectMake(borderSize+presetsListXOffset, borderSize+presetsListYOffset+fieldsHeight, presetsListWidth-borderSize*2-presetsListXOffset*2, presetsListHeight-borderSize*2-presetsListXOffset*2-fieldsHeight)];
        [self addSubview:presetsView];
        
        // Retrieving the list of preset files
        documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        [self updatePresetsList];
        
        // If no presets (first run), then create one
        if([presetsList count] == 0){
            [self createDefaultPresetFile];
            [self updatePresetsList];
        }
        
        [self buildPresetsTable];
        [self buildMenu];
        
        // reading audio settings from saved file
        audioSettingsFile = [documentsDirectory stringByAppendingPathComponent:@"audioSettings"];
        audioSettings = [[NSDictionary alloc] initWithContentsOfFile:audioSettingsFile];
        
        [self buildAudioSettingsTable];
        
        [self buildPopupWindow];
    }
    return self;
}

// udpate preset lists based on active presets files
- (void)updatePresetsList{
    NSArray *documentsDirectoryContent = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [presetsList removeAllObjects];
    for(int i=0; i<[documentsDirectoryContent count]; i++){
        if([[documentsDirectoryContent objectAtIndex:i] containsString:@"_keyb"]){
            [presetsList addObject:[[documentsDirectoryContent objectAtIndex:i] stringByReplacingOccurrencesOfString:@"_keyb" withString:@""]];
        }
    }
}

// creates the delete confirmation popup window
- (void)buildPopupWindow{
    popupWindow = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2-popupWindowWidth/2, self.frame.size.height/2-popupWindowHeight/2, popupWindowWidth, popupWindowHeight)];
    [popupWindow setBackgroundColor:oddPresetsNameFieldsBackgroundColor];
    [self addSubview:popupWindow];
    
    UILabel *popupMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, popupWindowWidth, popupWindowHeight-fieldsHeight-borderSize*2)];
    [popupMessage setTextAlignment:NSTextAlignmentCenter];
    [popupMessage setFont:[UIFont systemFontOfSize:presetsListFontSize]];
    popupMessage.numberOfLines = 2;
    [popupMessage setText:@"Are you sure you want to delete this preset?"];
    [popupWindow addSubview:popupMessage];
    
    CGFloat popupWindowButtonsWidth = popupWindowWidth/2-borderSize*2;
    NSArray *popupWindowButtonsLabels = [[NSArray alloc] initWithObjects:@"No", @"Yes", nil];
    for(int i=0; i<2; i++){
        Button *currentButton = [[Button alloc] initWithFrame:CGRectMake(borderSize+(popupWindowButtonsWidth+borderSize)*i, popupWindowHeight-fieldsHeight-borderSize, popupWindowButtonsWidth, fieldsHeight)];
        [currentButton setOnColor:menuButtonsBackgroundColor];
        [currentButton setOffColor:menuButtonsBackgroundColor];
        [currentButton setTextColor:menuButtonsTextColor];
        [currentButton setTextFont:[UIFont systemFontOfSize:presetsListFontSize]];
        [currentButton setText:[popupWindowButtonsLabels objectAtIndex:i]];
        [currentButton setTag:i];
        [currentButton addTarget:self action:@selector(newEventOnPopupWindow:) forControlEvents:UIControlEventValueChanged];
        [popupWindow addSubview:currentButton];
    }
    
    [popupWindow setHidden:true];
}

// builds the menu bar
- (void)buildMenu{
    NSArray *menuButtonsLabel = [[NSArray alloc] initWithObjects:@"+ Add Preset", @"- Delete Preset", @"Audio Settings", @"Run Preset :>", nil];
    for(int i=0; i<nMenuButtons; i++){
        Button *menuButton = [[Button alloc] initWithFrame:CGRectMake(borderSize+buttonsWidth*i, borderSize+presetsListHeight, buttonsWidth-borderSize*2, buttonsHeight-borderSize*2)];
        [menuButton setTag:i];
        [menuButton setOnColor:menuButtonsBackgroundColor];
        [menuButton setOffColor:menuButtonsBackgroundColor];
        [menuButton setTextColor:menuButtonsTextColor];
        [menuButton setTextFont:[UIFont systemFontOfSize:menuButtonsFontSize]];
        [menuButton setText:[menuButtonsLabel objectAtIndex:i]];
        [menuButton addTarget:self action:@selector(newEventOnMenu:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:menuButton];
    }
}

// build the preset table based on the preset list
- (void)buildPresetsTable{
    for(int i=0; i<[presetsList count]; i++){
        [selectButtons insertObject:[[Button alloc] initWithFrame:CGRectMake(0, fieldsHeight*i, fieldsHeight, fieldsHeight)] atIndex:i];
        if(i == currentPreset){
            [[selectButtons objectAtIndex:i] setOffColor:selectedButtonColor];
            [[selectButtons objectAtIndex:i] setOnColor:selectedButtonColor];
        }
        else{
            if(i%2 == 1){
                [[selectButtons objectAtIndex:i] setOffColor:evenSelectButtonsColor];
                [[selectButtons objectAtIndex:i] setOnColor:evenSelectButtonsColor];
            }
            else{
                [[selectButtons objectAtIndex:i] setOffColor:oddSelectButtonsColor];
                [[selectButtons objectAtIndex:i] setOnColor:oddSelectButtonsColor];
            }
        }
        [[selectButtons objectAtIndex:i] setTag:i];
        [[selectButtons objectAtIndex:i] addTarget:self action:@selector(newEventOnPresetSelect:) forControlEvents:UIControlEventValueChanged];
        [presetsView addSubview:[selectButtons objectAtIndex:i]];
        
        [presetsNameFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(fieldsHeight, fieldsHeight*i, (presetsListWidth-borderSize*2-presetsListXOffset*2)-fieldsHeight, fieldsHeight)] atIndex:i];
        if(i == currentPreset){
            [[presetsNameFields objectAtIndex:i] setBackgroundColor:selectedPresetsNameFieldsBackgroundColor];
        }
        else{
            if(i%2 == 1){
                [[presetsNameFields objectAtIndex:i] setBackgroundColor:evenPresetsNameFieldsBackgroundColor];
            }
            else{
                [[presetsNameFields objectAtIndex:i] setBackgroundColor:oddPresetsNameFieldsBackgroundColor];
            }
        }
        [[presetsNameFields objectAtIndex:i] setTextAlignment:NSTextAlignmentCenter];
        [[presetsNameFields objectAtIndex:i] setFont:[UIFont systemFontOfSize:presetsListFontSize]];
        [[presetsNameFields objectAtIndex:i] setTextColor:presetsNameColor];
        [[presetsNameFields objectAtIndex:i] setText:[presetsList objectAtIndex:i]];
        [[presetsNameFields objectAtIndex:i] setTag:i];
        [[presetsNameFields objectAtIndex:i] addTarget:self action:@selector(newEventOnPresetName:) forControlEvents:UIControlEventEditingDidEnd];
        [presetsView addSubview:[presetsNameFields objectAtIndex:i]];
    }
    presetsView.contentSize = CGSizeMake(presetsListWidth-borderSize*2-presetsListXOffset*2, [presetsList count]*fieldsHeight);
}

// creates the audio settings table
- (void)buildAudioSettingsTable{
    audioSettingsView = [[UIView alloc] initWithFrame:CGRectMake(borderSize+presetsListXOffset, borderSize+presetsListYOffset, presetsListWidth-borderSize*2-presetsListXOffset*2, presetsListHeight-borderSize*2-presetsListXOffset*2)];
    [self addSubview:audioSettingsView];
    
    NSArray *audioSettingsLabels = [[NSArray alloc] initWithObjects:@"Sampling Rate", @"Buffer Size", nil];
    for(int i=0; i<[audioSettingsLabels count]; i++){
        UILabel *currentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, fieldsHeight*i, audioSettingsLabelsWidth, fieldsHeight)];
        [currentLabel setTextAlignment:NSTextAlignmentCenter];
        [currentLabel setTextColor:menuButtonsTextColor];
        [currentLabel setFont:[UIFont systemFontOfSize:presetsListFontSize]];
        [currentLabel setText:[audioSettingsLabels objectAtIndex:i]];
        if(i%2 == 1){
            [currentLabel setBackgroundColor:evenSelectButtonsColor];
        }
        else{
            [currentLabel setBackgroundColor:oddSelectButtonsColor];
        }
        [audioSettingsView addSubview:currentLabel];
        
        UITextField *currentValueField = [[UITextField alloc] initWithFrame:CGRectMake(audioSettingsLabelsWidth, fieldsHeight*i, (presetsListWidth-borderSize*2-presetsListXOffset*2)-audioSettingsLabelsWidth, fieldsHeight)];
        if(i%2 == 1){
            [currentValueField setBackgroundColor:evenPresetsNameFieldsBackgroundColor];
        }
        else{
            [currentValueField setBackgroundColor:oddPresetsNameFieldsBackgroundColor];
        }
        [currentValueField setTextAlignment:NSTextAlignmentCenter];
        [currentValueField setFont:[UIFont systemFontOfSize:presetsListFontSize]];
        [currentValueField setTextColor:presetsNameColor];
        if(i == 0){
            [currentValueField setText:[NSString stringWithFormat:@"%d", [audioSettings[@"SR"] intValue]]];
        }
        else if (i == 1){
            [currentValueField setText:[NSString stringWithFormat:@"%d", [audioSettings[@"bufferLength"] intValue]]];
        }
        [currentValueField setTag:i];
        [currentValueField addTarget:self action:@selector(newEventOnAudioSettings:) forControlEvents:UIControlEventEditingDidEnd];
        [audioSettingsView addSubview:currentValueField];
    }
    [audioSettingsView setHidden:true];
}

// clean presets table (dealloc memory, etc.)
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

// Creates a set of new default preset file
- (void)createDefaultPresetFile{
    NSMutableDictionary *keyboardParameters = [NSMutableDictionary dictionaryWithDictionary:
        @{
          @"Number of Keyboards":[NSNumber numberWithInt:4],
          @"Max Fingers":[NSNumber numberWithInt:10],
          @"Max Keyboard Polyphony":[NSNumber numberWithInt:16],
          @"Mono Mode":[NSNumber numberWithInt:1],
          @"Rounding Mode":[NSNumber numberWithInt:0],
          @"Inter-Keyboard Slide":[NSNumber numberWithInt:1],
          @"Send Current Key":[NSNumber numberWithInt:1],
          @"Send Current Keyboard":[NSNumber numberWithInt:1],
          @"Send X":[NSNumber numberWithInt:1],
          @"Send Y":[NSNumber numberWithInt:1],
          @"Send Sensors":[NSNumber numberWithInt:1],
          @"Rounding Update Speed":[NSNumber numberWithFloat:0.06],
          @"Rounding Pole":[NSNumber numberWithFloat:0.9],
          @"Rounding Threshold":[NSNumber numberWithFloat:3],
          @"Rounding Cycles":[NSNumber numberWithInt:5]
          }];
    NSString *keyboardFilePath = [documentsDirectory stringByAppendingPathComponent:@"Preset 0_keyb"];
    [keyboardParameters writeToFile:keyboardFilePath atomically:YES];
    
    NSMutableDictionary *dspParameters = [NSMutableDictionary dictionary];
    NSString *dspFilePath = [documentsDirectory stringByAppendingPathComponent:@"Preset 0_dsp"];
    [dspParameters writeToFile:dspFilePath atomically:YES];
}

// process menu events
- (IBAction)newEventOnMenu:(Button*)sender{
    if(sender->on){
        // when adding a new preset, the current preset files are copied
        if(sender.tag == 0){
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
        // when deleting a preset, the related files are deleted
        else if(sender.tag == 1 && [presetsList count]>1){
            [popupWindow setHidden:false];
        }
        else if(sender.tag == 2){
            if(sender->polarity){
                [sender setBackgroundColor:selectedButtonColor];
                [audioSettingsView setHidden:false];
                [presetsTitleLabel setHidden:true];
                [presetsView setHidden:true];
            }
            else{
                [sender setBackgroundColor:menuButtonsBackgroundColor];
                [audioSettingsView setHidden:true];
                [presetsTitleLabel setHidden:false];
                [presetsView setHidden:false];
                actionType = 1;
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
        }
        else if(sender.tag == 3){
            actionType = 0;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}

// process preset selector events
- (IBAction)newEventOnPresetSelect:(Button*)sender{
    if(sender->on){
        if(sender.tag != currentPreset){
            if(currentPreset%2 == 1){
                [[selectButtons objectAtIndex:currentPreset] setOffColor:evenSelectButtonsColor];
                [[selectButtons objectAtIndex:currentPreset] setOnColor:evenSelectButtonsColor];
                [[presetsNameFields objectAtIndex:currentPreset] setBackgroundColor:evenPresetsNameFieldsBackgroundColor];
            }
            else{
                [[selectButtons objectAtIndex:currentPreset] setOffColor:oddSelectButtonsColor];
                [[selectButtons objectAtIndex:currentPreset] setOnColor:oddSelectButtonsColor];
                [[presetsNameFields objectAtIndex:currentPreset] setBackgroundColor:oddPresetsNameFieldsBackgroundColor];
            }
            
            [[selectButtons objectAtIndex:sender.tag] setOffColor:selectedButtonColor];
            [[selectButtons objectAtIndex:sender.tag] setOnColor:selectedButtonColor];
            [[presetsNameFields objectAtIndex:sender.tag] setBackgroundColor:selectedPresetsNameFieldsBackgroundColor];
            currentPreset = sender.tag;
        }
    }
}

// process preset name changes
- (IBAction)newEventOnPresetName:(UITextField*)sender{
    // when a preset name changes, the name of the corresponding preset files are updated
    [[NSFileManager defaultManager] moveItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:sender.tag] stringByAppendingString:@"_keyb"]] toPath:[documentsDirectory stringByAppendingPathComponent:[sender.text stringByAppendingString:@"_keyb"]] error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:sender.tag] stringByAppendingString:@"_dsp"]] toPath:[documentsDirectory stringByAppendingPathComponent:[sender.text stringByAppendingString:@"_dsp"]] error:nil];
    
    [self updatePresetsList];
    [self clearPresetsTable];
    [self buildPresetsTable];
}

// process audio setting change
- (IBAction)newEventOnAudioSettings:(UITextField*)sender{
    NSString *currentSetting;
    if(sender.tag == 0){
        currentSetting = @"SR";
    }
    else if(sender.tag == 1){
        currentSetting = @"bufferLength";
    }
    if([sender.text intValue] != 0){
        [audioSettings setValue:[NSNumber numberWithInt:[sender.text intValue]] forKey:currentSetting];
        [audioSettings writeToFile:audioSettingsFile atomically:YES];
    }
    else{
        sender.text = [NSString stringWithFormat:@"%d",[audioSettings[currentSetting] intValue]];
    }
}

// process popup window events
- (IBAction)newEventOnPopupWindow:(Button*)sender{
    if(sender->on){
        if(sender.tag == 1){
            [[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:currentPreset] stringByAppendingString:@"_keyb"]] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:[[presetsList objectAtIndex:currentPreset] stringByAppendingString:@"_dsp"]] error:nil];
            currentPreset = 0;
            
            [self updatePresetsList];
            [self clearPresetsTable];
            [self buildPresetsTable];
        }
        [popupWindow setHidden:true];
    }
}

@end
