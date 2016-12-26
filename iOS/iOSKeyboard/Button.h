//
//  Button.h
//  iOSKeyboard
//
//  Created by Romain Michon on 12/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Button : UIControl{
    @public
    Boolean on;
    int ID;
    Boolean polarity;
}

- (void)setOnColor:(UIColor*)onColor;
- (void)setOffColor:(UIColor*)offColor;

@end
