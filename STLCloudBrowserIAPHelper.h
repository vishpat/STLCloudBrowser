//
//  STLCloudBrowserIAPHelper.h
//  STLCloudBrowser
//
//  Created by Vishal Patil on 11/6/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "IAPHelper.h"

@interface STLCloudBrowserIAPHelper : IAPHelper
+ (STLCloudBrowserIAPHelper *) sharedHelper;
+ (BOOL)hasProductBeingPurchased;
- (BOOL)buyProduct;
@end
