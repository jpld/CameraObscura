//
//  CameraObscuraPlugIn.m
//  CameraObscura
//
//  Created by jpld on 07 Sept 2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "CameraObscuraPlugIn.h"

#define	kQCPlugIn_Name				@"CameraObscura"
#define	kQCPlugIn_Description		@"This patch captures and returns an image from a given camera input device."

@implementation CameraObscuraPlugIn

@dynamic inputCapture, outputImage;

+ (NSDictionary*)attributes {
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    if ([key isEqualToString:@"inputCapture"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Capture", QCPortAttributeNameKey, /*[NSNumber numberWithUnsignedInteger:0], QCPortAttributeDefaultValueKey,*/ nil];
    else if ([key isEqualToString:@"outputImage"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, /*[NSNumber numberWithUnsignedInteger:0], QCPortAttributeDefaultValueKey,*/ nil];
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	/*
	Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	*/

	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode)timeMode {
	/*
	Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	*/

	return kQCPlugInTimeModeNone;
}

- (id)init {
    self = [super init];
	if (self) {
		/*
		Allocate any permanent resource required by the plug-in.
		*/
	}
	return self;
}

- (void)finalize {
	/*
	Release any non garbage collected resources created in -init.
	*/

	[super finalize];
}

- (void)dealloc {
	/*
	Release any resources created in -init.
	*/

	[super dealloc];
}

+ (NSArray*)plugInKeys {
	/*
	Return a list of the KVC keys corresponding to the internal settings of the plug-in.
	*/

	return nil;
}

- (id)serializedValueForKey:(NSString*)key {
	/*
	Provide custom serialization for the plug-in internal settings that are not values complying to the <NSCoding> protocol.
	The return object must be nil or a PList compatible i.e. NSString, NSNumber, NSDate, NSData, NSArray or NSDictionary.
	*/

	return [super serializedValueForKey:key];
}

- (void)setSerializedValue:(id)serializedValue forKey:(NSString*)key {
	/*
	Provide deserialization for the plug-in internal settings that were custom serialized in -serializedValueForKey.
	Deserialize the value, then call [self setValue:value forKey:key] to set the corresponding internal setting of the plug-in instance to that deserialized value.
	*/

	[super setSerializedValue:serializedValue forKey:key];
}

- (QCPlugInViewController*)createViewController {
	/*
	Return a new QCPlugInViewController to edit the internal settings of this plug-in instance.
	You can return a subclass of QCPlugInViewController if necessary.
	*/

	return [[QCPlugInViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

@end

@implementation CameraObscuraPlugIn(Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	*/

	return YES;
}

- (void)enableExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	*/
}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
	/*
	Called by Quartz Composer whenever the plug-in instance needs to execute.
	Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	
	The OpenGL context for rendering can be accessed and defined for CGL macros using:
	CGLContextObj cgl_ctx = [context CGLContextObj];
	*/

	return YES;
}

- (void)disableExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	*/
}

- (void)stopExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	*/
}

@end
