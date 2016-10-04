//
//  IAPHelper.h
//  InAppRage
//
//  Created by Ray Wenderlich on 2/28/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"

#define kProductsLoadedNotification         @"ProductsLoaded"
#define kProductPurchasedNotification       @"ProductPurchased"
#define kProductPurchaseFailedNotification  @"ProductPurchaseFailed"
#define kProductRestoreCompletedTransactionsFinished        @"RestoreCompletedTransactionsFinished"
#define kProductRestoreCompletedTransactionsFailedWithError @"RestoreCompletedTransactionsFailedWithError"

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    NSSet * _productIdentifiers;    
    NSArray * _products;
    NSMutableSet * _purchasedProducts;
    SKProductsRequest * _request;
}

@property NSSet *productIdentifiers;
@property NSArray *products;
@property NSMutableSet *purchasedProducts;
@property SKProductsRequest *request;

- (void)requestProducts;
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (BOOL)buyProductIdentifier:(NSString *)productIdentifier;
- (BOOL)productsLoaded;
- (void)restoreCompletedTransactions;
@end
