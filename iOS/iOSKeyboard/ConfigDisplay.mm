//
//  ConfigDisplay.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/16/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "ConfigDisplay.h"

@implementation ConfigDisplay{
    NSMutableDictionary *keyboardParameters; // pointer to the keyboard parameters in MultiKeyboard
    NSMutableDictionary *dspParameters; // pointer to dsp parameters in MultiKeyboard
    DspFaust *dspFaust; // pointer to faust dsp in ViewController
    NSArray *keyboardKeys; // list of saved keyboard keys
    NSArray *dspKeys; // list of saved dsp keys
    
    // pointers to the different UI elements
    NSMutableArray *keyboardDeleteButtons, *keyboardKeyFields, *keyboardKeyValueFields;
    NSMutableArray *dspDeleteButtons, *dspKeyFields, *dspKeyValueFields;
    
    // scrollable parameters columns
    UIScrollView *keybParamsColumn;
    UIScrollView *dspParamsColumn;
    
    // documentation views
    UITextView *keyboardDoc;
    UITextView *dspGeneratedDoc;
    UIWebView *dspHtmlDoc;
    
    // other views
    UIView *popupWindow;
    
    // UI elements sizes
    CGFloat borderSize, frameWidth, frameHeight,
    columnWidth, columnLabelHeight, columnHeight,
    keyFieldWidth, addButtonWidth, keyValueFieldWidth,
    popupWindowWidth, popupWindowHeight;
    
    // UI elements colors
    UIColor *columnTitleBackgroundColor, *titleButtonsColor, *textWhiteColor,
    *oddFieldsColor0, *oddFieldsColor1, *evenFieldsColor0, *evenFieldsColor1,
    *lockedButtonColor, *popupWindowColor;
    
    // UI font sizes
    CGFloat titlesFontSize, titlesButtonsFontSize, defaultTextFontSize;
    
    // other stuff
    NSInteger paramToDelete, deleteActionType;
}

- (id)initWithFrame:(CGRect)frame withKeyboardParams:(NSMutableDictionary*)keyboardParams withDspParamas:(NSMutableDictionary*)dspParams withDspFaust:(DspFaust*)dsp{
    self = [super initWithFrame:frame];
    if(self){
        keyboardParameters = keyboardParams;
        dspParameters = dspParams;
        dspFaust = dsp;
        
        keyboardDeleteButtons = [[NSMutableArray alloc] init];
        keyboardKeyFields = [[NSMutableArray alloc] init];
        keyboardKeyValueFields = [[NSMutableArray alloc] init];
        
        dspDeleteButtons = [[NSMutableArray alloc] init];
        dspKeyFields = [[NSMutableArray alloc] init];
        dspKeyValueFields = [[NSMutableArray alloc] init];
        
        // configuring UI elements colors
        columnTitleBackgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.7];
        titleButtonsColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
        textWhiteColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        oddFieldsColor0 = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.7];
        evenFieldsColor0 = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.7];
        oddFieldsColor1 = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.7];
        evenFieldsColor1 = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.7];
        lockedButtonColor = [UIColor colorWithRed:1 green:0.3 blue:0.3 alpha:0.7];
        popupWindowColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9];
        
        // configuring UI elements font sizes
        titlesFontSize = 24;
        titlesButtonsFontSize = 26;
        defaultTextFontSize = 18;
        
        // scaling fonts in function of screen size, dirty dirty...
        CGFloat referenceWidth = 1024;
        titlesFontSize = titlesFontSize*frame.size.width/referenceWidth;
        titlesButtonsFontSize = titlesButtonsFontSize*frame.size.width/referenceWidth;
        defaultTextFontSize = defaultTextFontSize*frame.size.width/referenceWidth;
        
        // setting elements sizes
        borderSize = 2;
        frameWidth = frame.size.width;
        frameHeight = frame.size.height;
        columnWidth = frame.size.width/2;
        columnLabelHeight = frameHeight*0.08;
        columnHeight = frameHeight-columnLabelHeight;
        addButtonWidth = columnLabelHeight;
        keyFieldWidth = (columnWidth-borderSize*2)*0.8-addButtonWidth;
        keyValueFieldWidth = (columnWidth-borderSize*2)-(keyFieldWidth+addButtonWidth);
        popupWindowWidth = frameWidth/3;
        popupWindowHeight = frameHeight/4;
        
        // Setting background picture
        UIGraphicsBeginImageContextWithOptions(self.frame.size,NO,2.0f);
        [[UIImage imageNamed:@"configDisplayBackground.jpg"] drawInRect:self.bounds];
        UIImage *picOn = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.backgroundColor = [UIColor colorWithPatternImage:picOn];
        
        // building this shit!
        
        [self buildKeyboardParamsListHeader];
        
        // building keyboard params list scroll view
        keybParamsColumn = [[UIScrollView alloc] initWithFrame:CGRectMake(borderSize, borderSize+columnLabelHeight, columnWidth-borderSize*2, columnHeight-borderSize*2)];
        [self addSubview:keybParamsColumn];
        
        [self buildKeyboardParamList];
        [self buildDspParamsListHeader];
        
        // building dsp params list scroll view
        dspParamsColumn = [[UIScrollView alloc] initWithFrame:CGRectMake(columnWidth+borderSize, borderSize+columnLabelHeight, columnWidth, columnHeight)];
        [self addSubview:dspParamsColumn];
        
        [self buildDspParamList];
        [self buildKeyboardDoc];
        [self buildDspDoc];
        [self buildPopupWindow];
    }
    return self;
}

