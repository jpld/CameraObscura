//
//  CameraObscuraPlugIn.h
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface CameraObscuraPlugIn : QCPlugIn {
}
@property (nonatomic) BOOL inputCapture;
@property (nonatomic, retain) id<QCPlugInOutputImageProvider> outputImage;
@end
