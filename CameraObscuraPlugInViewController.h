//
//  CameraObscuraPlugInViewController.h
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface CameraObscuraPlugInViewController : QCPlugInViewController {
    NSPopUpButton* _devicesPopUp;
}
@property (nonatomic, assign) IBOutlet NSPopUpButton* devicesPopUp;
- (IBAction)selectedDeviceChanged:(id)sender;
@end