// builds the header of the keyboard parameters list
- (void)buildKeyboardParamsListHeader{
    // the title of the column
    UILabel *keybParamsLabel = [[UILabel alloc] initWithFrame:CGRectMake(borderSize, borderSize, columnWidth-borderSize*2, columnLabelHeight)];
    [keybParamsLabel setText:@"Keyboard Parameters"];
    [keybParamsLabel setTextAlignment:NSTextAlignmentCenter];
    [keybParamsLabel setFont:[UIFont boldSystemFontOfSize:titlesFontSize]];
    [keybParamsLabel setTextColor:textWhiteColor];
    [keybParamsLabel setBackgroundColor:columnTitleBackgroundColor];
    [self addSubview:keybParamsLabel];
    
    // show the documentation of the Faust dsp object
    Button *showKeyboardParametersButton = [[Button alloc] initWithFrame:CGRectMake(borderSize+(columnWidth-addButtonWidth*2-borderSize), borderSize*2, addButtonWidth-borderSize*2, columnLabelHeight-borderSize*2)];
    [showKeyboardParametersButton setOnColor:titleButtonsColor];
    [showKeyboardParametersButton setOffColor:titleButtonsColor];
    [showKeyboardParametersButton setTextFont:[UIFont boldSystemFontOfSize:titlesButtonsFontSize]];
    [showKeyboardParametersButton setTextColor:textWhiteColor];
    [showKeyboardParametersButton setText:@"H"];
    [showKeyboardParametersButton setTag:0];
    [showKeyboardParametersButton addTarget:self action:@selector(newEventOnShowParamsListButton:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:showKeyboardParametersButton];
    
    // add a new parameter button
    Button *addKeyboardFieldButton = [[Button alloc] initWithFrame:CGRectMake(borderSize+(columnWidth-addButtonWidth-borderSize), borderSize*2, addButtonWidth-borderSize*2, columnLabelHeight-borderSize*2)];
    [addKeyboardFieldButton setOnColor:titleButtonsColor];
    [addKeyboardFieldButton setOffColor:titleButtonsColor];
    [addKeyboardFieldButton setTextFont:[UIFont boldSystemFontOfSize:titlesButtonsFontSize]];
    [addKeyboardFieldButton setTextColor:textWhiteColor];
    [addKeyboardFieldButton setText:@"+"];
    [addKeyboardFieldButton addTarget:self action:@selector(newEventOnAddKeyboardFieldButton:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:addKeyboardFieldButton];
}

// builds the header of the DSP parameters list
- (void)buildDspParamsListHeader{
    // the title of the column
    UILabel *dspParamsLabel = [[UILabel alloc] initWithFrame:CGRectMake(columnWidth+borderSize, borderSize, columnWidth-borderSize*2, columnLabelHeight)];
    [dspParamsLabel setText:@"DSP Parameters"];
    [dspParamsLabel setTextAlignment:NSTextAlignmentCenter];
    [dspParamsLabel setFont:[UIFont boldSystemFontOfSize:titlesFontSize]];
    [dspParamsLabel setTextColor:textWhiteColor];
    [dspParamsLabel setBackgroundColor:columnTitleBackgroundColor];
    [self addSubview:dspParamsLabel];
    
    // show the documentation of the Faust dsp object
    Button *showDspParametersButton = [[Button alloc] initWithFrame:CGRectMake(columnWidth+borderSize+(columnWidth-addButtonWidth*2-borderSize), borderSize*2, addButtonWidth-borderSize*2, columnLabelHeight-borderSize*2)];
    [showDspParametersButton setOnColor:titleButtonsColor];
    [showDspParametersButton setOffColor:titleButtonsColor];
    [showDspParametersButton setTextFont:[UIFont boldSystemFontOfSize:titlesButtonsFontSize]];
    [showDspParametersButton setTextColor:textWhiteColor];
    [showDspParametersButton setText:@"H"];
    [showDspParametersButton setTag:1];
    [showDspParametersButton addTarget:self action:@selector(newEventOnShowParamsListButton:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:showDspParametersButton];
    
    // add a new parameter button
    Button *addDspFieldButton = [[Button alloc] initWithFrame:CGRectMake(columnWidth+borderSize+(columnWidth-addButtonWidth-borderSize), borderSize*2, addButtonWidth-borderSize*2, columnLabelHeight-borderSize*2)];
    [addDspFieldButton setOnColor:titleButtonsColor];
    [addDspFieldButton setOffColor:titleButtonsColor];
    [addDspFieldButton setTextFont:[UIFont boldSystemFontOfSize:titlesButtonsFontSize]];
    [addDspFieldButton setTextColor:textWhiteColor];
    [addDspFieldButton setText:@"+"];
    [addDspFieldButton addTarget:self action:@selector(newEventOnAddDspFieldButton:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:addDspFieldButton];
}

// builds the keyboard parameters list
- (void)buildKeyboardParamList{
    // retrieve the existing parameter keys and order alphabetically
    keyboardKeys = [[keyboardParameters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // build the list
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
            // deletable parameters
            [keyboardDeleteButtons insertObject:[[Button alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, addButtonWidth, columnLabelHeight)] atIndex:i];
            if(i%2 == 0){
                [[keyboardDeleteButtons objectAtIndex:i] setOffColor:evenFieldsColor0];
                [[keyboardDeleteButtons objectAtIndex:i] setOnColor:evenFieldsColor0];
            }
            else{
                [[keyboardDeleteButtons objectAtIndex:i] setOffColor:oddFieldsColor0];
                [[keyboardDeleteButtons objectAtIndex:i] setOnColor:oddFieldsColor0];
            }
            [[keyboardDeleteButtons objectAtIndex:i] setTextFont:[UIFont boldSystemFontOfSize:titlesButtonsFontSize]];
            [[keyboardDeleteButtons objectAtIndex:i] setTextColor:textWhiteColor];
            [[keyboardDeleteButtons objectAtIndex:i] setText:@"-"];
            [[keyboardDeleteButtons objectAtIndex:i] setTag:i];
            [[keyboardDeleteButtons objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardDeleteButton:) forControlEvents:UIControlEventValueChanged];
            [keybParamsColumn addSubview:[keyboardDeleteButtons objectAtIndex:i]];
        }
        else{
            // requiered parameters: no delete button, just UIView
            [keyboardDeleteButtons insertObject:[[UIView alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, addButtonWidth, columnLabelHeight)] atIndex:i];
            [[keyboardDeleteButtons objectAtIndex:i] setBackgroundColor:lockedButtonColor];
            [keybParamsColumn addSubview:[keyboardDeleteButtons objectAtIndex:i]];
        }
        
        // key name
        [keyboardKeyFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(addButtonWidth, columnLabelHeight*i, keyFieldWidth, columnLabelHeight)] atIndex:i];
        if(i%2 == 0){
            [[keyboardKeyFields objectAtIndex:i] setBackgroundColor:evenFieldsColor1];
        }
        else{
            [[keyboardKeyFields objectAtIndex:i] setBackgroundColor:oddFieldsColor1];
        }
        [[keyboardKeyFields objectAtIndex:i] setFont:[UIFont systemFontOfSize:defaultTextFontSize]];
        [[keyboardKeyFields objectAtIndex:i] setText:[keyboardKeys objectAtIndex:i]];
        [[keyboardKeyFields objectAtIndex:i] setTag:i];
        [[keyboardKeyFields objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardParamName:) forControlEvents:UIControlEventEditingDidEnd];
        [[keyboardKeyFields objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardParamEditingBegin:) forControlEvents:UIControlEventEditingDidBegin];
        [keybParamsColumn addSubview:[keyboardKeyFields objectAtIndex:i]];
        
        // key value
        [keyboardKeyValueFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(keyFieldWidth+addButtonWidth, columnLabelHeight*i, keyValueFieldWidth, columnLabelHeight)] atIndex:i];
        if(i%2 == 0){
            [[keyboardKeyValueFields objectAtIndex:i] setBackgroundColor:evenFieldsColor0];
        }
        else{
            [[keyboardKeyValueFields objectAtIndex:i] setBackgroundColor:oddFieldsColor0];
        }
        [[keyboardKeyValueFields objectAtIndex:i] setFont:[UIFont systemFontOfSize:defaultTextFontSize]];
        [[keyboardKeyValueFields objectAtIndex:i] setText:[NSString stringWithFormat:@"%@",[keyboardParameters objectForKey:[keyboardKeys objectAtIndex:i]]]];
        [[keyboardKeyValueFields objectAtIndex:i] setTag:i];
        [[keyboardKeyValueFields objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardValue:) forControlEvents:UIControlEventEditingDidEnd];
        [[keyboardKeyValueFields objectAtIndex:i] addTarget:self action:@selector(newEventOnKeyboardParamEditingBegin:) forControlEvents:UIControlEventEditingDidBegin];
        [keybParamsColumn addSubview:[keyboardKeyValueFields objectAtIndex:i]];
    }
    
    // updating view size in function of the number of keys
    keybParamsColumn.contentSize = CGSizeMake(columnWidth-borderSize*2,columnLabelHeight*[keyboardKeys count]+(columnHeight-columnLabelHeight));
}

// builds the dsp parameters list
- (void)buildDspParamList{
    // retrieving the dsp keys and ordering them alphabetically
    dspKeys = [[dspParameters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // building the list
    for(int i=0; i<[dspKeys count]; i++){
        // delete buttons
        [dspDeleteButtons insertObject:[[Button alloc] initWithFrame:CGRectMake(0, columnLabelHeight*i, addButtonWidth, columnLabelHeight)] atIndex:i];
        if(i%2 == 0){
            [[dspDeleteButtons objectAtIndex:i] setOffColor:evenFieldsColor0];
            [[dspDeleteButtons objectAtIndex:i] setOnColor:evenFieldsColor0];
        }
        else{
            [[dspDeleteButtons objectAtIndex:i] setOffColor:oddFieldsColor0];
            [[dspDeleteButtons objectAtIndex:i] setOnColor:oddFieldsColor0];
        }
        [[dspDeleteButtons objectAtIndex:i] setTextFont:[UIFont boldSystemFontOfSize:titlesButtonsFontSize]];
        [[dspDeleteButtons objectAtIndex:i] setTextColor:textWhiteColor];
        [[dspDeleteButtons objectAtIndex:i] setText:@"-"];
        [[dspDeleteButtons objectAtIndex:i] setTag:i];
        [[dspDeleteButtons objectAtIndex:i] addTarget:self action:@selector(newEventOnDspDeleteButton:) forControlEvents:UIControlEventValueChanged];
        [dspParamsColumn addSubview:[dspDeleteButtons objectAtIndex:i]];
        
        // key name
        [dspKeyFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(addButtonWidth, columnLabelHeight*i, keyFieldWidth, columnLabelHeight)] atIndex:i];
        if(i%2 == 0){
            [[dspKeyFields objectAtIndex:i] setBackgroundColor:evenFieldsColor1];
        }
        else{
            [[dspKeyFields objectAtIndex:i] setBackgroundColor:oddFieldsColor1];
        }
        [[dspKeyFields objectAtIndex:i] setFont:[UIFont systemFontOfSize:defaultTextFontSize]];
        [[dspKeyFields objectAtIndex:i] setText:[dspKeys objectAtIndex:i]];
        [[dspKeyFields objectAtIndex:i] setTag:i];
        [[dspKeyFields objectAtIndex:i] addTarget:self action:@selector(newEventOnDspParamName:) forControlEvents:UIControlEventEditingDidEnd];
        [[dspKeyFields objectAtIndex:i] addTarget:self action:@selector(newEventOnDspParamEditingBegin:) forControlEvents:UIControlEventEditingDidBegin];
        [dspParamsColumn addSubview:[dspKeyFields objectAtIndex:i]];
        
        // key value
        [dspKeyValueFields insertObject:[[UITextField alloc] initWithFrame:CGRectMake(keyFieldWidth+addButtonWidth, columnLabelHeight*i, keyValueFieldWidth, columnLabelHeight)] atIndex:i];
        if(i%2 == 0){
            [[dspKeyValueFields objectAtIndex:i] setBackgroundColor:evenFieldsColor0];
        }
        else{
            [[dspKeyValueFields objectAtIndex:i] setBackgroundColor:oddFieldsColor0];
        }
        [[dspKeyValueFields objectAtIndex:i] setFont:[UIFont systemFontOfSize:defaultTextFontSize]];
        [[dspKeyValueFields objectAtIndex:i] setText:[NSString stringWithFormat:@"%@",[dspParameters objectForKey:[dspKeys objectAtIndex:i]]]];
        [[dspKeyValueFields objectAtIndex:i] setTag:i];
        [[dspKeyValueFields objectAtIndex:i] addTarget:self action:@selector(newEventOnDspValue:) forControlEvents:UIControlEventEditingDidEnd];
        [[dspKeyValueFields objectAtIndex:i] addTarget:self action:@selector(newEventOnDspParamEditingBegin:) forControlEvents:UIControlEventEditingDidBegin];
        [dspParamsColumn addSubview:[dspKeyValueFields objectAtIndex:i]];
    }
    
    // updating size of view in function of the number of keys
    dspParamsColumn.contentSize = CGSizeMake(columnWidth-borderSize*2,columnLabelHeight*[dspKeys count]+(columnHeight-columnLabelHeight));
}

// builds SmartKeyboard documentation
- (void)buildKeyboardDoc{
    keyboardDoc = [[UITextView alloc] initWithFrame:CGRectMake(borderSize, borderSize+columnLabelHeight, frameWidth-borderSize*2, columnHeight)];
    [keyboardDoc setBackgroundColor:evenFieldsColor0];
    [keyboardDoc setText:
     @"SMART KEYBOARD CONFIGURATION KEYS DOCUMENTATION\n\n"
     ];
    [keyboardDoc setFont:[UIFont systemFontOfSize:defaultTextFontSize]];
    [keyboardDoc setHidden:true];
    [self addSubview:keyboardDoc];
}

// builds the Faust dsp documentation
- (void)buildDspDoc{
    // retrieves the url of the html doc of the Faust DSP
    NSString *dspDocURL = [[NSBundle mainBundle] pathForResource:@"dspDoc" ofType:@"html"];
    if(dspDocURL != NULL){
        // if the html doc exists, then use it to build the page
        dspHtmlDoc = [[UIWebView alloc] initWithFrame:CGRectMake(borderSize, borderSize+columnLabelHeight, frameWidth-borderSize*2, columnHeight)];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:dspDocURL]];
        [dspHtmlDoc loadRequest:urlRequest];
        [dspHtmlDoc setHidden:true];
        [self addSubview:dspHtmlDoc];
    }
    else{
        // if the html dsp doc doesn't exist, then generate automatic doc based on the UI description of the Faust object and save it
        dspGeneratedDoc = [[UITextView alloc] initWithFrame:CGRectMake(borderSize, borderSize+columnLabelHeight, frameWidth-borderSize*2, columnHeight)];
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *generatedDspDocFile = [documentsDirectory stringByAppendingPathComponent:@"dspDoc"];
        if([[NSFileManager defaultManager] fileExistsAtPath:generatedDspDocFile]){
            // if doc was already generated, then load it
            dspGeneratedDoc.text = [[NSString alloc] initWithContentsOfFile:generatedDspDocFile encoding:NSUTF8StringEncoding error:nil];
        }
        else{
            // if doc was never generated then generate it and save it
            dspGeneratedDoc.text = @"CURRENT FAUST DSP DOCUMENTATION\n\nThis was automatically generated from the UI description of the Faust code associated with this app.\n\n";
            for(int i=0; i<dspFaust->getParamsCount(); i++){
                dspGeneratedDoc.text = [dspGeneratedDoc.text stringByAppendingString:[NSString stringWithFormat:@"%s\n",dspFaust->getParamAddress(i)]];
                dspGeneratedDoc.text = [dspGeneratedDoc.text stringByAppendingString:[NSString stringWithFormat:@"Description: %s\n",dspFaust->getParamTooltip(i)]];
                dspGeneratedDoc.text = [dspGeneratedDoc.text stringByAppendingString:[NSString stringWithFormat:@"Min: %f\n",dspFaust->getParamMin(i)]];
                dspGeneratedDoc.text = [dspGeneratedDoc.text stringByAppendingString:[NSString stringWithFormat:@"Max: %f\n",dspFaust->getParamMax(i)]];
                dspGeneratedDoc.text = [dspGeneratedDoc.text stringByAppendingString:[NSString stringWithFormat:@"Default: %f\n",dspFaust->getParamInit(i)]];
                dspGeneratedDoc.text = [dspGeneratedDoc.text stringByAppendingString:@"----------\n\n"];
            }
            [dspGeneratedDoc.text writeToFile:generatedDspDocFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        [dspGeneratedDoc setBackgroundColor:evenFieldsColor0];
        [dspGeneratedDoc setFont:[UIFont systemFontOfSize:defaultTextFontSize]];
        dspGeneratedDoc.editable = false;
        [dspGeneratedDoc setHidden:true];
        [self addSubview:dspGeneratedDoc];
    }
}

// creates the delete confirmation popup window
- (void)buildPopupWindow{
    popupWindow = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2-popupWindowWidth/2, self.frame.size.height/2-popupWindowHeight/2, popupWindowWidth, popupWindowHeight)];
    [popupWindow setBackgroundColor:popupWindowColor];
    [self addSubview:popupWindow];
    
    UILabel *popupMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, popupWindowWidth, popupWindowHeight-columnLabelHeight-borderSize*2)];
    [popupMessage setTextAlignment:NSTextAlignmentCenter];
    [popupMessage setFont:[UIFont systemFontOfSize:defaultTextFontSize]];
    popupMessage.numberOfLines = 2;
    [popupMessage setText:@"Are you sure you want to delete this parameter?"];
    [popupWindow addSubview:popupMessage];
    
    CGFloat popupWindowButtonsWidth = popupWindowWidth/2-borderSize*2;
    NSArray *popupWindowButtonsLabels = [[NSArray alloc] initWithObjects:@"No", @"Yes", nil];
    for(int i=0; i<2; i++){
        Button *currentButton = [[Button alloc] initWithFrame:CGRectMake(borderSize+(popupWindowButtonsWidth+borderSize)*i, popupWindowHeight-columnLabelHeight-borderSize, popupWindowButtonsWidth, columnLabelHeight)];
        [currentButton setOnColor:titleButtonsColor];
        [currentButton setOffColor:titleButtonsColor];
        [currentButton setTextColor:textWhiteColor];
        [currentButton setTextFont:[UIFont systemFontOfSize:defaultTextFontSize]];
        [currentButton setText:[popupWindowButtonsLabels objectAtIndex:i]];
        [currentButton setTag:i];
        [currentButton addTarget:self action:@selector(newEventOnPopupWindow:) forControlEvents:UIControlEventValueChanged];
        [popupWindow addSubview:currentButton];
    }
    
    [popupWindow setHidden:true];
}

