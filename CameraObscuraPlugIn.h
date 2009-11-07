//
//  CameraObscuraPlugIn.h
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

@interface CameraObscuraPlugIn : QCPlugIn <ICDeviceBrowserDelegate, ICCameraDeviceDelegate> {
@private
    BOOL _isCaptureDone;
    BOOL _captureDoneChanged;
    BOOL _isExecutionEnabled;
    ICDeviceBrowser* _deviceBrowser;
    ICCameraDevice* _camera;
}
@property (nonatomic) BOOL inputCaptureSignal;
@property (nonatomic, assign) id<QCPlugInOutputImageProvider> outputImage;
@property (nonatomic) BOOL outputDoneSignal;

@property (nonatomic, readonly, assign) ICDeviceBrowser* deviceBrowser;
@property (nonatomic, retain) ICCameraDevice* camera;
@end
