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
    Boolean polarity;
    UILabel *label;
}

- (void)setOnColor:(UIColor*)onColor;
- (void)setOffColor:(UIColor*)offColor;
- (void)setOnImage:(UIImage*)fillImage;
- (void)setOffImage:(UIImage*)fillImage;
- (Boolean)getPolarity;
- (void)setText:(NSString*)t;
- (void)setTextColor:(UIColor*)color;
- (void)setTextFont:(UIFont*)font;

@end