// clears the keyboard parameters list
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

// clears the dsp parameters list
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

// save a keyboard parameter in the dictionary
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

// creates a new keyboard parameter in the dictionary
- (IBAction)newEventOnAddKeyboardFieldButton:(Button*)sender{
    if(sender->on){
        keyboardParameters[@"**NewParameter**"] = [NSNumber numberWithInteger:0];
        [self clearKeyboardParamList];
        [self buildKeyboardParamList];
    }
}

// created a new dsp parameter in the dictionary
- (IBAction)newEventOnAddDspFieldButton:(Button*)sender{
    if(sender->on){
        dspParameters[@"/**NewParameter**"] = [NSNumber numberWithFloat:0.0];
        [self clearDspParamList];
        [self buildDspParamList];
    }
}

// focus on the current param
- (IBAction)newEventOnKeyboardParamEditingBegin:(UITextField*)sender{
    [keybParamsColumn setContentOffset:CGPointMake(0,sender.tag*columnLabelHeight)];
}

// the name of a keyboard parameter changed
- (IBAction)newEventOnKeyboardParamName:(UITextField*)sender{
    UITextField *currentValueField = [keyboardKeyValueFields objectAtIndex:sender.tag];
    [keyboardParameters removeObjectForKey:[keyboardKeys objectAtIndex:sender.tag]];
    [self saveKeyboardParamValue:sender.text withValue:currentValueField.text];
    [self clearKeyboardParamList];
    [self buildKeyboardParamList];
}

