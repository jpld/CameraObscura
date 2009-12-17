//
//  CameraObscuraPlugInViewController.m
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CameraObscuraPlugInViewController.h"
#import "CameraObscuraPlugIn.h"
#import "ICCameraDevice-COAdditions.h"

static NSString* _COVCCameraObservationContext = @"_COVCCameraObservationContext";
static NSString* _COVCDevicesObservationContext = @"_COVCDevicesObservationContext";


@interface CameraObscuraPlugInViewController()
- (void)_setupObservation;
- (void)_invalidateObservation;
- (void)_rebuildPopUpMenu;
- (void)_setPopUpSelection;
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

- (void)awakeFromNib {
    [self _rebuildPopUpMenu];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context == _COVCCameraObservationContext) {
        // fixup popup selection when plugIn.camera is assigned from
        if ([(CameraObscuraPlugIn*)self.plugIn camera] != self.devicesPopUp.selectedItem.representedObject)
            [self _setPopUpSelection];
    } else if (context == _COVCDevicesObservationContext) {
        [self _rebuildPopUpMenu];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -

- (IBAction)devicesPopUpSelectionChanged:(id)sender {
    CameraObscuraPlugIn* plugIn = (CameraObscuraPlugIn*)self.plugIn;
    plugIn.camera = self.devicesPopUp.selectedItem.representedObject;
}

#pragma mark -

- (void)_setupObservation {
    [self.plugIn addObserver:self forKeyPath:@"camera" options:nil context:_COVCCameraObservationContext];
    [[(CameraObscuraPlugIn*)self.plugIn deviceBrowser] addObserver:self forKeyPath:@"devices" options:nil context:_COVCDevicesObservationContext];
}

- (void)_invalidateObservation {
    [self.plugIn removeObserver:self forKeyPath:@"camera"];
    [[(CameraObscuraPlugIn*)self.plugIn deviceBrowser] removeObserver:self forKeyPath:@"devices"];
}

- (void)_rebuildPopUpMenu {
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@""];
    [menu setAutoenablesItems:NO];

    // TODO - localize 'None'
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@"None" action:NULL keyEquivalent:@""];
    [menu addItem:item];
    [item release];

    // add a separator if there are items
    CameraObscuraPlugIn* plugIn = (CameraObscuraPlugIn*)self.plugIn;
    if (plugIn.deviceBrowser.devices.count > 0)
        [menu addItem:[NSMenuItem separatorItem]];

    for (ICCameraDevice* camera in plugIn.deviceBrowser.devices) {
        // TODO - localize 'Unknown'
        item = [[NSMenuItem alloc] initWithTitle:(camera.name ? camera.name : @"Unknown") action:NULL keyEquivalent:@""];
        // disallow stealing the device from another source
        [item setEnabled:camera.canTakePictures && (!camera.delegate || camera.delegate == plugIn)];

        // if (camera.icon) {
        //     NSImage* image = [[NSImage alloc] initWithCGImage:camera.icon size:NSMakeSize(CGImageGetWidth(camera.icon), CGImageGetHeight(camera.icon))];
        //     [item setImage:image];
        //     [image release];
        // }

        [item setRepresentedObject:camera];

        [menu addItem:item];
        [item release];
    }

    [self.devicesPopUp setMenu:menu];
    [menu release];

    [self _setPopUpSelection];
}

- (void)_setPopUpSelection {
    NSMenuItem* selectedItem = nil;
    for (NSMenuItem* item in self.devicesPopUp.menu.itemArray) {
        if ([item representedObject] != [(CameraObscuraPlugIn*)self.plugIn camera])
            continue;
        selectedItem = item;
        break;
    }
    [self.devicesPopUp selectItem:selectedItem];
}

@end
