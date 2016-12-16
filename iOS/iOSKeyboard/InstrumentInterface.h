//
//  InstrumentInterface.h
//  iOSKeyboard
//
//  Created by Romain Michon on 12/15/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "DspFaust.h"
#import "MultiKeyboard.h"
#import "NavBar.h"
#import "ConfigDisplay.h"

@interface InstrumentInterface : UIView

- (id)initWithFrame:(CGRect)frame withFaustDSP:(DspFaust*)dsp;

@end
