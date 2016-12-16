//
//  Button.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "Button.h"

@implementation Button{
    UIView *layerOn;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self setBackgroundColor:[UIColor redColor]]; // default "off" color
        on = false; // default is off
        
        // Status "on" layer
        layerOn = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
        // Default "on" color
        [layerOn setBackgroundColor:[UIColor greenColor]];
        [layerOn setHidden:true];
        [self addSubview:layerOn];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self setOn];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self setOff];
}

- (void)setOn{
    [layerOn setHidden:false];
    on = true;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOff{
    [layerOn setHidden:true];
    on = false;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOffColor:(UIColor*)offColor{
    [self setBackgroundColor:offColor];
}

- (void)setOnColor:(UIColor*)onColor{
    [layerOn setBackgroundColor:onColor];
}

@end
