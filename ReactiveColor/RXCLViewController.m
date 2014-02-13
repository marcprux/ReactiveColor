//
//  RXCLViewController.m
//  ReactiveColor
//
//  Created by Marc Prud'hommeaux on 1/29/14.
//  Copyright (c) 2014 impathic. All rights reserved.
//

#import "RXCLViewController.h"
#import <ReactiveCocoa/RACEXTScope.h>

@implementation UIColor(RXCLHelper)

/** Return a variation of the current color by setting the comonent index to the given value */
- (UIColor *)colorWithComponent:(NSUInteger)componentIndex value:(CGFloat)value {
    CGColorRef color = [self CGColor];
    CGColorSpaceRef space = CGColorGetColorSpace(color);
    size_t compCount = CGColorSpaceGetNumberOfComponents(space) + 1;
    if (componentIndex >= compCount)
        return nil;

    CGFloat comps[compCount];
    memcpy(comps, CGColorGetComponents(color), sizeof(CGFloat)*compCount);
    comps[componentIndex] = value;

    UIColor *c = [UIColor colorWithCGColor:CGColorCreate(space, comps)];
    return c;
}

@end

/** A view backed by a graident layer that animated changes to the gradient color array */
@implementation RXCLGradientView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    // the colors array of CAGradientLayer doesn't animate by default; this makes it so
    if ([event isEqualToString:@keypath(CAGradientLayer.new, colors)])
        return [CABasicAnimation animationWithKeyPath:event];
    return nil;
}

- (void)setGradientFromColor:(UIColor *)col varyingComponent:(NSUInteger)componentIndex {
    CAGradientLayer *layer = (CAGradientLayer *)self.layer;
    layer.colors = @[
                     (__bridge id)[[col colorWithComponent:componentIndex value:0] CGColor],
                     (__bridge id)[[col colorWithComponent:componentIndex value:1] CGColor] ];

}

@end

@interface RXCLViewController ()
@property RXCLColor *reactiveColor;
@property (strong, readwrite) NSUndoManager *undoManager;
@end

@implementation RXCLViewController
@synthesize undoManager;

