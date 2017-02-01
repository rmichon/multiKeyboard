//
//  NavBar.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "NavBar.h"

@implementation NavBar{
    NSMutableArray *buttons; // global pointers to the buttons
    int nButtons; // number of buttons
    UIColor *textOnColor, *textOffColor; // colors of the different states of the button
}

- (id)initWithFrame:(CGRect)frame withOrientation:(Boolean)orientation{
    self = [super initWithFrame:frame];
    if(self){
        [self setBackgroundColor:[UIColor blackColor]];
        
        touchedButton = 0;
        
        // setting size params
        nButtons = 5;
        CGFloat borderSize = 1;
        CGFloat buttonsWidth = frame.size.width/nButtons; // used only in horizontal mode
        CGFloat buttonsHeight = frame.size.height/nButtons; // used only in vertical mode
        
        // setting font size
        CGFloat fontSize = 24;
        
        // scaling font size in function of screen size
        CGFloat referenceWidth = 1024;
        fontSize = fontSize*fmax(frame.size.width,frame.size.height)/referenceWidth;
        
        // color map TODO textOffColor actually not defined anywhere
        textOnColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
        textOnColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        
        // building the navigation bar
        buttons = [[NSMutableArray alloc] init];
        NSArray *buttonsLabel = [[NSArray alloc] initWithObjects:@"Home", @"Settings", @"- Preset", @"+ Preset", @"Flip", nil];
        for(int i=0; i<nButtons; i++){
            Button *button;
            if(orientation){
                button = [[Button alloc] initWithFrame:CGRectMake(borderSize+(buttonsWidth+borderSize)*i, borderSize, buttonsWidth-borderSize*2, frame.size.height-borderSize*2)];
            }
            else{
                button = [[Button alloc] initWithFrame:CGRectMake(borderSize, borderSize+(buttonsHeight+borderSize)*i, frame.size.width-borderSize*2, buttonsHeight-borderSize*2)];
            }
            [button setTag:i];
            [button setOnImage:[UIImage imageNamed:@"navBarButtonsOn.png"]];
            [button setOffImage:[UIImage imageNamed:@"navBarButtonsOff.png"]];
            [button setTextColor:textOffColor];
            [button setTextFont:[UIFont boldSystemFontOfSize:fontSize]];
            [button setText:[buttonsLabel objectAtIndex:i]];
            [button addTarget:self action:@selector(newEventOnButton:) forControlEvents:UIControlEventValueChanged];
            [self addSubview:button];
            [buttons insertObject:button atIndex:i];
        }
    }
    return self;
}

- (IBAction)newEventOnButton:(Button*)sender{
    if(sender->on){
        if(sender.tag == 1){
            if(sender->polarity){
                [sender setOffImage:[UIImage imageNamed:@"navBarButtonsOn.png"]];
                [[buttons objectAtIndex:2] setOffImage:[UIImage imageNamed:@"navBarButtonsOn.png"]];
                [[buttons objectAtIndex:3] setOffImage:[UIImage imageNamed:@"navBarButtonsOn.png"]];
                [[buttons objectAtIndex:4] setOffImage:[UIImage imageNamed:@"navBarButtonsOn.png"]];
                [sender setTextColor:textOnColor];
            }
            else{
                [sender setOffImage:[UIImage imageNamed:@"navBarButtonsOff.png"]];
                [[buttons objectAtIndex:2] setOffImage:[UIImage imageNamed:@"navBarButtonsOff.png"]];
                [[buttons objectAtIndex:3] setOffImage:[UIImage imageNamed:@"navBarButtonsOff.png"]];
                [[buttons objectAtIndex:4] setOffImage:[UIImage imageNamed:@"navBarButtonsOff.png"]];
                [sender setTextColor:textOffColor];
            }
        }
        touchedButton = sender.tag;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}
 
@end
