//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//
#import "ReactiveCocoa.h"
#import "RWViewController.h"
#import "RWDummySignInService.h"

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields

    [self.usernameTextField.rac_textSignal subscribeNext:^(id x) {
        
        NSLog(@"当前帐号输入为:%@", x);
    }];
    
//    [[self.passwordTextField.rac_textSignal filter:^BOOL(id value) {
//        NSString *str = value;
//        return [str  isEqual: @"aa"];
//    }] subscribeNext:^(id x) {
//        NSLog(@"新值:%@", x);
//    }];
    
    RACSignal *userSignal = [self.usernameTextField.rac_textSignal map:^id(id value) {
        return @([self isValidUsername:(NSString *)value]);
    }];
    
    RACSignal *password = [self.passwordTextField.rac_textSignal map:^id(id value) {
        return @([self isValidPassword:(NSString *)value]);
    }];
    
    
    RAC(self.usernameTextField, backgroundColor) = [userSignal map:^id(id value) {
        return [value boolValue] ? [UIColor greenColor] : [UIColor redColor];
    }];
    
    RAC(self.passwordTextField, backgroundColor) = [password map:^id(id value) {
        return [value boolValue] ? [UIColor greenColor] : [UIColor redColor];
    }];
    
    RACSignal *signalUpActiveSignal = [RACSignal combineLatest:(@[userSignal, password]) reduce:^id(NSNumber *userNumber, NSNumber *passwordNumber){
       return  @([userNumber boolValue] && [passwordNumber boolValue]);
    }];
    
    [signalUpActiveSignal subscribeNext:^(id x) {
        self.signInButton.enabled = [x boolValue];
    }];
    
    
    [[[[self.signInButton
       rac_signalForControlEvents:UIControlEventTouchUpInside]
      doNext:^(id x){
          self.signInButton.enabled =NO;
          self.signInFailureText.hidden =YES;
      }]
      flattenMap:^id(id x){
          return[self signInSignal];
      }]
     subscribeNext:^(id x){
         self.signInButton.enabled = YES;
         BOOL success =[x boolValue];
         self.signInFailureText.hidden = success;
         NSLog(@"succes is %@", x);
         if(success){
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
     }];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL a) {
            [subscriber sendNext:@(a)];
            [subscriber sendCompleted];
        }];
        
        return nil;
    }];

}

/*
- (IBAction)signInButtonTouched:(id)sender {
  // disable all UI controls
  self.signInButton.enabled = NO;
  self.signInFailureText.hidden = YES;
  
  // sign in
  [self.signInService signInWithUsername:self.usernameTextField.text
                            password:self.passwordTextField.text
                            complete:^(BOOL success) {
                              self.signInButton.enabled = YES;
                              self.signInFailureText.hidden = success;
                              if (success) {
                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
                              }
                            }];
}

*/
// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid

@end
