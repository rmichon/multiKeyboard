//
//  NavBar.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "NavBar.h"

@implementation NavBar{
    NSMutableArray *buttons;
    int nButtons;
}

- (id)initWithFrame:(CGRect)frame withOrientation:(Boolean)orientation{
    self = [super initWithFrame:frame];
    if(self){
        [self setBackgroundColor:[UIColor blackColor]];
        
        touchedButton = 0;
        
        nButtons = 5;
        CGFloat buttonsBorderSize = 1;
        
        buttons = [[NSMutableArray alloc] init];
        
        for(int i=0; i<nButtons; i++){
            Button *button;
            if(orientation){
                CGFloat buttonsWidth = frame.size.width/nButtons-buttonsBorderSize*2;
                button = [[Button alloc] initWithFrame:CGRectMake(buttonsBorderSize*(1 + 2*i)+buttonsWidth*i, 0.0f, buttonsWidth, frame.size.height)];
                // TODO will have horizontal button image set here instead
                [button setOnColor:[UIColor greenColor]];
                [button setOffColor:[UIColor redColor]];
            }
            else{
                CGFloat buttonsHeight = frame.size.height/nButtons-buttonsBorderSize*2;
                button = [[Button alloc] initWithFrame:CGRectMake(0.0f, buttonsBorderSize*(1 + 2*i)+buttonsHeight*i, frame.size.width, buttonsHeight)];
                // TODO will have vertical button image set here instead
                [button setOnColor:[UIColor blueColor]];
                [button setOffColor:[UIColor yellowColor]];
            }
            button->ID = i;
            [button addTarget:self action:@selector(newEventOnButton:) forControlEvents:UIControlEventValueChanged];
            [self addSubview:button];
            [buttons insertObject:button atIndex:i];
        }
    }
    return self;
}

- (IBAction)newEventOnButton:(Button*)sender{
    if(sender->on){
        touchedButton = sender->ID;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}
 
@end
