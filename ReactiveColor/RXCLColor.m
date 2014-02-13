//
//  RXCLColor.m
//  ReactiveColor
//
//  Created by Marc Prud'hommeaux on 1/30/14.
//  Copyright (c) 2014 impathic. All rights reserved.
//

#import "RXCLColor.h"
#import <ReactiveCocoa/RACEXTScope.h>

@implementation RXCLColor

- (RACSignal *)colorSignalFixed {
    return [RACSignal combineLatest:@[
                                      RACObserve(self, red),
                                      RACObserve(self, green),
                                      RACObserve(self, blue),
                                      RACObserve(self, alpha) ]
                             reduce:^(NSNumber *r,
                                      NSNumber *g,
                                      NSNumber *b,
                                      NSNumber *a) {
                                 return [UIColor colorWithRed:r.doubleValue green:g.doubleValue blue:b.doubleValue alpha:a.doubleValue];
                             }];
}

- (RACSignal *)colorSignalDynamic {
    return [[RACSignal combineLatest:@[
                                       RACObserve(self, red),
                                       RACObserve(self, green),
                                       RACObserve(self, blue),
                                       RACObserve(self, alpha) ]
             ] map:^(RACTuple *comps) {
        return [UIColor colorWithRed:[comps[0] doubleValue] green:[comps[1] doubleValue] blue:[comps[2] doubleValue] alpha:[comps[3] doubleValue]];
    }];
}

- (RACSignal *)colorSignal {
    return [self colorSignalDynamic];
}


//+ (RXCLColor *)createColor {
//    return [[RXCLColor alloc] init];
//}


// being a CoreData NSManagerObject instance is only to gain undo support; we use a minimal in-memory persistent store for this

@dynamic red, blue, green, alpha;

+ (RXCLColor *)createColor {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(RXCLColor.class) inManagedObjectContext:[self globalContext]];
}


+ (NSManagedObjectContext *)globalContext {
    static NSManagedObjectContext *globalContext = nil;

    if (globalContext)
        return globalContext;

    NSString *entityName = NSStringFromClass(RXCLColor.class);

    NSEntityDescription *colorEntity = [[NSEntityDescription alloc] init];
    colorEntity.name = colorEntity.managedObjectClassName = entityName;

    NSMutableArray *props = [NSMutableArray array];
    for (NSString *propName in @[ @keypath(RXCLColor.new, red), @keypath(RXCLColor.new, green), @keypath(RXCLColor.new, blue), @keypath(RXCLColor.new, alpha) ]) {
        NSAttributeDescription *attr = [[NSAttributeDescription alloc] init];
        attr.name = propName;
        attr.attributeType = NSDoubleAttributeType;
        [props addObject:attr];
    }
    colorEntity.properties = props;

    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] init];
    mom.entities = @[ colorEntity ];

    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];

    NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    ctx.persistentStoreCoordinator = coordinator;

    return globalContext = ctx;
}

@end
