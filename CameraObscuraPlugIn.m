//
//  CameraObscuraPlugIn.m
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import "CameraObscuraPlugIn.h"
#import "CameraObscuraPlugInViewController.h"
#import "ICCameraDevice-COAdditions.h"

#if CONFIGURATION == DEBUG
    #define CODebugLogSelector() NSLog(@"-[%@ %@]", /*NSStringFromClass([self class])*/self, NSStringFromSelector(_cmd))
    #define CODebugLog(a...) NSLog(a)
#else
    #define CODebugLogSelector()
    #define CODebugLog(a...)
#endif

#define COLocalizedString(key, comment) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:(nil)]

static NSString* _COExecutionEnabledObservationContext = @"_COExecutionEnabledObservationContext";
static NSString* _COCameraObservationContext = @"_COCameraObservationContext";
static NSString* _COCameraDelegateObservationContext = @"_COCameraDelegateObservationContext";


// WORKAROUND - naming violation for cocoa memory management
@interface QCPlugIn(CameraObscuraAdditions)
- (QCPlugInViewController*)createViewController NS_RETURNS_RETAINED;
@end


@interface CameraObscuraPlugIn()
@property (nonatomic, getter=isExecutionEnabled) BOOL executionEnabled;
@property (nonatomic, readwrite, assign) ICDeviceBrowser* deviceBrowser;
@property (nonatomic, retain) id <QCPlugInOutputImageProvider> placeHolderProvider;
- (void)_setupObservation;
- (void)_invalidateObservation;
- (void)_cleanUpDeviceBrowser;
- (void)_cleanUpCamera;
- (void)_didDownloadFile:(ICCameraFile*)file error:(NSError*)error options:(NSDictionary*)options contextInfo:(void*)contextInfo;
- (void)_didReadData:(NSData*)data fromFile:(ICCameraFile*)file error:(NSError*)error contextInfo:(void*)contextInfo;
- (ICCameraDevice*)_nextAvailableCamera;
@end

@implementation CameraObscuraPlugIn

@dynamic inputCaptureSignal, outputImage, outputDoneSignal;
@synthesize deleteImageFromSource = _deleteImageFromSource/*, saveCopyOfOriginalImage = _saveCopyOfOriginalImage*/;
@synthesize executionEnabled = _isExecutionEnabled, deviceBrowser = _deviceBrowser, camera = _camera, placeHolderProvider = _placeHolderProvider;

static void _BufferReleaseCallback(const void* address, void* context) {
    CODebugLog(@"_BufferReleaseCallback(const void* address, void* context)");
    // release bitmap context backing
    free((void*)address);
}

