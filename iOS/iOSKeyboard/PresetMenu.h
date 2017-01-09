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
    NSInteger currentPreset;
    NSInteger actionType; // 0 for run preset and 1 for update audio settings
}

- (id)initWithFrame:(CGRect)frame withCurrentPreset:(NSInteger)preset;

@end