- (void)viewDidLoad {
    if ([self isRunningTestCases])
        return;

    [super viewDidLoad];
    [self assignRandomColor];
    [self setupGradientSliderBackgrounds];

    self.reactiveColor = [RXCLColor createColor];

    RXCLColor *model = self.reactiveColor;

    RACSignal *colorSignal = [model colorSignal];

    // the "canvas" background is the current color
    @weakify(self);
    [colorSignal subscribeNext:^(UIColor *color) {
        @strongify(self);
        self.canvas.backgroundColor = color;
    }];

    // the text in the center of the canvas is a hex representation of the color
    [colorSignal subscribeNext:^(UIColor *color) {
        @strongify(self);
        self.canvasField.text = [NSString stringWithFormat:@"#%02X%02X%02X%02X", (int)(model.red*255), (int)(model.green*255), (int)(model.blue*255), (int)(model.alpha*255)];
    }];


    [colorSignal subscribeNext:^(UIColor *color) {
        @strongify(self);
        CGFloat brightness;
        CGFloat alpha;
        [color getHue:NULL saturation:NULL brightness:&brightness alpha:&alpha];
        self.canvasField.textColor = alpha < .5 || brightness >= 0.5 ? [UIColor blackColor] : [UIColor whiteColor];
    }];

    // we also change the view's tint color whenever the model color changes (affects toolbar buttons)
    [colorSignal subscribeNext:^(UIColor *color) {
        @strongify(self);
        self.view.tintColor = [color colorWithAlphaComponent:1];
    }];


    // each slider is bound to the appropriate component of the color
    RACChannelTo(model, red) = [self.slider1 rac_newValueChannelWithNilValue:@0];
    RACChannelTo(model, green) = [self.slider2 rac_newValueChannelWithNilValue:@0];
    RACChannelTo(model, blue) = [self.slider3 rac_newValueChannelWithNilValue:@0];
    RACChannelTo(model, alpha) = [self.slider4 rac_newValueChannelWithNilValue:@0];

    // each text field maps to a component and transforms between percentage text and the numberic value
    NSNumberFormatter *percentage = [[NSNumberFormatter alloc] init];
    percentage.numberStyle = NSNumberFormatterPercentStyle;
    percentage.lenient = YES;
    percentage.maximum = @1;
    percentage.minimum = @0;

    [self bindNumericTerminal:RACChannelTo(model, red) toStringTerminal:[self.text1 rac_newTextChannel] withFormatter:percentage];
    [self bindNumericTerminal:RACChannelTo(model, green) toStringTerminal:[self.text2 rac_newTextChannel] withFormatter:percentage];
    [self bindNumericTerminal:RACChannelTo(model, blue) toStringTerminal:[self.text3 rac_newTextChannel] withFormatter:percentage];
    [self bindNumericTerminal:RACChannelTo(model, alpha) toStringTerminal:[self.text4 rac_newTextChannel] withFormatter:percentage];

    // we can't use rac_newTextChannel because it sends an event on every keystroke!
    [[self.canvasField rac_signalForControlEvents:UIControlEventEditingDidEndOnExit] subscribeNext:^(UITextField *field) {
        NSString *hexString = [field.text stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet]]; // filter non-hex
        NSScanner *scanner = [NSScanner scannerWithString:hexString];

        unsigned long long argbValue = 0;
        [scanner scanHexLongLong:&argbValue];

        // handle both RGBA and RGB hex strings
        if (hexString.length >= 8) {
            model.red = ((argbValue & 0xFF000000) >> 24)/255.0;
            model.green = ((argbValue & 0xFF0000) >> 16)/255.0;
            model.blue = ((argbValue & 0xFF00) >> 8)/255.0;
            model.alpha = (argbValue & 0xFF)/255.0;
        } else {
            model.red = ((argbValue & 0xFF0000) >> 16)/255.0;
            model.green = ((argbValue & 0xFF00) >> 8)/255.0;
            model.blue = (argbValue & 0xFF)/255.0;
        }

    }];

    // adjust the gradients of each slider to show the color that would be set if the relevant component varied
    [colorSignal subscribeNext:^(UIColor *color) {
        @strongify(self);
        [self.grad1 setGradientFromColor:color varyingComponent:0];
        [self.grad2 setGradientFromColor:color varyingComponent:1];
        [self.grad3 setGradientFromColor:color varyingComponent:2];
        [self.grad4 setGradientFromColor:color varyingComponent:3];
    }];

    // compress the views when the keyboard displays
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillChangeFrameNotification object:nil] subscribeNext:^(NSNotification *note) {
        @strongify(self);
        CGRect keyboardBounds = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

        self.toolbarBottom.constant = CGRectGetHeight(self.view.bounds) - CGRectGetMinY(keyboardBounds);
        [self.view setNeedsUpdateConstraints];

        // move the text fields in sync with the keyboard animation

        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:[note.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
        [UIView setAnimationDuration:[note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [self.view layoutIfNeeded];

        [UIView commitAnimations];
    }];

    // setup the done button to appear only when the keyboard is visible
    self.doneButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        [self.view endEditing:YES]; // resigns the other first responders
        return [RACSignal empty];
    }];

    NSArray *toolbarItems = self.toolbar.items;
    [[RACSignal merge:@[
                        [[NSNotificationCenter defaultCenter] rac_addObserverForName:UIWindowDidBecomeKeyNotification object:nil],
                        [[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil],
                        [[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillHideNotification object:nil]]
      ] subscribeNext:^(NSNotification *note) {
        BOOL keyboardShowing = [note.name isEqualToString:UIKeyboardWillShowNotification];
        [self.toolbar setItems:[[toolbarItems.rac_sequence filter:^BOOL(UIBarButtonItem *button) {
            return (button == self.doneButton || button == self.flexSpace3) == keyboardShowing;
        }] array] animated:YES];

    }];

    // add a tap recognizer that adjusts the hue and saturation of the color
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] init];
    [self.canvas addGestureRecognizer:tapper];
    [[tapper rac_gestureSignal] subscribeNext:^(UIPanGestureRecognizer *recognizer) {
        [self.view endEditing:YES];

        UIColor *color = [UIColor colorWithRed:model.red green:model.green blue:model.blue alpha:model.alpha];
        CGFloat hue, sat, bri, alpha;
        [color getHue:&hue saturation:&sat brightness:&bri alpha:&alpha];
        UIView *v = recognizer.view;
        hue = [recognizer locationInView:v].x / (v.bounds.size.width);
        sat = [recognizer locationInView:v].y / (v.bounds.size.height);
        color = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:alpha];
        CGFloat red, green, blue;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        model.red = red;
        model.green = green;
        model.blue = blue;
        model.alpha = alpha;
    }];

    // the shuffle button randomizes the color inside a springy animation block
    self.shuffleButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.4 initialSpringVelocity:1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            @strongify(self);
            [self assignRandomColor];
        } completion:^(BOOL finished) {
        }];

        return [RACSignal empty];
    }];


    NSUndoManager *undo = [[NSUndoManager alloc] init];
    undo.groupsByEvent = YES;
    self.undoManager = self.reactiveColor.managedObjectContext.undoManager = undo;
    [undo endUndoGrouping];
    [undo removeAllActions];

    RACSignal *undoChangedSignal = [[NSNotificationCenter defaultCenter] rac_addObserverForName:NSUndoManagerCheckpointNotification object:undo];

    // undo button performs undo, and is enabled if we are able to undo
    self.undoButton.rac_command = [[RACCommand alloc] initWithEnabled:[undoChangedSignal map:^id(id value) {
        return @([undo canUndo]);
    }] signalBlock:^RACSignal *(id input) {
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [undo undo];
        } completion:^(BOOL finished) {
        }];
        return [RACSignal empty];
    }];

    // redo button performs redo, and is enabled if we are able to redo
    self.redoButton.rac_command = [[RACCommand alloc] initWithEnabled:[undoChangedSignal map:^id(id value) {
        return @([undo canRedo]);
    }] signalBlock:^RACSignal *(id input) {
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [undo redo];
        } completion:^(BOOL finished) {
        }];
        return [RACSignal empty];
    }];


    // batch together slider changes in the undo manager so we have coarse-grained undo; otherwise, each change to the slider would be added as a separate undo event
    for (UISlider *slider in @[ self.slider1, self.slider2, self.slider3, self.slider4] ) {
        [[slider rac_signalForControlEvents:UIControlEventTouchDown] subscribeNext:^(UISlider *slider) {
            [undo beginUndoGrouping];
        }];
        [[slider rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UISlider *slider) {
            [undo endUndoGrouping];
        }];
        [[slider rac_signalForControlEvents:UIControlEventTouchUpOutside] subscribeNext:^(UISlider *slider) {
            [undo endUndoGrouping];
        }];
    }

    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIDeviceOrientationDidChangeNotification object:nil] subscribeNext:^(id x) {
        NSLog(@"rotated: %@", x);
    }];
}

