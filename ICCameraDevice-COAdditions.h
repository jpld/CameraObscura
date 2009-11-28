//
//  ICCameraDevice-COAdditions.h
//  CameraObscura
//
//  Created by jpld on 27 Nov 2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageCaptureCore/ICCameraDevice.h>

@interface ICCameraDevice(CameraObscuraAdditions)
- (BOOL)canTakePictures;
- (BOOL)canDeleteOneFile;
@end
