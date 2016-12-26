//
//  ConfigDisplay.h
//  iOSKeyboard
//
//  Created by Romain Michon on 12/16/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Button.h"
#include "DspFaust.h"

@interface ConfigDisplay : UIView

- (id)initWithFrame:(CGRect)frame withParams:(NSMutableDictionary*)params withDspFaust:(DspFaust*)dsp;
- (void)saveState;

@end
