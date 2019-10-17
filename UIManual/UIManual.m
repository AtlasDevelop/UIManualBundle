/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  UIManual.h
 *  UIManual
 *
 */

#import "UIManual.h"
#import "UIManualPlugin.h"

@implementation UIManual

- (void)registerBundlePlugins
{
	[self registerPluginName:@"UIManualPlugin" withPluginCreator:^id<CTPluginProtocol>(){
		return [[UIManualPlugin alloc] init];
	}];
}

@end
