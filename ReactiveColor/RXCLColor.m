//
//  RXCLColor.m
//  ReactiveColor
//
//  Created by Marc Prud'hommeaux on 1/30/14.
//  MIT License
//

#import "RXCLColor.h"
#import <ReactiveCocoa/RACEXTScope.h>

@implementation RXCLColor

- (RACSignal *)colorSignal {
    return [RACSignal combineLatest:@[
                                      RACObserve(self, mode),
                                      RACObserve(self, color1),
                                      RACObserve(self, color2),
                                      RACObserve(self, color3),
                                      RACObserve(self, alpha) ]
                             reduce:^(NSNumber *m,
                                      NSNumber *c1,
                                      NSNumber *c2,
                                      NSNumber *c3,
                                      NSNumber *a) {
                                 if ([m boolValue])
                                     return [UIColor colorWithHue:c1.doubleValue saturation:c2.doubleValue brightness:c3.doubleValue alpha:a.doubleValue];
                                 else
                                     return [UIColor colorWithRed:c1.doubleValue green:c2.doubleValue blue:c3.doubleValue alpha:a.doubleValue];
                             }];
}

//+ (RXCLColor *)createColor {
//    return [[RXCLColor alloc] init];
//}


// being a CoreData NSManagerObject instance is only to gain undo support; we use a minimal in-memory persistent store for this

@dynamic mode, color1, color2, color3, alpha;

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
    for (NSString *propName in @[ @keypath(RXCLColor.new, mode), @keypath(RXCLColor.new, color1), @keypath(RXCLColor.new, color2), @keypath(RXCLColor.new, color3), @keypath(RXCLColor.new, alpha) ]) {
        NSAttributeDescription *attr = [[NSAttributeDescription alloc] init];
        attr.name = propName;
        attr.attributeType = [propName isEqualToString:@keypath(RXCLColor.new, mode)] ? NSBooleanAttributeType : NSDoubleAttributeType;
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
