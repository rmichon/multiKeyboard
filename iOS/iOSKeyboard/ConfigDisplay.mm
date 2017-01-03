//
//  ConfigDisplay.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/16/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "ConfigDisplay.h"

@implementation ConfigDisplay{
    NSMutableDictionary *keyboardParameters; // TODO: might not be needed
    NSMutableDictionary *dspParameters; // TODO: might not be needed
    DspFaust *dspFaust; // TODO: migh not be needed too
    NSArray *keyboardKeys;
    NSArray *dspKeys;
    NSMutableArray *keyboardDeleteButtons, *keyboardKeyFields, *keyboardKeyValueFields;
    NSMutableArray *dspDeleteButtons, *dspKeyFields, *dspKeyValueFields;
    UIScrollView *keybParamsColumn;
    UIScrollView *dspParamsColumn;
    CGFloat borderSize, frameWidth, frameHeight,
    columnWidth, columnLabelHeight, columnHeight,
    keyFieldWidth, addButtonWidth, keyValueFieldWidth;
}

- (id)initWithFrame:(CGRect)frame withKeyboardParams:(NSMutableDictionary*)keyboardParams withDspParamas:(NSMutableDictionary*)dspParams withDspFaust:(DspFaust*)dsp{
    self = [super initWithFrame:frame];
    if(self){
        [self setBackgroundColor:[UIColor blackColor]];
        
        keyboardParameters = keyboardParams;
        dspParameters = dspParams;
        dspFaust = dsp;
        
        keyboardDeleteButtons = [[NSMutableArray alloc] init];
        keyboardKeyFields = [[NSMutableArray alloc] init];
        keyboardKeyValueFields = [[NSMutableArray alloc] init];
        
        dspDeleteButtons = [[NSMutableArray alloc] init];
        dspKeyFields = [[NSMutableArray alloc] init];
        dspKeyValueFields = [[NSMutableArray alloc] init];
        
        borderSize = 1;
        frameWidth = frame.size.width-borderSize*2;
        frameHeight = frame.size.height-borderSize*2;
        columnWidth = frameWidth/2;
        columnLabelHeight = frameHeight*0.08;
        columnHeight = frameHeight-columnLabelHeight;
        addButtonWidth = columnLabelHeight;
        keyFieldWidth = columnWidth*0.8-addButtonWidth;
        keyValueFieldWidth = columnWidth-(keyFieldWidth+addButtonWidth);
        
        // KEYBOARD PARAMETERS
        UILabel *keybParamsLabel = [[UILabel alloc] initWithFrame:CGRectMake(borderSize, borderSize, columnWidth-addButtonWidth, columnLabelHeight)];
        [keybParamsLabel setText:@"Keyboard Parameters"];
        [keybParamsLabel setTextAlignment:NSTextAlignmentCenter];
        [keybParamsLabel setFont:[UIFont systemFontOfSize:22]];
        [keybParamsLabel setBackgroundColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1]];
        [self addSubview:keybParamsLabel];
        
        Button *addKeyboardFieldButton = [[Button alloc] initWithFrame:CGRectMake(borderSize+(columnWidth-addButtonWidth), borderSize, addButtonWidth, columnLabelHeight)];
        [addKeyboardFieldButton addTarget:self action:@selector(newEventOnAddKeyboardFieldButton:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:addKeyboardFieldButton];
        
        keybParamsColumn = [[UIScrollView alloc] initWithFrame:CGRectMake(borderSize, borderSize+columnLabelHeight, columnWidth, columnHeight)];
        [self addSubview:keybParamsColumn];
        
        [self buildKeyboardParamList];
        
        // DSP PARAMETERS
        UILabel *dspParamsLabel = [[UILabel alloc] initWithFrame:CGRectMake(columnWidth+borderSize, borderSize, columnWidth-addButtonWidth, columnLabelHeight)];
        [dspParamsLabel setText:@"DSP Parameters"];
        [dspParamsLabel setTextAlignment:NSTextAlignmentCenter];
        [dspParamsLabel setFont:[UIFont systemFontOfSize:22]];
        [dspParamsLabel setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
        [self addSubview:dspParamsLabel];
        
        Button *addDspFieldButton = [[Button alloc] initWithFrame:CGRectMake(columnWidth+borderSize+(columnWidth-addButtonWidth), borderSize, addButtonWidth, columnLabelHeight)];
        [addDspFieldButton addTarget:self action:@selector(newEventOnAddDspFieldButton:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:addDspFieldButton];
        
        dspParamsColumn = [[UIScrollView alloc] initWithFrame:CGRectMake(columnWidth+borderSize, borderSize+columnLabelHeight, columnWidth, columnHeight)];
        [self addSubview:dspParamsColumn];
        
        [self buildDspParamList];
    }
    return self;
}

- (void)buildKeyboardParamList{
    keyboardKeys = [[keyboardParameters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for(int i=0; i<[keyboardKeys count]; i++){
        // delete button
        if(![[keyboardKeys objectAtIndex:i] isEqual: @"nKeyb"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"maxFingers"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"maxKeybPoly"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"monoMode"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"quantizationMode"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"interKeybSlideAllowed"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"roundingUpdateSpeed"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"roundingSmoothPole"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"roundingThreshold"] &&
           ![[keyboardKeys objectAtIndex:i] isEqual: @"roundingDeactCycles"]){
            [keyboardDeleteButtons insertObject:[[Button alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, addButtonWidth, columnLabelHeight)] atIndex:i];
            [[keyboardDeleteButtons objectAtIndex:i] setOffColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
            [[keyboardDeleteButtons objectAtIndex:i] setID:i];
            [[keyboardDeleteButtons objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardDeleteButton:) forControlEvents:UIControlEventValueChanged];
            [keybParamsColumn addSubview:[keyboardDeleteButtons objectAtIndex:i]];
        }
        else{
            [keyboardDeleteButtons insertObject:[[UIView alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, addButtonWidth, columnLabelHeight)] atIndex:i];
            [[keyboardDeleteButtons objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1]];
            [keybParamsColumn addSubview:[keyboardDeleteButtons objectAtIndex:i]];
        }
        
        // key name
        [keyboardKeyFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(addButtonWidth, columnLabelHeight*i, keyFieldWidth, columnLabelHeight)] atIndex:i];
        [[keyboardKeyFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.9-(0.1*(i%2)) green:0.9-(0.1*(i%2)) blue:0.9-(0.1*(i%2)) alpha:1]];
        [[keyboardKeyFields objectAtIndex:i] setText:[keyboardKeys objectAtIndex:i]];
        [[keyboardKeyFields objectAtIndex:i] setTag:i];
        [[keyboardKeyFields objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardParamName:) forControlEvents:UIControlEventEditingDidEnd];
        [keybParamsColumn addSubview:[keyboardKeyFields objectAtIndex:i]];
        
        // key value
        [keyboardKeyValueFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(keyFieldWidth+addButtonWidth, columnLabelHeight*i, keyValueFieldWidth, columnLabelHeight)] atIndex:i];
        [[keyboardKeyValueFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
        [[keyboardKeyValueFields objectAtIndex:i] setText:[NSString stringWithFormat:@"%@",[keyboardParameters objectForKey:[keyboardKeys objectAtIndex:i]]]];
        [[keyboardKeyValueFields objectAtIndex:i] setTag:i];
        [[keyboardKeyValueFields objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardValue:) forControlEvents:UIControlEventEditingDidEnd];
        [keybParamsColumn addSubview:[keyboardKeyValueFields objectAtIndex:i]];
    }
    
    keybParamsColumn.contentSize = CGSizeMake(columnWidth,columnLabelHeight*[keyboardKeys count]+(columnHeight-columnLabelHeight));
}

- (void)buildDspParamList{
    dspKeys = [[dspParameters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for(int i=0; i<[dspKeys count]; i++){
        [dspDeleteButtons insertObject:[[Button alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, addButtonWidth, columnLabelHeight)] atIndex:i];
        [[dspDeleteButtons objectAtIndex:i] setOffColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
        [[dspDeleteButtons objectAtIndex:i] setID:i];
        [[dspDeleteButtons objectAtIndex:i] addTarget:self action:@selector(newEventOnDspDeleteButton:) forControlEvents:UIControlEventValueChanged];
        [dspParamsColumn addSubview:[dspDeleteButtons objectAtIndex:i]];
        
        // key name
        [dspKeyFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(addButtonWidth, columnLabelHeight*i, keyFieldWidth, columnLabelHeight)] atIndex:i];
        [[dspKeyFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.9-(0.1*(i%2)) green:0.9-(0.1*(i%2)) blue:0.9-(0.1*(i%2)) alpha:1]];
        [[dspKeyFields objectAtIndex:i] setText:[dspKeys objectAtIndex:i]];
        [[dspKeyFields objectAtIndex:i] setTag:i];
        [[dspKeyFields objectAtIndex:i] addTarget:self action:@selector(newEventOnDspParamName:) forControlEvents:UIControlEventEditingDidEnd];
        [dspParamsColumn addSubview:[dspKeyFields objectAtIndex:i]];
        
        // key value
        [dspKeyValueFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(keyFieldWidth+addButtonWidth, columnLabelHeight*i, keyValueFieldWidth, columnLabelHeight)] atIndex:i];
        [[dspKeyValueFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
        [[dspKeyValueFields objectAtIndex:i] setText:[NSString stringWithFormat:@"%@",[dspParameters objectForKey:[dspKeys objectAtIndex:i]]]];
        [[dspKeyValueFields objectAtIndex:i] setTag:i];
        [[dspKeyValueFields objectAtIndex:i] addTarget:self action:@selector(newEventOnDspValue:) forControlEvents:UIControlEventEditingDidEnd];
        [dspParamsColumn addSubview:[dspKeyValueFields objectAtIndex:i]];
    }
    
    dspParamsColumn.contentSize = CGSizeMake(columnWidth,columnLabelHeight*[dspKeys count]+(columnHeight-columnLabelHeight));
}

- (void)clearKeyboardParamList{
    int nKeyFields = (int)[keyboardKeyFields count];
    for(int i=nKeyFields-1; i>=0; i--){
        [[keyboardDeleteButtons objectAtIndex:i] removeFromSuperview];
        [keyboardDeleteButtons removeObjectAtIndex:i];
        [[keyboardKeyFields objectAtIndex:i] removeFromSuperview];
        [keyboardKeyFields removeObjectAtIndex:i];
        [[keyboardKeyValueFields objectAtIndex:i] removeFromSuperview];
        [keyboardKeyValueFields removeObjectAtIndex:i];
        
    }
}

- (void)clearDspParamList{
    int nKeyFields = (int)[dspKeyFields count];
    for(int i=nKeyFields-1; i>=0; i--){
        [[dspDeleteButtons objectAtIndex:i] removeFromSuperview];
        [dspDeleteButtons removeObjectAtIndex:i];
        [[dspKeyFields objectAtIndex:i] removeFromSuperview];
        [dspKeyFields removeObjectAtIndex:i];
        [[dspKeyValueFields objectAtIndex:i] removeFromSuperview];
        [dspKeyValueFields removeObjectAtIndex:i];
        
    }
}

- (void)saveKeyboardParamValue:(NSString*)key withValue:(NSString*)value{
    if([key isEqual: @"nKeyb"] ||
       [key isEqual: @"maxFingers"] ||
       [key isEqual: @"maxKeybPoly"] ||
       [key isEqual: @"monoMode"] ||
       [key isEqual: @"quantizationMode"] ||
       [key isEqual: @"interKeybSlideAllowed"] ||
       [key isEqual: @"roundingDeactCycles"] ||
       [key containsString:@"keyb"]){
        keyboardParameters[key] = [NSNumber numberWithInteger:[value integerValue]];
    }
    else{
        keyboardParameters[key] = [NSNumber numberWithFloat:[value floatValue]];
    }
}

- (IBAction)newEventOnAddKeyboardFieldButton:(Button*)sender{
    if(sender->on){
        keyboardParameters[@"**NewParameter**"] = [NSNumber numberWithInteger:0];
        [self clearKeyboardParamList];
        [self buildKeyboardParamList];
    }
}

- (IBAction)newEventOnAddDspFieldButton:(Button*)sender{
    if(sender->on){
        dspParameters[@"/**NewParameter**"] = [NSNumber numberWithFloat:0.0];
        [self clearDspParamList];
        [self buildDspParamList];
    }
}

- (IBAction)newEventOnKeyboardParamName:(UITextField*)sender{
    UITextField *currentValueField = [keyboardKeyValueFields objectAtIndex:sender.tag];
    [self saveKeyboardParamValue:sender.text withValue:currentValueField.text];
    [keyboardParameters removeObjectForKey:[keyboardKeys objectAtIndex:sender.tag]];
    [self clearKeyboardParamList];
    [self buildKeyboardParamList];
}

- (IBAction)newEventOnKeyboardValue:(UITextField*)sender{
    UITextField *currentParamNameField = [keyboardKeyFields objectAtIndex:sender.tag];
    [self saveKeyboardParamValue:currentParamNameField.text withValue:sender.text];
    [self clearKeyboardParamList];
    [self buildKeyboardParamList];
}

- (IBAction)newEventOnKeyboardDeleteButton:(Button*)sender{
    if(sender->on){
        [keyboardParameters removeObjectForKey:[keyboardKeys objectAtIndex:sender->ID]];
        [self clearKeyboardParamList];
        [self buildKeyboardParamList];
    }
}

- (IBAction)newEventOnDspParamName:(UITextField*)sender{
    UITextField *currentValueField = [dspKeyValueFields objectAtIndex:sender.tag];
    dspParameters[sender.text] = [NSNumber numberWithFloat:[currentValueField.text floatValue]];
    [dspParameters removeObjectForKey:[dspKeys objectAtIndex:sender.tag]];
    [self clearDspParamList];
    [self buildDspParamList];
}

- (IBAction)newEventOnDspValue:(UITextField*)sender{
    UITextField *currentParamNameField = [dspKeyFields objectAtIndex:sender.tag];
    dspParameters[currentParamNameField.text] = [NSNumber numberWithFloat:[sender.text floatValue]];
    [self clearDspParamList];
    [self buildDspParamList];
}

- (IBAction)newEventOnDspDeleteButton:(Button*)sender{
    if(sender->on){
        [dspParameters removeObjectForKey:[dspKeys objectAtIndex:sender->ID]];
        [self clearDspParamList];
        [self buildDspParamList];
    }
}

@end
