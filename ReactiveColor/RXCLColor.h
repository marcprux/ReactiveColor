//
//  RXCLColor.h
//  ReactiveColor
//
//  Created by Marc Prud'hommeaux on 1/30/14.
//  Copyright (c) 2014 impathic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
@import CoreData;

@interface RXCLColor : NSManagedObject
@property CGFloat red;
@property CGFloat green;
@property CGFloat blue;
@property CGFloat alpha;

/** Returns a signal that forms a UIColor from the rgba components of this object */
- (RACSignal *)colorSignal;

+ (RXCLColor *)createColor;

@end
