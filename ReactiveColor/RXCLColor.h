//
//  RXCLColor.h
//  ReactiveColor
//
//  Created by Marc Prud'hommeaux on 1/30/14.
//  MIT License
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
@import CoreData;

/** A 3-component color model that will signal color changes based on the mode (HSB/RGB) */
@interface RXCLColor : NSManagedObject
@property BOOL mode;
@property double color1;
@property double color2;
@property double color3;
@property double alpha;

/** Returns a signal that forms a UIColor from the rgba components of this object */
- (RACSignal *)colorSignal;

/** Creates a new color instance */
+ (RXCLColor *)createColor;

@end