- (void)bindNumericTerminal:(RACChannelTerminal *)numericTerm toStringTerminal:(RACChannelTerminal *)stringTerm withFormatter:(NSNumberFormatter *)formatter {
    [[numericTerm map:^id(NSNumber *value) {
        return [formatter stringFromNumber:value] ?: @"";
    }] subscribe:stringTerm];

    [[stringTerm map:^id(NSString *value) {
        return [formatter numberFromString:value] ?: @0;
    }] subscribe:numericTerm];
}

- (void)assignRandomColor {
    self.reactiveColor.red = drand48();
    self.reactiveColor.blue = drand48();
    self.reactiveColor.green = drand48();
    self.reactiveColor.alpha = drand48();
}

/** Set a nice corner radius for the gradient sliders */
- (void)setupGradientSliderBackgrounds {
    for (CAGradientLayer *layer in @[ self.grad1.layer, self.grad2.layer, self.grad3.layer, self.grad4.layer ]) {
        layer.cornerRadius = 5.0;
        layer.borderWidth = 1.0;
        layer.borderColor = [[UIColor darkGrayColor] CGColor];
        layer.startPoint = CGPointMake(0.0, 0.5);
        layer.endPoint = CGPointMake(1.0, 0.5);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self assignRandomColor];
    [self.undoManager endUndoGrouping];
    [self.undoManager removeAllActions];
}

/** Randomize the color whenever the user shakes the device */
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [UIView animateWithDuration:0.25 animations:^{
            [self assignRandomColor]; // shake to shuffle the colors
        }];
    }
}

/** Sent when the keyboard is not longer used; needed to support automatic keyboard hiding */
- (IBAction)keyboardDidEnd:(id)sender {
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

/** Whether we are currently running test cases; used to skip loading the view controller for test cases */
- (BOOL)isRunningTestCases {
    return [[[NSProcessInfo processInfo] environment][@"XCInjectBundle"] hasSuffix:@"test"];
}

@end
