//
//  ESWelcomeViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "AFNetworking.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "ProgressHUD.h"
#import "ESPageViewController.h"

#import "ESWelcomeViewController.h"
#import "ESLoginViewController.h"
#import "ESSignUpViewController.h"

@implementation ESWelcomeViewController
@synthesize loginButton,signupButton, pageController,arrPageImages,arrPageTitles;
- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([PFUser currentUser]) {
        [[PFUser currentUser] fetchInBackground];
        // Present Netzwierk UI
        [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentTabBarController];
    }else{
    
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] playMusic];

    }
    
    
    arrPageTitles = @[NSLocalizedString(@"Welcome to Sidetone",nil),NSLocalizedString(@"Sidetone allows you to add voice memos to photos and send them to people you know.",nil),NSLocalizedString(@"Start by creating a short profile to help other Sidetoners find you.",nil), NSLocalizedString(@"Have an extra comment? Use the integrated chat system.",nil), NSLocalizedString(@"Worried about data privacy? All Sidetones are backed-up in the cloud.",nil)];
    arrPageImages =@[@"intro_0.png",@"intro_1.png",@"intro_2.png", @"intro_3.png",@"intro_4.png"];
    
    // Create page view controller
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    ESPageViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:startingViewController];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    // Change the size of page view controller
    self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 80);
    [self addChildViewController:self.pageController];
    [self.view addSubview:self.pageController.view];
    [self.pageController didMoveToParentViewController:self];
    for (UIView *subview in self.pageController.view.subviews) {
        if ([subview isKindOfClass:[UIPageControl class]]) {
            UIPageControl *pageControl = (UIPageControl *)subview;
            pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:0.9 alpha:0.6];
            pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
            pageControl.backgroundColor = [UIColor clearColor];
        }
    }
    
    self.title = @"Welcome";
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.view.backgroundColor = [UIColor colorWithRed:0.3412 green:0.6902 blue:0.9294 alpha:1];
    self.loginButton = [[UIButton alloc]init];
    [self.view addSubview:self.loginButton];
    
    self.signupButton = [[UIButton alloc]init];
    [self.view addSubview:self.signupButton];
    [self.signupButton setTitle:NSLocalizedString(@"Sign up", nil) forState:UIControlStateNormal];
    [self.loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    self.signupButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    self.loginButton.titleLabel.textColor = [UIColor whiteColor];
    self.signupButton.titleLabel.textColor = [UIColor whiteColor];
    
    [self.loginButton addTarget:self action:@selector(actionLogin:) forControlEvents:UIControlEventTouchDown];
    [self.signupButton addTarget:self action:@selector(actionRegister:) forControlEvents:UIControlEventTouchDown];
    
    self.loginButton.frame = CGRectMake(20, [UIScreen mainScreen].bounds.size.height - 70, [UIScreen mainScreen].bounds.size.width/2 -30, 50);
    self.loginButton.layer.cornerRadius = 5;
    self.signupButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2 + 10, [UIScreen mainScreen].bounds.size.height - 70, [UIScreen mainScreen].bounds.size.width/2 -30, 50);
    self.signupButton.layer.cornerRadius = 5;
    self.signupButton.backgroundColor = [UIColor colorWithRed:3.0f/255.0f green:201.0f/255.0f blue:169.0f/255.0f alpha:1.0f];
    self.signupButton.titleLabel.textColor = [UIColor whiteColor];
    self.loginButton.backgroundColor = [UIColor colorWithRed:189.0f/255.0f green:195.0f/255.0f blue:199.0f/255.0f alpha:1.0f];
    
    self.loginButton.titleLabel.textColor = [UIColor whiteColor];
    
    
}
- (void) viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.hidden = YES;
}

#pragma mark - User actions
- (IBAction)actionRegister:(id)sender
{
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] stopMusic];

    ESSignUpViewController *registerView = [[ESSignUpViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:registerView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentModalViewController:navigation animated:YES];
    });
    
}

- (IBAction)actionLogin:(id)sender
{
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] stopMusic];

    ESLoginViewController *loginView = [[ESLoginViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:loginView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentModalViewController:navigation animated:YES];
    });
}
#pragma mark - PageViewController data source and delegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = ((ESPageViewController*) viewController).pageIndex;
    if ((index == 0) || (index == NSNotFound))
    {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = ((ESPageViewController*) viewController).pageIndex;
    if (index == NSNotFound)
    {
        return nil;
    }
    index++;
    if (index == [self.arrPageTitles count])
    {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}
- (ESPageViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    if (([self.arrPageTitles count] == 0) || (index >= [self.arrPageTitles count])) {
        return nil;
    }
    ESPageViewController *pageContentViewController = [[ESPageViewController alloc] initWithNibName:@"ESPageViewController" bundle:nil];
    pageContentViewController.imgFile = self.arrPageImages[index];
    pageContentViewController.txtTitle = self.arrPageTitles[index];
    pageContentViewController.pageIndex = index;
    return pageContentViewController;
}

-(NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.arrPageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}
@end
