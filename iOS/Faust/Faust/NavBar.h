//
//  NavBar.h
//  iOSKeyboard
//
//  Created by Romain Michon on 12/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Button.h"

@interface NavBar : UIControl{
    @public
    NSInteger touchedButton;
}

- (id)initWithFrame:(CGRect)frame withOrientation:(Boolean)orientation;

@end
