//
//  ReactiveColorTests.m
//  ReactiveColorTests
//
//  Created by Marc Prud'hommeaux on 1/29/14.
//  Copyright (c) 2014 impathic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RXCLColor.h"


@interface ReactiveColorTests : XCTestCase
@end

@implementation ReactiveColorTests

@end




@interface Product : NSObject
@property (strong) NSString *itemTitle;
@property double itemPrice;
@end

@implementation Product
@end

@interface TraditionalObserver : NSObject
@property (strong) Product *observee;
@property int changeCount;
@end

@implementation TraditionalObserver

- (id)initWithProduct:(Product *)product {
    if (self = [super init]) {
        self.observee = product;
        [product addObserver:self forKeyPath:@"itemTitle" options:0 context:NULL];
        [product addObserver:self forKeyPath:@"itemPrice" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc {
    [self.observee removeObserver:self forKeyPath:@"itemTitle"];
    [self.observee removeObserver:self forKeyPath:@"itemPrice"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSAssert(object == self.observee, @"unexpected observee!");
    self.changeCount++; // remember how many changes take place
    if ([keyPath isEqualToString:@"itemTitle"])
        [self titleDidChange];
    if ([keyPath isEqualToString:@"itemPrice"])
        [self priceDidChange];
}

- (void)titleDidChange {

}

- (void)priceDidChange {

}


@end

@interface ReactiveSnippetsTests : XCTestCase
@end

@implementation ReactiveSnippetsTests

- (void)testTraditionalObservation {
    Product *product = [[Product alloc] init];
    TraditionalObserver *observer = [[TraditionalObserver alloc] initWithProduct:product];
    product.itemTitle = @"Candy Crush Saga";
    product.itemPrice = 0.99;
    NSAssert(observer.changeCount == 2, @"KVO change tracking");

    [product setItemPrice:10.0];
    NSAssert([product itemPrice] == 10.0, @"price via setter");

    product.itemPrice += 5.0;
    NSAssert(product.itemPrice == 15.0, @"price via property");

    [product setValue:@25.0 forKey:@"itemPrice"];
    NSAssert([[product valueForKey:@"itemPrice"] isEqual:@25.0], @"price via KVC");

    NSAssert(observer.changeCount == 5, @"KVO change tracking");
}

- (void)testKVC {
    Product *product = [[Product alloc] init];
    TraditionalObserver *observer = [[TraditionalObserver alloc] initWithProduct:product];

    [product setItemPrice:10.0];
    NSAssert([product itemPrice] == 10.0, @"price via setter");

    product.itemPrice += 5.0;
    NSAssert(product.itemPrice == 15.0, @"price via property");

    [product setValue:@25.0 forKey:@"itemPrice"];
    NSAssert([[product valueForKey:@"itemPrice"] isEqual:@25.0], @"price via KVC");

    NSAssert(observer.changeCount == 3, @"KVO change tracking");
}

- (void)testReactiveObservation {
    Product *product = [[Product alloc] init];

    NSUInteger __block priceChangeCount = 0;
    [RACObserve(product, itemPrice) subscribeNext:^(NSNumber *newPrice) {
        NSLog(@"new price: %@", newPrice);
        priceChangeCount++;
    }];

    NSAssert(priceChangeCount == 1, @"reactive change tracking");
    product.itemPrice = 9.99;
    NSAssert(priceChangeCount == 2, @"reactive change tracking");
}

- (void)testReactiveMacroExpansion {

    Product *product = [[Product alloc] init];

    NSUInteger __block priceChangeCount = 0;

    [RACObserve(product, itemPrice) subscribeNext:^(NSNumber *newPrice) {
        priceChangeCount++;
    }];

    RACSignal *priceSignal = [product rac_valuesForKeyPath:@"itemPrice" observer:self];
    [priceSignal subscribeNext:^(NSNumber *newPrice) {
        priceChangeCount++;
    }];

    NSAssert(priceChangeCount == 2, @"reactive change tracking");
    product.itemPrice = 9.99;
    NSAssert(priceChangeCount == 4, @"reactive change tracking");
}

- (void)testReactiveBindings {

    Product *product = [[Product alloc] init];
    UITextField *textField = [[UITextField alloc] init];

//    RACChannelTo(textField, text) = RACChannelTo(product, itemTitle);
    RACKVOChannel *viewChannel = [[RACKVOChannel alloc] initWithTarget:textField keyPath:@"text" nilValue:nil];
    RACKVOChannel *modelChannel = [[RACKVOChannel alloc] initWithTarget:product keyPath:@"itemTitle" nilValue:nil];
    viewChannel[@"followingTerminal"] = modelChannel[@"followingTerminal"];

    product.itemTitle = @"Paper";
    NSAssert([[textField text] isEqualToString:@"Paper"], @"model to view");

    textField.text = @"Paper++ by Fifty-Eight";
    NSAssert([product.itemTitle isEqualToString:@"Paper++ by Fifty-Eight"], @"view to model");
}

- (void)testSequences {

    NSArray *values = @[ @"red", @"green", @"blue" ];

    NSArray *shortUppercaseColors = [[values filteredArrayUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(NSString *color, NSDictionary *bindings) {
        return [color length] <= 4;
    }]] valueForKeyPath:@"uppercaseString"];

    NSAssert(([shortUppercaseColors isEqualToArray:@[ @"RED", @"BLUE" ]]), @"colors");

    RACSequence *seq = [[values.rac_sequence filter:^BOOL(NSString *color) {
        return [color length] <= 4;
    }] map:^id(NSString *color) {
        return [color uppercaseString];
    }];
    NSAssert(([[seq array] isEqualToArray:@[ @"RED", @"BLUE" ]]), @"colors");


    RACSequence *nums = [RACSequence sequenceWithHeadBlock:^id{
        return @1;
    } tailBlock:^RACSequence *{
        return nil;
    }];

    for (id ob in nums) {
        NSLog(@"seq: %@", ob);
    }
}

- (IBAction)buttonPressed:(id)sender {
    // do something
}

- (void)testUserInterface {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

    button.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
        // do something
        return [RACSignal empty];
    }];
}

@end


