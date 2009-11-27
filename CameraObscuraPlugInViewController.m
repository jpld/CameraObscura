//
//  CameraObscuraPlugInViewController.m
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CameraObscuraPlugInViewController.h"
#import "CameraObscuraPlugIn.h"

static NSString* _COVCCameraObservationContext = @"_COVCCameraObservationContext";

@interface CameraObscuraPlugInViewController()
- (void)_setupObservation;
- (void)_invalidateObservation;
@end

@implementation CameraObscuraPlugInViewController

@synthesize devicesPopUp = _devicesPopUp;

- (id)initWithPlugIn:(QCPlugIn*)plugIn viewNibName:(NSString*)name {
    self = [super initWithPlugIn:plugIn viewNibName:name];
    if (self) {
        [self _setupObservation];
    }
    return self;
}

- (void)finalize {
    [self _invalidateObservation];

    [super finalize];
}

- (void)dealloc {
    [self _invalidateObservation];

    [super dealloc];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context == _COVCCameraObservationContext) {
        // TODO - this reactive approach isn't the right way to handle this and it doesn't work on the second assignment
        // fixup selection, selectedObject doesn't seem to observe the value, so if it doesn't change it, it doesn't take note
        if ([(CameraObscuraPlugIn*)self.plugIn camera] != self.devicesPopUp.selectedItem.representedObject)
            [self.devicesPopUp selectItemAtIndex:0];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -

- (void)_setupObservation {
    [self.plugIn addObserver:self forKeyPath:@"camera" options:nil context:_COVCCameraObservationContext];
}

- (void)_invalidateObservation {
    [self.plugIn removeObserver:self forKeyPath:@"camera"];
}

@end
