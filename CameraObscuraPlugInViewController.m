//
//  CameraObscuraPlugInViewController.m
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CameraObscuraPlugInViewController.h"

@implementation CameraObscuraPlugInViewController

@synthesize devicesPopUp = _devicesPopUp;

- (id)initWithPlugIn:(QCPlugIn*)plugIn viewNibName:(NSString*)name {
    self = [super initWithPlugIn:plugIn viewNibName:name];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark - 

- (void)awakeFromNib {
    NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

#pragma mark -

- (IBAction)selectedDeviceChanged:(id)sender {
    NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

@end
