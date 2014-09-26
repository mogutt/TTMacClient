//
//  RTXTabItemView.h
//  Duoduo
//
//  Created by zuoye on 13-12-23.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RTXTabItemView : NSView{
    BOOL bMouseDown;
    BOOL bMouseLeave;
}


@property NSSize imageSize;
@property NSImage *image;
@property NSImage *alterImage;
@property NSImage *selectImage;
@property id target;
@property float bHighetLight;

@end
