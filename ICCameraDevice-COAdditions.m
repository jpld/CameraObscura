//
//  ICCameraDevice-COAdditions.m
//  CameraObscura
//
//  Created by jpld on 27 Nov 2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import "ICCameraDevice-COAdditions.h"

@implementation ICCameraDevice(CameraObscuraAdditions)

- (BOOL)canTakePictures {
    return [self.capabilities containsObject:ICCameraDeviceCanTakePicture];
}

- (BOOL)canDeleteOneFile {
    return [self.capabilities containsObject:ICCameraDeviceCanDeleteOneFile];
}

@end