// the value of a keyboard parameter changed
- (IBAction)newEventOnKeyboardValue:(UITextField*)sender{
    UITextField *currentParamNameField = [keyboardKeyFields objectAtIndex:sender.tag];
    [self saveKeyboardParamValue:currentParamNameField.text withValue:sender.text];
    [self clearKeyboardParamList];
    [self buildKeyboardParamList];
}

// a keyboard parameter was deleted
- (IBAction)newEventOnKeyboardDeleteButton:(Button*)sender{
    if(sender->on){
        paramToDelete = sender.tag;
        deleteActionType = 0;
        [popupWindow setHidden:false];
    }
}

// focus on the current param
- (IBAction)newEventOnDspParamEditingBegin:(UITextField*)sender{
    [dspParamsColumn setContentOffset:CGPointMake(0,sender.tag*columnLabelHeight)];
}

// the name of a dsp parameter changed
- (IBAction)newEventOnDspParamName:(UITextField*)sender{
    UITextField *currentValueField = [dspKeyValueFields objectAtIndex:sender.tag];
    [dspParameters removeObjectForKey:[dspKeys objectAtIndex:sender.tag]];
    dspParameters[sender.text] = [NSNumber numberWithFloat:[currentValueField.text floatValue]];
    [self clearDspParamList];
    [self buildDspParamList];
}