+ (NSDictionary*)attributes {
	return [NSDictionary dictionaryWithObjectsAndKeys:COLocalizedString(@"kQCPlugIn_Name", NULL), QCPlugInAttributeNameKey, COLocalizedString(@"kQCPlugIn_Description", NULL), QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    // TODO - localize?
    if ([key isEqualToString:@"inputCaptureSignal"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Capture Signal", QCPortAttributeNameKey, nil];
    else if ([key isEqualToString:@"outputImage"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
    else if ([key isEqualToString:@"outputDoneSignal"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Done Signal", QCPortAttributeNameKey, nil];
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode {
	return kQCPlugInTimeModeNone;
}

+ (NSArray*)plugInKeys {
    // return [NSArray arrayWithObjects:@"deleteImageFromSource", @"saveCopyOfOriginalImage", nil];
    return [NSArray arrayWithObjects:@"deleteImageFromSource", nil];
}

#pragma mark -

- (id)init {
    self = [super init];
	if (self) {
        self.deleteImageFromSource = YES;
        [self _setupObservation];

        self.deviceBrowser = [[ICDeviceBrowser alloc] init];
        self.deviceBrowser.delegate = self;
        self.deviceBrowser.browsedDeviceTypeMask = ICDeviceLocationTypeMaskLocal | ICDeviceTypeMaskCamera;
        [self.deviceBrowser start];
    }
	return self;
}

- (void)finalize {
    [self _invalidateObservation];

    [self _cleanUpDeviceBrowser];
    [self _cleanUpCamera];

    CGImageRelease(_sourceImage);
    self.placeHolderProvider = nil;

    [super finalize];
}

- (void)dealloc {
    [self _invalidateObservation];

    [self _cleanUpDeviceBrowser];
    [self _cleanUpCamera];

    CGImageRelease(_sourceImage);
    self.placeHolderProvider = nil;

    [super dealloc];
}

#pragma mark -

- (id)serializedValueForKey:(NSString*)key {
	/*
	Provide custom serialization for the plug-in internal settings that are not values complying to the <NSCoding> protocol.
	The return object must be nil or a PList compatible i.e. NSString, NSNumber, NSDate, NSData, NSArray or NSDictionary.
	*/

    CODebugLogSelector();

    id value = nil;
    if ([key isEqualToString:@"deleteImageFromSource"])
        value = [NSNumber numberWithBool:self.deleteImageFromSource];
    // else if ([key isEqualToString:@"saveCopyOfOriginalImage"])
    //     value = [NSNumber numberWithBool:self.saveCopyOfOriginalImage];
    else
	    value = [super serializedValueForKey:key];
    return value;
}

- (void)setSerializedValue:(id)serializedValue forKey:(NSString*)key {
	/*
	Provide deserialization for the plug-in internal settings that were custom serialized in -serializedValueForKey.
	Deserialize the value, then call [self setValue:value forKey:key] to set the corresponding internal setting of the plug-in instance to that deserialized value.
	*/

    CODebugLogSelector();

    // TODO - self.camera.UUIDString
    if ([key isEqualToString:@"deleteImageFromSource"])
        self.deleteImageFromSource = [serializedValue boolValue];
    // else if ([key isEqualToString:@"saveCopyOfOriginalImage"])
    //     self.saveCopyOfOriginalImage = [serializedValue boolValue];
    else
	    [super setSerializedValue:serializedValue forKey:key];
}

- (QCPlugInViewController*)createViewController {
	return [[CameraObscuraPlugInViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context == _COExecutionEnabledObservationContext) {
        if (self.isExecutionEnabled && self.camera && !self.camera.hasOpenSession) {
            CODebugLog(@"%@ requesting session open '%@'", self, self.camera.name);
            [self.camera requestOpenSession];
            // use timeout to catch open session request failure
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1LL * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
                if (self.camera.hasOpenSession && self.camera.delegate == self)
                    return;
                NSLog(@"NOTICE - %@ failed to open session on '%@'", self, self.camera.name);
                self.camera = [self _nextAvailableCamera];
            });
        } else if (!self.isExecutionEnabled && self.camera && self.camera.hasOpenSession) {
            CODebugLog(@"%@ requesting session close '%@'", self, self.camera.name);
            [self.camera requestCloseSession];

            // cancel any inflight downloads
            [self.camera cancelDownload];

            // release bitmap context backing
            self.placeHolderProvider = nil;
        }
    } else if (context == _COCameraObservationContext) {
        if (!self.camera)
            return;
        if ([(NSNumber*)[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
            if (self.camera.hasOpenSession && self.camera.delegate == self) {
                CODebugLog(@"%@ requesting session close '%@'", self, self.camera.name);
                [self.camera requestCloseSession];
            }

            // stop observation of camera delegate
            [self.camera removeObserver:self forKeyPath:@"delegate"];
            if (self.camera.delegate == self)
                self.camera.delegate = nil;
        } else {
            if (!self.camera.canTakePictures) {
                NSLog(@"ERROR - %@ selected capture source '%@', not capable of tethered shooting in current configuration", self, self.camera.name);
                self.camera = nil;
                return;
            }
            if (self.camera.hasOpenSession || self.camera.delegate)
                NSLog(@"NOTICE - %@ taking over selection of '%@' from %@", self, self.camera.name, self.camera.delegate);

            self.camera.delegate = self;
            // observe camera delegate
            [self.camera addObserver:self forKeyPath:@"delegate" options:NSKeyValueObservingOptionPrior context:_COCameraDelegateObservationContext];

            if (self.isExecutionEnabled) {
                CODebugLog(@"%@ requesting session open '%@'", self, self.camera.name);
                [self.camera requestOpenSession];
                // use timeout to catch open session request failure
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1LL * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
                    if (self.camera.hasOpenSession && self.camera.delegate == self)
                        return;
                    NSLog(@"NOTICE - %@ failed to open session on '%@'", self, self.camera.name);
                    self.camera = [self _nextAvailableCamera];
                });
            }
            if (!self.camera.canDeleteOneFile)
                NSLog(@"WARNING - %@ unable to remotely delete files from selected camera '%@', capture session may be limted to camera's local storage.", self, self.camera.name);
        }
    } else if (context == _COCameraDelegateObservationContext) {
        if ([(NSNumber*)[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
          NSLog(@"NOTICE - %@ losing selection of '%@' to %@", self, self.camera.name, self.camera.delegate);
          if (self.camera.hasOpenSession) {
              CODebugLog(@"%@ requesting session close '%@'", self, self.camera.name);
              [self.camera requestCloseSession];
          }
          self.camera = nil;          
      }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark EXECUTION

- (BOOL)startExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
    Return NO in case of fatal failure (this will prevent rendering of the composition to start).
    */

    CODebugLogSelector();

    return YES;
}

- (void)enableExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
    */

    CODebugLogSelector();

    self.executionEnabled = YES;
}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
    // setup provider and assign output image when new image ready
    if (_captureDoneChanged && _isCaptureDone) {
        CODebugLog(@"%@ redrawing image into known pixel format, creating placeHolderProvider and assigning output image", self);

        // TODO - move this to a separate method and message from _didDownloadFile: and _didReadData:
        size_t bytesPerRow = CGImageGetWidth(_sourceImage) * 4;
        if(bytesPerRow % 16)
            bytesPerRow = ((bytesPerRow / 16) + 1) * 16;

        void* baseAddress = valloc(CGImageGetHeight(_sourceImage) * bytesPerRow);
        if (baseAddress == NULL) {
            CGImageRelease(_sourceImage);
            _sourceImage = NULL;
            return NO;
        }

        CGContextRef bitmapContext = CGBitmapContextCreate(baseAddress, CGImageGetWidth(_sourceImage), CGImageGetHeight(_sourceImage), 8, bytesPerRow, [context colorSpace], kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
        if (bitmapContext == NULL) {
            free(baseAddress);
            CGImageRelease(_sourceImage);
            _sourceImage = NULL;
            return NO;
        }
        CGRect bounds = CGRectMake(0., 0., CGImageGetWidth(_sourceImage), CGImageGetHeight(_sourceImage));
        CGContextClearRect(bitmapContext, bounds);
        CGContextDrawImage(bitmapContext, bounds, _sourceImage);

        self.placeHolderProvider = [context outputImageProviderFromBufferWithPixelFormat:QCPlugInPixelFormatBGRA8 pixelsWide:CGImageGetWidth(_sourceImage) pixelsHigh:CGImageGetHeight(_sourceImage) baseAddress:baseAddress bytesPerRow:bytesPerRow releaseCallback:_BufferReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:YES];
        self.outputImage = self.placeHolderProvider;

        // cleanup
        CGImageRelease(_sourceImage);
        _sourceImage = NULL;
        CGContextRelease(bitmapContext);
    }

    // update capture done signal when changed
    if (_captureDoneChanged) {
        self.outputDoneSignal = _isCaptureDone;
        _captureDoneChanged = _isCaptureDone;
        _isCaptureDone = NO;
    }

    // only process input on the rising edge
    if (!([self didValueForInputKeyChange:@"inputCaptureSignal"] && self.inputCaptureSignal))
        return YES;

    CODebugLogSelector();

    if (!self.camera || !self.camera.hasOpenSession)
        return YES;

    // TODO - could offer a blocking synchronous execution mode

    // TODO - need to make sure the device is ready first?
    CODebugLog(@"%@ taking picture on '%@'", self, self.camera.name);
    [self.camera requestTakePicture];

    return YES;
}

- (void)disableExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
    */

    CODebugLogSelector();

    self.executionEnabled = NO;
}

- (void)stopExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
    */

    // TOOD - teardown here instead of -dealloc/-finalize

    CODebugLogSelector();
}

#pragma mark -
#pragma mark DEVICE BROWSER DELEGATE

- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)device moreComing:(BOOL)moreComing {
    CODebugLogSelector();

    // if a camera is already assigned bail, otherwise use the first supported camera
    if (self.camera)
        return;

    ICCameraDevice* camera = (ICCameraDevice*)device;
    if (!camera.canTakePictures) {
        NSLog(@"NOTICE - %@ device '%@' not capable of tethered shooting in current configuration", self, device.name);
        return;
    }
    if (camera.hasOpenSession || camera.delegate) {
        NSLog(@"NOTICE - %@ device '%@' already in use by %@", self, device.name, device.delegate);
        return;
    }

    CODebugLog(@"%@ auto selected %@", self, camera);
    self.camera = camera;
}

- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing {
    CODebugLogSelector();

    if (device != self.camera)
        return;

    [self didRemoveDevice:device];
}

- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeName:(ICDevice*)device {
    CODebugLogSelector();

    // TODO - update display name in popup if visible
}

- (void)deviceBrowserDidEnumerateLocalDevices:(ICDeviceBrowser*)browser {
    CODebugLogSelector();
}

#pragma mark -
#pragma mark DEVICE DELEGATE

- (void)didRemoveDevice:(ICDevice*)device {
    CODebugLogSelector();

    if (device != self.camera)
        return;

    CODebugLog(@"%@ removed '%@'", self, self.camera.name);

    [self _cleanUpCamera];
    // TODO - grab another camera?
}

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error {
    CODebugLogSelector();

    if (device != self.camera || !error)
        return;

    NSLog(@"ERROR - %@ failed to open '%@'", self, self.camera.name);

    [self _cleanUpCamera];
    // TODO - go cry in the corner?
}

- (void)deviceDidBecomeReady:(ICDevice*)device {
    CODebugLogSelector();

    if (device != self.camera)
        return;

    CODebugLog(@"%@ ready '%@'", self, self.camera.name);
}

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error {
    CODebugLogSelector();
}

- (void)deviceDidChangeSharingState:(ICDevice*)device {
    CODebugLogSelector();
}

- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status {
    CODebugLogSelector();
}

- (void)device:(ICDevice*)device didEncounterError:(NSError*)error {
    CODebugLogSelector();
}

- (void)device:(ICDevice*)device didReceiveButtonPress:(NSString*)buttonType {
    CODebugLogSelector();
}

#pragma mark -
#pragma mark CAMERA DELEGATE

- (void)cameraDevice:(ICCameraDevice*)camera didAddItem:(ICCameraItem*)item {
    CODebugLogSelector();

    if (!UTTypeConformsTo((CFStringRef)(item.UTI), kUTTypeImage))
        return;

    ICCameraFile* file = (ICCameraFile*)item;

    // TODO - compare performance / complexity of download vs in-memory read
#define DOWNLOAD_IMAGE 0
#if DOWNLOAD_IMAGE
    CODebugLog(@"%@ downloading image from '%@'", self, self.camera.name);
    // TODO - use input to determine download location
    NSMutableDictionary* options = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSURL fileURLWithPath:[@"~/Desktop/" stringByExpandingTildeInPath]], ICDownloadsDirectoryURL, nil];
    // TODO - plan accordingly around !camera.canDeleteOneFile
    if (self.deleteImageFromSource && camera.canDeleteOneFile)
        [options setObject:[NSNumber numberWithBool:YES] forKey:ICDeleteAfterSuccessfulDownload];
    [camera requestDownloadFile:file options:options downloadDelegate:self didDownloadSelector:@selector(_didDownloadFile:error:options:contextInfo:) contextInfo:NULL];
    [options release];
#else
    CODebugLog(@"%@ reading image from '%@'", self, self.camera.name);
    [camera requestReadDataFromFile:file atOffset:0 length:file.fileSize readDelegate:self didReadDataSelector:@selector(_didReadData:fromFile:error:contextInfo:) contextInfo:NULL];
#endif
}

#pragma mark -
#pragma mark PRIVATE

- (void)_setupObservation {
    [self addObserver:self forKeyPath:@"executionEnabled" options:0 context:_COExecutionEnabledObservationContext];
    [self addObserver:self forKeyPath:@"camera" options:NSKeyValueObservingOptionPrior context:_COCameraObservationContext];
}

- (void)_invalidateObservation {
    [self removeObserver:self forKeyPath:@"executionEnabled"];
    [self removeObserver:self forKeyPath:@"camera"];
}

- (void)_cleanUpDeviceBrowser {
    [self.deviceBrowser stop];
    self.deviceBrowser.delegate = nil;
    [_deviceBrowser release];
    _deviceBrowser = nil;
}

- (void)_cleanUpCamera {
    if (self.camera.hasOpenSession && self.camera.delegate == self) {
        CODebugLog(@"%@ closing '%@'", self, self.camera.name);
        [self.camera requestCloseSession];
        self.openSessionRequestSucceeded = NO;
    }
    [self.camera removeObserver:self forKeyPath:@"delegate"];
    if (self.camera.delegate == self)
        self.camera.delegate = nil;
    self.camera = nil;
}

- (void)_didDownloadFile:(ICCameraFile*)file error:(NSError*)error options:(NSDictionary*)options contextInfo:(void*)contextInfo {
    CODebugLogSelector();

    if (error != NULL) {
        NSLog(@"ERROR - %@ failed to download image - %@.", self, error);
        return;
    }

    CODebugLog(@"%@ download of '%@' complete", self, [options objectForKey:ICSavedFilename]);

    // NB - this should never occur, the KVO on executionEnabled should close the session immediately
    if (!self.executionEnabled) {
        NSLog(@"ERROR - %@ execution disabled but new image downlaoded and possibly saved to disk", self);
        return;
    }

    CGImageRelease(_sourceImage);

    NSURL* downloadsDirectoryURL = [options objectForKey:ICDownloadsDirectoryURL];
    NSString* filePath =  [[downloadsDirectoryURL path] stringByAppendingPathComponent:[options objectForKey:ICSavedFilename]];
    NSURL* fileURL = [NSURL fileURLWithPath:filePath];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)fileURL, NULL);
    _sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    CFRelease(imageSource);

    _isCaptureDone = YES;
    _captureDoneChanged = YES;
}

- (void)_didReadData:(NSData*)data fromFile:(ICCameraFile*)file error:(NSError*)error contextInfo:(void*)contextInfo {
    CODebugLogSelector();

    if (error != NULL) {
        NSLog(@"ERROR - %@ failed to read image - %@", self, error);
        return;
    }

    CODebugLog(@"%@ read of '%@' complete", self, file.name);

    // TODO - save on a seprate thread? [self performSelectorInBackground:@selector(_writeImageData:) withObject:data];
    // if (self.saveCopyOfOriginalImage) {
    //     NSString* filePath =  [self.saveLocation stringByAppendingPathComponent:file.name];
    //     NSURL* fileURL = [NSURL fileURLWithPath:filePath];
    //     BOOL status = [data writeToURL:fileURL options:nil error:&error];
    //     if (!status)
    //         NSLog(@"ERROR - %@ failed to save image - %@", self, error);
    // }

    // NB - this should never occur, the KVO on executionEnabled should close the session immediately
    if (!self.executionEnabled) {
        NSLog(@"ERROR - %@ execution disabled but new image read and possibly saved to disk", self);
        return;
    }

    CGImageRelease(_sourceImage);

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    _sourceImage = CGImageCreateWithJPEGDataProvider(provider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);

    // TODO - plan accordingly around !camera.canDeleteOneFile
    if (self.deleteImageFromSource && file.device.canDeleteOneFile) {
        NSArray* files = [[NSArray alloc] initWithObjects:file, nil];
        [file.device requestDeleteFiles:files];
        [files release];
    }

    _isCaptureDone = YES;
    _captureDoneChanged = YES;
}

- (ICCameraDevice*)_nextAvailableCamera {
    ICCameraDevice* camera = nil;
    for (ICCameraDevice* c in self.deviceBrowser.devices) {
        if (!c.canTakePictures || c.hasOpenSession || c.delegate)
            continue;
        camera = c;
        break;
    }
    return camera;
}

@end
