//
//  ConfigDisplay.m
//  iOSKeyboard
//
//  Created by Romain Michon on 12/16/16.
//  Copyright © 2016 CCRMA. All rights reserved.
//

#import "ConfigDisplay.h"

@implementation ConfigDisplay{
    //NSMutableDictionary *parameters;
}

- (id)initWithFrame:(CGRect)frame withParams:(NSMutableDictionary*)params{
    self = [super initWithFrame:frame];
    if(self){
        [self setBackgroundColor:[UIColor whiteColor]];
        
        /*
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        // TODO: wrong name! Should be the same as preset name
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"params"];
        
        parameters = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
        */
        
        
    }
    return self;
}

@end
