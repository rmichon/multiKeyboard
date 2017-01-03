//
//  PresetMenu.h
//  iOSKeyboard
//
//  Created by Romain Michon on 12/27/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Button.h"

@interface PresetMenu : UIControl{
    @public
    int currentPreset;
}

- (id)initWithFrame:(CGRect)frame withCurrentPreset:(int)preset;

@end
