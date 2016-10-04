//
//  STLCloudBrowserIAPHelper.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 11/6/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "STLCloudBrowserIAPHelper.h"

#define PRODUCT_ID_CLOUD_VIEWER        @"com.akruty.3dcp.stlviewer"

@implementation STLCloudBrowserIAPHelper
static  STLCloudBrowserIAPHelper* _sharedHelper;

+ (STLCloudBrowserIAPHelper *) sharedHelper {
    
    if (_sharedHelper != nil) {
        return _sharedHelper;
    }
    _sharedHelper = [[STLCloudBrowserIAPHelper alloc] init];
    return _sharedHelper;
    
}

+(int)productCount {
    return _sharedHelper.products ? [_sharedHelper.products count] : 0;
}

- (id)init {
    
    _productIdentifiers = [NSSet setWithObjects:
                           PRODUCT_ID_CLOUD_VIEWER,
                           nil];
    
    if ((self = [super initWithProductIdentifiers:_productIdentifiers])) {
        
    }
    return self;
}

+ (BOOL)hasProductBeingPurchased {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs boolForKey:PRODUCT_ID_CLOUD_VIEWER];
}

-(BOOL)buyProduct {
    return [super buyProductIdentifier:PRODUCT_ID_CLOUD_VIEWER];
}

@end