// the value of a dsp parameter changed
- (IBAction)newEventOnDspValue:(UITextField*)sender{
    UITextField *currentParamNameField = [dspKeyFields objectAtIndex:sender.tag];
    dspParameters[currentParamNameField.text] = [NSNumber numberWithFloat:[sender.text floatValue]];
    [self clearDspParamList];
    [self buildDspParamList];
}

// a dsp parameter was deleted
- (IBAction)newEventOnDspDeleteButton:(Button*)sender{
    if(sender->on){
        paramToDelete = sender.tag;
        deleteActionType = 1;
        [popupWindow setHidden:false];
    }
}

// one of the help view needs to be diplayed
- (IBAction)newEventOnShowParamsListButton:(Button*)sender{
    if(sender->on){
        if(sender->polarity){ // displaying the view
            if(sender.tag == 1){
                if(dspHtmlDoc == NULL){ // dsp doc
                    [dspGeneratedDoc setHidden:false];
                }
                else{
                    [dspHtmlDoc setHidden:false];
                }
            }
            else if(sender.tag == 0){ // keyboard doc
                [keyboardDoc setHidden:false];
            }
            [sender setOffColor:lockedButtonColor];
            [dspParamsColumn setHidden:true];
            [keybParamsColumn setHidden:true];
        }
        else{ // hiding the view
            if(sender.tag == 1){
                if(dspHtmlDoc == NULL){ // dsp doc
                    [dspGeneratedDoc setHidden:true];
                }
                else{
                    [dspHtmlDoc setHidden:true];
                }
            }
            else if(sender.tag == 0){ // keyboard doc
                [keyboardDoc setHidden:true];
            }
            [sender setOffColor:titleButtonsColor];
            [dspParamsColumn setHidden:false];
            [keybParamsColumn setHidden:false];
        }
    }
}

// process popup window events
- (IBAction)newEventOnPopupWindow:(Button*)sender{
    if(sender->on){
        if(sender.tag == 1){
            if(deleteActionType == 0){
                [keyboardParameters removeObjectForKey:[keyboardKeys objectAtIndex:paramToDelete]];
                [self clearKeyboardParamList];
                [self buildKeyboardParamList];
            }
            else if(deleteActionType == 1){
                [dspParameters removeObjectForKey:[dspKeys objectAtIndex:paramToDelete]];
                [self clearDspParamList];
                [self buildDspParamList];
            }
        }
        [popupWindow setHidden:true];
    }
}

@end
