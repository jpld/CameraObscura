//
//  CameraObscuraPlugIn.h
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

@interface CameraObscuraPlugIn : QCPlugIn <ICDeviceBrowserDelegate> {
@private
    ICDeviceBrowser* _deviceBrowser;
}
@property (nonatomic) BOOL inputCapture;
@property (nonatomic, assign) id<QCPlugInOutputImageProvider> outputImage;
@property (nonatomic, readonly) ICDeviceBrowser* deviceBrowser;
@end
