/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  UIManual.h
 *  UIManual
 *
 */

 #import <CoreTestFoundation/CoreTestFoundation.h>

@interface UIManual : CTPluginBaseFactory <CTPluginFactory>

- (void)registerBundlePlugins;

@end