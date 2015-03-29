//
//  AMReflowOperation.m
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 11/7/14.
//  Copyright (c) 2014 Ian Ynda-Hummel. All rights reserved.
//

#import "AMReflowOperation.h"

#import "AMConfiguration.h"
#import <Silica/Silica.h>

@interface AMFrameAssignment ()
@property (nonatomic, assign) CGRect finalFrame;
@property (nonatomic, strong) SIWindow *window;
@property (nonatomic, assign) BOOL focused;
@property (nonatomic, assign) CGRect screenFrame;
@end

@implementation AMFrameAssignment

- (instancetype)initWithFrame:(CGRect)finalFrame window:(SIWindow *)window focused:(BOOL)focused screenFrame:(CGRect)screenFrame {
    self = [super init];
    if (self) {
        self.finalFrame = finalFrame;
        self.window = window;
        self.focused = focused;
        self.screenFrame = screenFrame;
    }
    return self;
}

@end

@interface AMReflowOperation ()
@property (nonatomic, strong) NSScreen *screen;
@property (nonatomic, strong) NSArray *windows;
@end

@implementation AMReflowOperation

- (instancetype)initWithScreen:(NSScreen *)screen windows:(NSArray *)windows {
    self = [super init];
    if (self) {
        self.screen = screen;
        self.windows = windows;
    }
    return self;
}

- (CGRect)adjustedFrameForLayout:(NSScreen *)screen {
    return [[AMConfiguration sharedConfiguration] ignoreMenuBar] ? screen.frameIncludingDockAndMenu : screen.frameWithoutDockOrMenu;
}

- (void)performFrameAssignments:(NSArray *)frameAssignments {
    if (self.cancelled) {
        return;
    }

    if (CGSManagedDisplayIsAnimating(CGSDefaultConnection, (__bridge CFStringRef)self.screen.am_screenIdentifier)) {
        return;
    }

    if (self.screen.am_isFullscreen) {
        return;
    }

    for (AMFrameAssignment *frameAssignment in frameAssignments) {
        SIWindow *window = frameAssignment.window;
        if (!window.isActive || !self.activeIDCache[@(window.windowID)]) {
            return;
        }
    }

    for (AMFrameAssignment *frameAssignment in frameAssignments) {
        [self assignFrame:frameAssignment.finalFrame toWindow:frameAssignment.window focused:frameAssignment.focused screenFrame:frameAssignment.screenFrame];
    }
}

- (void)assignFrame:(CGRect)finalFrame toWindow:(SIWindow *)window focused:(BOOL)focused screenFrame:(CGRect)screenFrame {
    CGRect  screenBorder = [self adjustedFrameForLayout:self.screen];
    CGFloat padding      = [[AMConfiguration sharedConfiguration] windowPadding];
    
    if([[AMConfiguration sharedConfiguration] windowPaddingCollapse]) {
        CGFloat collapsedPadding = floor(padding / 2);
        
        if(finalFrame.origin.x + collapsedPadding < screenBorder.origin.x + padding) {
            finalFrame.origin.x    = screenBorder.origin.x + padding;
            finalFrame.size.width -= collapsedPadding;
        }
        else {
            finalFrame.origin.x += collapsedPadding;
        }
        
        if(finalFrame.origin.y + collapsedPadding < screenBorder.origin.y + padding) {
            finalFrame.origin.y     = screenBorder.origin.y + padding;
            finalFrame.size.height -= collapsedPadding;
        }
        else {
            finalFrame.origin.y += collapsedPadding;
        }
    
        finalFrame.size.width  = MIN(finalFrame.size.width  - padding, screenBorder.size.width  + screenBorder.origin.x - padding - finalFrame.origin.x);
        finalFrame.size.height = MIN(finalFrame.size.height - padding, screenBorder.size.height + screenBorder.origin.y - padding - finalFrame.origin.y);
    }
    else {
        finalFrame.origin.x    += padding;
        finalFrame.origin.y    += padding;
        finalFrame.size.width  -= 2*padding;
        finalFrame.size.height -= 2*padding;
    }
    
    CGPoint finalPosition = finalFrame.origin;
    
    // Just resize the window
    finalFrame.origin = window.frame.origin;
    window.frame = finalFrame;
    
    if (focused) {
        finalFrame.size = CGSizeMake(MAX(window.frame.size.width, finalFrame.size.width), MAX(window.frame.size.height, finalFrame.size.height));
        if (!CGRectContainsRect(screenFrame, finalFrame)) {
            finalPosition.x = MIN(finalPosition.x, CGRectGetMaxX(screenFrame) - CGRectGetWidth(finalFrame));
            finalPosition.y = MIN(finalPosition.y, CGRectGetMaxY(screenFrame) - CGRectGetHeight(finalFrame));
        }
    }
    
    // Move the window to its final frame
    finalFrame.origin = finalPosition;
    window.frame = finalFrame;
}

@end
