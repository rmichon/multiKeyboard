//
//  ConfigDisplay.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/16/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "ConfigDisplay.h"

@implementation ConfigDisplay{
    NSMutableDictionary *parameters; // TODO: might not be needed
    DspFaust *dspFaust; // TODO: migh not be needed too
    NSMutableArray *keyboardKeyFields;
    NSMutableArray *keyboardKeyValueFields;
    UIScrollView *keybParamsColumn;
    CGFloat borderSize, frameWidth, frameHeight,
    columnWidth, columnLabelHeight, columnHeight,
    keyFieldWidth, addButtonWidth, keyValueFieldWidth;
}

- (id)initWithFrame:(CGRect)frame withParams:(NSMutableDictionary*)params withDspFaust:(DspFaust*)dsp{
    self = [super initWithFrame:frame];
    if(self){
        [self setBackgroundColor:[UIColor blackColor]];
        
        parameters = params;
        dspFaust = dsp;
        
        keyboardKeyFields = [[NSMutableArray alloc] init];
        keyboardKeyValueFields = [[NSMutableArray alloc] init];
        
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
        [addKeyboardFieldButton addTarget:self action:@selector(newEventOnAddButton:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:addKeyboardFieldButton];
        
        keybParamsColumn = [[UIScrollView alloc] initWithFrame:CGRectMake(borderSize, borderSize+columnLabelHeight, columnWidth, columnHeight)];
        [self addSubview:keybParamsColumn];
        
        NSArray *keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        for(int i=0; i<[keys count]; i++){
            // delete button
            Button *deleteFieldButton = [[Button alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, addButtonWidth, columnLabelHeight)];
            [deleteFieldButton setOffColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
            deleteFieldButton->ID = i;
            [deleteFieldButton addTarget:self action:@selector(newEventOnDeleteButton:) forControlEvents:UIControlEventValueChanged];
            [keybParamsColumn addSubview:deleteFieldButton];
            
            // key name
            [keyboardKeyFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(addButtonWidth, columnLabelHeight*i, keyFieldWidth, columnLabelHeight)] atIndex:i];
            [[keyboardKeyFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.9-(0.1*(i%2)) green:0.9-(0.1*(i%2)) blue:0.9-(0.1*(i%2)) alpha:1]];
            [[keyboardKeyFields objectAtIndex:i] setText:[keys objectAtIndex:i]];
            [keybParamsColumn addSubview:[keyboardKeyFields objectAtIndex:i]];
            
            // key value
            [keyboardKeyValueFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(keyFieldWidth+addButtonWidth, columnLabelHeight*i, keyValueFieldWidth, columnLabelHeight)] atIndex:i];
            [[keyboardKeyValueFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
            [[keyboardKeyValueFields objectAtIndex:i] setText:[NSString stringWithFormat:@"%@",[parameters objectForKey:[keys objectAtIndex:i]]]];
            [keybParamsColumn addSubview:[keyboardKeyValueFields objectAtIndex:i]];
        }
        
        keybParamsColumn.contentSize = CGSizeMake(columnWidth,columnLabelHeight*[keys count]);
        
        // DSP PARAMETERS
        UILabel *dspParamsLabel = [[UILabel alloc] initWithFrame:CGRectMake(columnWidth+borderSize, borderSize, columnWidth, columnLabelHeight)];
        [dspParamsLabel setText:@"DSP Parameters"];
        [dspParamsLabel setTextAlignment:NSTextAlignmentCenter];
        [dspParamsLabel setFont:[UIFont systemFontOfSize:22]];
        [dspParamsLabel setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
        [self addSubview:dspParamsLabel];
    }
    return self;
}

- (void)saveState{
    for(int i=0; i<[keyboardKeyValueFields count]; i++){
        // TODO: type checker very dirty: works but float processes all cases...
        UITextField *currentKeyField = [keyboardKeyFields objectAtIndex:i];
        UITextField *currentKeyValueField = [keyboardKeyValueFields objectAtIndex:i];
        if([[NSScanner scannerWithString:currentKeyValueField.text] scanInt:NULL]){
            NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            if([currentKeyValueField.text rangeOfCharacterFromSet:notDigits].location == NSNotFound){
                parameters[currentKeyField.text] = [NSNumber numberWithInt:[currentKeyValueField.text intValue]];
            }
            else{
                parameters[currentKeyField.text] = [NSNumber numberWithFloat:[currentKeyValueField.text floatValue]];
            }
        }
    }
}

- (IBAction)newEventOnAddButton:(Button*)sender{
    if(sender->on){
        NSUInteger i = [keyboardKeyFields count];
        
        // key name
        [keyboardKeyFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, keyFieldWidth, columnLabelHeight)] atIndex:i];
        [[keyboardKeyFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.9-(0.1*(i%2)) green:0.9-(0.1*(i%2)) blue:0.9-(0.1*(i%2)) alpha:1]];
        [keybParamsColumn addSubview:[keyboardKeyFields objectAtIndex:i]];
        
        // key value
        [keyboardKeyValueFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(keyFieldWidth, columnLabelHeight*i, columnWidth-keyFieldWidth, columnLabelHeight)] atIndex:i];
        [[keyboardKeyValueFields objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:0.7-(0.1*(i%2)) green:0.7-(0.1*(i%2)) blue:0.7-(0.1*(i%2)) alpha:1]];
        [keybParamsColumn addSubview:[keyboardKeyValueFields objectAtIndex:i]];
    
        keybParamsColumn.contentSize = CGSizeMake(columnWidth,columnLabelHeight*(i+1));
    }
}

- (IBAction)newEventOnDeleteButton:(Button*)sender{
    if(sender->on){
        if(sender->polarity){
            [sender setOffColor:[UIColor colorWithRed:1 green:0.4 blue:0.4 alpha:1]];
            [[keyboardKeyFields objectAtIndex:sender->ID] setBackgroundColor:[UIColor colorWithRed:0.9 green:0.5 blue:0.5 alpha:1]];
            [[keyboardKeyValueFields objectAtIndex:sender->ID] setBackgroundColor:[UIColor colorWithRed:0.9 green:0.5 blue:0.5 alpha:1]];
        }
        else{
            [[keyboardKeyFields objectAtIndex:sender->ID] setBackgroundColor:[UIColor colorWithRed:0.9-(0.1*(sender->ID%2)) green:0.9-(0.1*(sender->ID%2)) blue:0.9-(0.1*(sender->ID%2)) alpha:1]];
            [[keyboardKeyValueFields objectAtIndex:sender->ID] setBackgroundColor:[UIColor colorWithRed:0.7-(0.1*(sender->ID%2)) green:0.7-(0.1*(sender->ID%2)) blue:0.7-(0.1*(sender->ID%2)) alpha:1]];
            [sender setOffColor:[UIColor colorWithRed:0.7-(0.1*(sender->ID%2)) green:0.7-(0.1*(sender->ID%2)) blue:0.7-(0.1*(sender->ID%2)) alpha:1]];
        }
    }
}

@end
