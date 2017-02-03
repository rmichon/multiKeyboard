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

- (id)initWithFrame:(CGRect)frame withKeyboardParams:(NSMutableDictionary*)keyboardParams withDspParamas:(NSMutableDictionary*)dspParams withDspFaust:(DspFaust*)dsp;

@end
