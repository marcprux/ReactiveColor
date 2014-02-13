//
//  RXCLViewController.h
//  ReactiveColor
//
//  Created by Marc Prud'hommeaux on 1/29/14.
//  Copyright (c) 2014 impathic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RXCLColor.h"

@interface RXCLGradientView : UIView
@end

@interface RXCLViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *canvas;
@property (weak, nonatomic) IBOutlet UITextField *canvasField;
@property (weak, nonatomic) IBOutlet UISlider *slider1;
@property (weak, nonatomic) IBOutlet UISlider *slider2;
@property (weak, nonatomic) IBOutlet UISlider *slider3;
@property (weak, nonatomic) IBOutlet UISlider *slider4;
@property (weak, nonatomic) IBOutlet UITextField *text1;
@property (weak, nonatomic) IBOutlet UITextField *text2;
@property (weak, nonatomic) IBOutlet UITextField *text3;
@property (weak, nonatomic) IBOutlet UITextField *text4;
@property (weak, nonatomic) IBOutlet RXCLGradientView *grad1;
@property (weak, nonatomic) IBOutlet RXCLGradientView *grad2;
@property (weak, nonatomic) IBOutlet RXCLGradientView *grad3;
@property (weak, nonatomic) IBOutlet RXCLGradientView *grad4;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *redoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shuffleButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottom;

- (IBAction)keyboardDidEnd:(id)sender;

@end
