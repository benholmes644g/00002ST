//
//  ESEditPhotoViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "ESEditPhotoViewController.h"
#import "ESPhotoDetailsFooterView.h"
#import "UIImage+ResizeAdditions.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "PXAlertView.h"
#import <CoreLocation/CoreLocation.h>
#import "ESShareWithFollowersViewController.h"
#import "AppDelegate.h"
#import "UIImageView+ImageFrame.h"
#import "VLDContextSheetItem.h"
#import "MKInputBoxView.h"
#import "UIViewController+ENPopUp.h"
#import "TOWebViewController.h"
#import <SafariServices/SafariServices.h>
#define UIViewAutoresizingFlexibleMargins                 \
UIViewAutoresizingFlexibleBottomMargin    | \
UIViewAutoresizingFlexibleLeftMargin      | \
UIViewAutoresizingFlexibleRightMargin     | \
UIViewAutoresizingFlexibleTopMargin
@implementation ESEditPhotoViewController
@synthesize scrollView;
@synthesize image;
@synthesize commentTextField;
@synthesize photoFile;
@synthesize thumbnailFile;
@synthesize fileUploadBackgroundTaskId;
@synthesize photoPostBackgroundTaskId;
@synthesize photoImageView;
@synthesize tapGesture,addedAudios,addedAudiosPath;
@synthesize frameSize,contextSheet,longPressPosition;
@synthesize library=_library;
#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (id)initWithImage:(UIImage *)aImage {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (!aImage) {
            return nil;
        }
        
        self.image = aImage;
        self.fileUploadBackgroundTaskId = UIBackgroundTaskInvalid;
        self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
       // self.audio=[[NSMutableArray alloc] init];
        //self.audioPath=[[NSMutableArray alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UIViewController

- (void)loadView {
    self.navigationController.navigationBar.translucent = YES;
    sidetones = [[NSMutableArray alloc] init];
    selectedPin = 1 ;
    self.scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.scrollView.delegate = self;
    self.view = self.scrollView;
    if ([UIScreen mainScreen].bounds.size.height > 500) {
        photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    }
    else {
        photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, -15.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    }
    [photoImageView setBackgroundColor:[UIColor blackColor]];
    [photoImageView setImage:self.image];
    [photoImageView setContentMode:UIViewContentModeScaleAspectFit];

    CALayer *layer = photoImageView.layer;
    layer.masksToBounds = NO;
    layer.shadowRadius = 3.0f;
    layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    layer.shadowOpacity = 0.5f;
    layer.shouldRasterize = YES;
    
    [self.scrollView addSubview:photoImageView];
    
    CGRect footerRect = [ESPhotoDetailsFooterView rectForView];
    footerRect.origin.y = photoImageView.frame.origin.y + photoImageView.frame.size.height;

    footerRect.size.height = 0;//footerRect.size.height + 50;
    
//    ESPhotoDetailsFooterView *footerView = [[ESPhotoDetailsFooterView alloc] initWithFrame:footerRect];
//    self.commentTextField = footerView.commentField;
//    self.commentTextField.delegate = self;
//    [self.scrollView addSubview:footerView];
  //  [footerView.commentField removeFromSuperview]
  //  ;

    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, photoImageView.frame.origin.y + photoImageView.frame.size.height /*+ footerView.frame.size.height*/)];
   // [self loadMarkers];
    
    self.addedAudios =[[NSMutableArray alloc] init];
    self.addedAudiosPath =[[NSMutableArray alloc] init];
    [photoImageView setUserInteractionEnabled:YES];
    UIGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(longPressed:)];
    [self.scrollView addGestureRecognizer: gestureRecognizer];
    [self addContextSheetUI];
   // self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    
   // self.tapGesture.delegate = self;
    
   // [self.view addGestureRecognizer:self.tapGesture];
    
    
    NSArray *components = [[[PFUser currentUser] objectForKey:@"profileColor"] componentsSeparatedByString:@","];
    CGFloat r = [[components objectAtIndex:0] floatValue];
    CGFloat g = [[components objectAtIndex:1] floatValue];
    CGFloat b = [[components objectAtIndex:2] floatValue];
    CGFloat a = [[components objectAtIndex:3] floatValue];
    colorH = [UIColor colorWithHue:204.0f/360.0f saturation:76.0f/100.0f brightness:86.0f/100.0f alpha:1];[UIColor colorWithRed:r green:g blue:b alpha:a];
   // [self addPinSelectButton];
    self.frameSize = [self.photoImageView imageFrame];
}


#pragma -mark context sheet
-(void)addContextSheetUI{
    VLDContextSheetItem *item1 = [[VLDContextSheetItem alloc] initWithTitle: @"Sidetone"
                                                                      image: [UIImage imageNamed: @"pinmich"]
                                                           highlightedImage: [UIImage imageNamed: @"pinmichigh"]];

    VLDContextSheetItem *item2 = [[VLDContextSheetItem alloc] initWithTitle: @"HashTag"
                                                                      image: [UIImage imageNamed: @"pinhash"]
                                                           highlightedImage: [UIImage imageNamed: @"pinhashhigh"]];
    VLDContextSheetItem *item3 = [[VLDContextSheetItem alloc] initWithTitle: @"Link"
                                                                      image: [UIImage imageNamed: @"pinlink"]
                                                           highlightedImage: [UIImage imageNamed: @"pinlinkhigh"]];
    VLDContextSheetItem *item4 = [[VLDContextSheetItem alloc] initWithTitle: @"Facebook"
                                                                      image: [UIImage imageNamed: @"pinfb"]
                                                           highlightedImage: [UIImage imageNamed: @"pinfbhigh"]];
    VLDContextSheetItem *item5 = [[VLDContextSheetItem alloc] initWithTitle: @"Twitter"
                                                                      image: [UIImage imageNamed: @"pintwit"]
                                                           highlightedImage: [UIImage imageNamed: @"pintwithigh"]];
    VLDContextSheetItem *item6 = [[VLDContextSheetItem alloc] initWithTitle: @"WWW"
                                                                      image: [UIImage imageNamed: @"pinurl"]
                                                           highlightedImage: [UIImage imageNamed: @"pinurlhigh"]];
//    VLDContextSheetItem *item4 = [[VLDContextSheetItem alloc] initWithTitle: @"Close"
//                                                                      image: [UIImage imageNamed: @"pin4"]
//                                                           highlightedImage: [UIImage imageNamed: @"pin4"]];
    self.contextSheet = [[VLDContextSheet alloc] initWithItems: @[ item1, item2, item3,item4,item5,item6 ]];
 
    [self.contextSheet setDelegate:self];
}
- (void) longPressed: (UIGestureRecognizer *) sender {

    
    CGPoint location = [sender locationInView:self.scrollView];
    
    self.longPressPosition =[[sender valueForKey:@"_startPointScreen"] CGPointValue];
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        for (UIView *view in self.view.subviews)
        {
            if ([view isKindOfClass:[UIImageView class]] && CGRectContainsPoint(view.frame, location))
            {
               // UIImageView *image = (UIImageView *) view;
                
                        [self.contextSheet startWithGestureRecognizer: sender inView: self.scrollView];
                
                // ok, now you know which image you received your long press for
                // do whatever you wanted on it at this point
                
                return;
            }
        }
    }
}
CGPoint CGRectCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}
- (void) contextSheet: (VLDContextSheet *) contextsheet didSelectItem: (VLDContextSheetItem *) item {
    
    CGPoint point = CGRectCenter(contextsheet.centerView.frame);
     if([item.title isEqualToString:@"Sidetone"]){
        NSLog(@"Selected item: %@", item.title);
         [self addMakerWithInt:5 at:point];

    
    }
    if([item.title isEqualToString:@"HashTag"]){
        
        NSLog(@"Selected item: %@", item.title);
        [self addMakerWithInt:6 at:point];

 
    }
    if([item.title isEqualToString:@"Link"]){
        NSLog(@"Selected item: %@", item.title);
        [self addMakerWithInt:7 at:point];


        
    }
    if([item.title isEqualToString:@"Facebook"]){
       [self addMakerWithInt:8 at:point];
       // [self launchFacebook];

    }
    if([item.title isEqualToString:@"Twitter"]){
        [self addMakerWithInt:9 at:point];
      //  [self launchTwitter];
       
        
    }
    if([item.title isEqualToString:@"WWW"]){
        [self addMakerWithInt:10 at:point];
        //  [self launchTwitter];
        
        
    }
    
    
}
-(void)launchTwitter{

    activeNavbar = 1;
    NSURL *url = [NSURL URLWithString:@"http://twitter.com"];
    navController1 = [[UINavigationController alloc] init];
    webViewController = [[TOWebViewController alloc] initWithURL:url];
    webViewController.hidesBottomBarWhenPushed=YES;
    [webViewController setShowLoadingBar:YES];
    [webViewController setNavigationButtonsHidden:YES];

      [navController1 addChildViewController:webViewController];
    UIWindow *window        = [UIApplication sharedApplication].windows[0];
    CGRect allFrame         = window.frame;
    
    CGRect boxFrame         = CGRectMake(allFrame.size.width/2-MIN(300, window.frame.size.width - 50)/2,
                                         window.frame.size.height/2-300/2,
                                         MIN(300, window.frame.size.width - 50),
                                         300);
    navController1.view.frame = boxFrame;//CGRectMake(0.0, 100.0, 320.0, 426.0);
    navController1.navigationBar.frame = CGRectMake(0.0, 0.0, window.frame.size.width-50.0, 44.0);
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Snap"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(snapshotAction:)];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                   style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    
    
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@""];
    item.rightBarButtonItem = rightButton;
    item.leftBarButtonItem = leftButton;
    item.hidesBackButton = NO;
    webViewController.navigationItem.leftBarButtonItem = leftButton;
    webViewController.navigationItem.rightBarButtonItem = rightButton;


 //    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@""];
//    item.rightBarButtonItem = rightButton;
//    item.leftBarButtonItem = leftButton;
//    item.hidesBackButton = YES;
   // [webViewController.navigationController.navigationBar pushNavigationItem:item animated:NO];

     //[navController.navigationBar addnav:item animated:NO];
    //[navController.view setFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)]
    webViewController.hidesBottomBarWhenPushed = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentPopUpViewController:navController1];
        
        //[self presentViewController:webViewController animated:YES completion:nil];
    });
}
-(void)cancelAction:(id)sender{
    
    switch (activeNavbar) {
        case 0:
            
            //
            break;
            
        case 1:
            [navController1 dismissPopUpViewController] ;
              break;
            
        case 2:
            [navController dismissPopUpViewController];
            //
            break;
            
        case 3:
            [navController2 dismissPopUpViewController];
            //
            break;
            
        default:
            break;
    }
    
    
   // NSUInteger index=[self.addedAudios indexOfObject:sender];
    UIButton *btn = [self.addedAudios lastObject];
   // [self.addedAudios removeObject:btn];
    [self removeMarker:btn];
    
    activeNavbar = 0;
    
    
    
}

-(void)snapshotAction:(id)sender{
    NSString *str = [[NSString alloc] init];

    switch (activeNavbar) {
        case 0:
            
            //
            break;
            
        case 1:
           // str = webViewController.urlRequest.URL.absoluteString;
           str = webViewController.url.absoluteString;// str = [webViewController1.webView stringByEvaluatingJavaScriptFromString:@"window.location"];
            [[self.addedAudiosPath objectAtIndex:activeIndex] setObject:str forKey:@"path"];

            [self captureScreen:webViewController.view];
            
           [navController1 dismissPopUpViewController] ;
            //facebook
            break;
            
        case 2:
             str = webViewController1.url.absoluteString;//str = [webViewController.webView stringByEvaluatingJavaScriptFromString:@"window.location"];
            [[self.addedAudiosPath objectAtIndex:activeIndex] setObject:str forKey:@"path"];
            

            [self captureScreen:webViewController1.view];
             [navController dismissPopUpViewController] ;
            // twitter
            break;
        case 3:
            str = webViewController2.url.absoluteString;//[webViewController2.webView stringByEvaluatingJavaScriptFromString:@"window.location"];
            [[self.addedAudiosPath objectAtIndex:activeIndex] setObject:str forKey:@"path"];
            

//NSString *lURI =[NSSt];// [NSString stringWithFormat:webViewController2.URL.absoluteString];
           // [[self.addedAudiosPath objectAtIndex:activeIndex] setObject:@"loadedURI" forKey:@"path"];
            [self captureScreen:webViewController2.view];
           

            [navController2 dismissPopUpViewController] ;
            // twitter
            break;
            
        default:
            break;
    }
    
    //activeNavbar = 0;
    
    
    
}

-(void)captureScreen:(UIView*) viewToCapture
{
    
//    UIWindow *window        = [UIApplication sharedApplication].windows[0];
//    CGRect allFrame         = window.frame;
    
//    CGRect boxFrame         = CGRectMake(allFrame.size.width/2-MIN(300, window.frame.size.width - 50)/2,
//                                         window.frame.size.height/2-300/2,
//                                         MIN(300, window.frame.size.width - 50),
//                                         300);
   // navController1.view.frame = boxFrame;//CGRectMake(0.0, 100.0, 320.0, 426.0);
   // navController1.navigationBar.frame = CGRectMake(0.0, 0.0, window.frame.size.width-50.0, 44.0);
   // CGRect rect = CGRectMake(viewToCapture.bounds.origin.x, viewToCapture.bounds.origin.y-22.0, viewToCapture.bounds.size.width, viewToCapture.bounds.size.height);
    UIGraphicsBeginImageContext(viewToCapture.bounds.size);
    [viewToCapture.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
     CGRect rect2 = CGRectMake(viewToCapture.bounds.origin.x, viewToCapture.bounds.origin.y+44.00, viewToCapture.bounds.size.width, viewToCapture.bounds.size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([viewImage CGImage], rect2);
    // or use the UIImage wherever you like
    UIImage *viewImage1=[UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    NSLog(@"Captured image size is %f X %f",viewImage.size.width,viewImage.size.height);
   // self.vc.imgSS = viewImage;
    [self saveImageToDirectory:viewImage1];

    
}
- (void)saveImageToDirectory:(UIImage*)saveImg {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
     NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",fileName]];
    UIImage *imagesave = saveImg;//imageView.image; // imageView is my image from camera
    NSData *imageData = UIImagePNGRepresentation(imagesave);
    //[imageData writeToFile:savedImagePath atomically:NO];
    PFFile *file = [PFFile fileWithName:[NSString stringWithFormat:@"%@.png",fileName] data:imageData];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        //
        
         if (succeeded) {
             [[self.addedAudiosPath objectAtIndex:activeIndex] setObject:file forKey:@"img"];
            //

        }
    }];
    /*
     
     [[self.addedAudiosPath objectAtIndex:activeIndex] setObject:value1 forKey:@"img"];

     */
 }
- (void)getImage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,     NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
    UIImage *img = [UIImage imageWithContentsOfFile:getImagePath];
}
-(void)launchFacebook{
    activeNavbar = 2;

    NSURL *url = [NSURL URLWithString:@"https://mbasic.facebook.com/"];
     navController = [[UINavigationController alloc] init];
    webViewController1 = [[TOWebViewController alloc] initWithURL:url];
    [navController addChildViewController:webViewController1];
    webViewController1.hidesBottomBarWhenPushed=YES;
    [webViewController1 setShowLoadingBar:YES];
    [webViewController1 setNavigationButtonsHidden:YES];
    UIWindow *window        = [UIApplication sharedApplication].windows[0];
    CGRect allFrame         = window.frame;
    
    CGRect boxFrame         = CGRectMake(allFrame.size.width/2-MIN(300, window.frame.size.width - 50)/2,
                                         window.frame.size.height/2-300/2,
                                         MIN(300, window.frame.size.width - 50),
                                         300);
    navController.view.frame = boxFrame;//CGRectMake(0.0, 100.0, 320.0, 426.0);
    navController.navigationBar.frame = CGRectMake(0.0, 0.0, window.frame.size.width-50.0, 44.0);
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Snap"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(snapshotAction:)];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                   style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@""];
    item.rightBarButtonItem = rightButton;
    item.leftBarButtonItem = leftButton;
    item.hidesBackButton = NO;
    webViewController1.navigationItem.leftBarButtonItem = leftButton;
    webViewController1.navigationItem.rightBarButtonItem = rightButton;
    //[webViewController.navigationController.navigationBar pushNavigationItem:item animated:NO];
    //[navController.view setFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)]
    webViewController1.hidesBottomBarWhenPushed = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentPopUpViewController:navController];
        
        //[self presentViewController:webViewController animated:YES completion:nil];
    });
}
- (void)loadAddress:(id)sender event:(UIEvent *)event
{
    UITextField *textField = sender;
    NSString* urlString = textField.text;
   // NSString *urlString = @"google.com";
    NSURL *webpageUrl;
    
    if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
        webpageUrl = [NSURL URLWithString:urlString];
    } else {
        webpageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", urlString]];
    }
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:webpageUrl];
    [webViewController2.webView loadRequest:urlRequest];
}

-(void)launchWWW{
    activeNavbar = 3;
    
    NSURL *url = [NSURL URLWithString:@"http://google.com"];
    navController2 = [[UINavigationController alloc] init];
    
    
 
    navController2 = [[UINavigationController alloc] init];
    webViewController2 = [[TOWebViewController alloc] initWithURL:url];
    [navController2 addChildViewController:webViewController2];
    webViewController2.hidesBottomBarWhenPushed=YES;
    [webViewController2 setShowLoadingBar:YES];
    [webViewController2 setNavigationButtonsHidden:YES];
    // webViewController2.showAddressBar = YES;
//    UITextField *addressField = [[UITextField alloc] init];
//    [webViewController2.view addSubview:addressField];
    
                  //  webViewController2.allowHistory = YES;
  //  [webViewController2 setSupportedWebActions:CruiserWebActionNone];
   // webViewController2.showLoadingProgress = YES;
    //[webViewController2 setHidesBottomBarWhenPushed:YES];
    //[[TOWebViewController alloc] initWithURL:url];
    [navController2 addChildViewController:webViewController2];
//    webViewController2.hidesBottomBarWhenPushed=YES;
//    [webViewController2 setShowLoadingBar:YES];
//    [webViewController2 setNavigationButtonsHidden:YES];
//    
    UIWindow *window        = [UIApplication sharedApplication].windows[0];
    CGRect allFrame         = window.frame;
    
    CGRect boxFrame         = CGRectMake(allFrame.size.width/2-MIN(300, window.frame.size.width - 50)/2,
                                         window.frame.size.height/2-300/2,
                                         MIN(300, window.frame.size.width - 50),
                                         300);
    CGRect boxFrame1         = CGRectMake(allFrame.size.width/2-MIN(300, window.frame.size.width - 50)/2,
                                         window.frame.size.height/2-300/2 -22.0,
                                         MIN(300, window.frame.size.width - 50),
                                         300);
    [webViewController2.view setFrame:boxFrame1];
    
    UITextField *textField;// = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, 250, 21.0)];

    
  
     //navController2.navigationItem.titleView = textField;
   // [[navController2 navigationItem] setTitleView:textField];
    navController2.view.frame = boxFrame;//CGRectMake(0.0, 100.0, 320.0, 426.0);
    navController2.navigationBar.frame = CGRectMake(0.0, 0.0, window.frame.size.width-50.0, 44.0);
   // [addressField setFrame:CGRectMake(0.0, 44.0, window.frame.size.width-50.0, 44.0)];
    
    textField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, webViewController2.navigationController.navigationBar.frame.size.width, 21.0)];
    
    [textField addTarget:self action:@selector(loadAddress:event:) forControlEvents:UIControlEventEditingDidEndOnExit];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Snap"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(snapshotAction:)];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                   style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@""];
    item.rightBarButtonItem = rightButton;
    item.leftBarButtonItem = leftButton;
    item.hidesBackButton = NO;
    webViewController2.navigationItem.leftBarButtonItem = leftButton;
    webViewController2.navigationItem.rightBarButtonItem = rightButton;
    webViewController2.navigationItem.titleView = textField;

    //[webViewController.navigationController.navigationBar pushNavigationItem:item animated:NO];
    //[navController.view setFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)]
    webViewController2.hidesBottomBarWhenPushed = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentPopUpViewController:navController2];
        [textField becomeFirstResponder];

        
        //[self presentViewController:webViewController animated:YES completion:nil];
    });
}


-(void)addMakerWithInt:(int)type at:(CGPoint)point{
    UIButton *marker;
    UIImageView *_imageView=self.photoImageView;
    int index;
    if(!marker){
        //[_imageView setUserInteractionEnabled:YES];
        UIImage *pin = [UIImage imageNamed:[NSString stringWithFormat:@"pin%d.png",type]];
        CGRect newrect = CGRectMake(point.x-23, point.y-46, 46, 46);
        
        marker = [[UIButton alloc] initWithFrame:newrect];
        [marker setImage:pin forState:UIControlStateNormal];
        [marker setTag:type];
        
        [marker setEnabled:YES];
        marker.autoresizingMask  = UIViewAutoresizingFlexibleMargins;
        [marker addTarget:self action:@selector(actionMarker:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        
        //   [marker setFrame:CGRectMake(point.x, point.y,30, 49)];
    }
    [_imageView addSubview:marker];
   // [self.addedAudios addObject:marker];
    [self.addedAudios addObject:marker];
    index = (int)[self.addedAudios indexOfObject:marker];
    if(type==5){
    [self performSelector:@selector(launchRecorderView) withObject:nil afterDelay:0.1];
    }
    if(type==8){
        NSMutableDictionary* dict = [self sideToneDictWithType:8 value:@"Facebook"];
        [self.addedAudiosPath addObject:dict];
        [self performSelector:@selector(launchFacebook) withObject:nil afterDelay:0.1];
        activeIndex = index;
    }
    if(type==9){
        NSMutableDictionary* dict = [self sideToneDictWithType:9 value:@"Twitter"];
        [self.addedAudiosPath addObject:dict];
        [self performSelector:@selector(launchTwitter) withObject:nil afterDelay:0.1];
        activeIndex = index;

    }
    if(type==10){
        NSMutableDictionary* dict = [self sideToneDictWithType:10 value:@"WWW"];
        [self.addedAudiosPath addObject:dict];
        [self performSelector:@selector(launchWWW) withObject:nil afterDelay:0.1];
        activeIndex = index;
        
    }

    
    
    if(type==6){

        NSMutableDictionary* dict = [self sideToneDictWithType:6 value:@"Hashtag or Comment"];
        [self.addedAudiosPath addObject:dict];
        MKInputBoxView *inputBoxView = [MKInputBoxView boxOfType:PlainTextInput];
        [inputBoxView setTitle:@"Enter Text"];
        [inputBoxView setMessage:@""];
        [inputBoxView setSubmitButtonText:@"OK"];
        [inputBoxView setCancelButtonText:@"Cancel"];
        inputBoxView.tag=[self.addedAudios indexOfObject:marker];
        inputBoxView.customise = ^(UITextField *textField) {
            textField.placeholder = @"Hashtag or Comment";
            if (textField.secureTextEntry) {
                // textField.placeholder = @"Your password";
            }
            textField.textColor = [UIColor whiteColor];
            textField.layer.cornerRadius = 4.0f;
            textField.tag=index;
            return textField;
        };
        
        inputBoxView.onSubmit = ^(NSString *value1, NSString *value2) {
            NSLog(@"user: %@", value1);
            NSLog(@"pass: %@", value2);
            int selectedIndex = (int)inputBoxView.tag;
            
            [[self.addedAudiosPath objectAtIndex:selectedIndex] setObject:value1 forKey:@"path"];
            return YES;
            //            if ([value1 isValid] && [value2 isValid]){
            //                return YES; // YES to hide the inputBoxView
            //            } else {
            //                return NO; // NO will keep the inputBoxView open
            //            }
        };
        inputBoxView.onCancel = ^{
            NSLog(@"Cancel!");
        };
        [inputBoxView show];
    }
    if(type==7){
        NSMutableDictionary* dict = [self sideToneDictWithType:7 value:@"http://"];
        [self.addedAudiosPath addObject:dict];
        MKInputBoxView *inputBoxView = [MKInputBoxView boxOfType:PlainTextInput];
        [inputBoxView setTitle:@"Enter Url"];
        [inputBoxView setMessage:@""];
        [inputBoxView setSubmitButtonText:@"OK"];
        [inputBoxView setCancelButtonText:@"Cancel"];
        inputBoxView.tag=index;
        inputBoxView.customise = ^(UITextField *textField) {
            textField.placeholder = @"http://";
            if (textField.secureTextEntry) {
                // textField.placeholder = @"Your password";
            }
            textField.textColor = [UIColor whiteColor];
            textField.layer.cornerRadius = 4.0f;
            textField.tag=index;
            return textField;
        };
        
        inputBoxView.onSubmit = ^(NSString *value1, NSString *value2) {
            NSLog(@"user: %@", value1);
            NSLog(@"pass: %@", value2);
            int selectedIndex = (int)inputBoxView.tag;
            
            [[self.addedAudiosPath objectAtIndex:selectedIndex] setObject:value1 forKey:@"path"];
            return YES;
            //            if ([value1 isValid] && [value2 isValid]){
            //                return YES; // YES to hide the inputBoxView
            //            } else {
            //                return NO; // NO will keep the inputBoxView open
            //            }
        };
        inputBoxView.onCancel = ^{
            NSLog(@"Cancel!");
        };
        [inputBoxView show];

     }

}
-(void)addPinSelectButton{
    
    
    UIImage *pin1img = [UIImage imageNamed:[NSString stringWithFormat:@"pin1.png"]];
    
    UIImage *pin2img = [UIImage imageNamed:[NSString stringWithFormat:@"pin2.png"]];
    
    UIImage *pin3img = [UIImage imageNamed:[NSString stringWithFormat:@"pin3.png"]];
    
    UIImage *pin4img = [UIImage imageNamed:[NSString stringWithFormat:@"pin4.png"]];
    float Y_Co = self.view.frame.size.height - 92;
    float X_Co = self.view.frame.size.width;
    
    UIStackView *stack = [[UIStackView alloc] init];
    [stack setFrame: CGRectMake(0 , Y_Co, X_Co, 46)];
    [self.view addSubview:stack];
    [stack setAxis:UILayoutConstraintAxisHorizontal];
    [stack setDistribution:UIStackViewDistributionFillEqually];
    [stack setAlignment:UIStackViewAlignmentCenter];
    pin1 = [[UIButton alloc] init];
    [pin1 setImage:pin1img forState:UIControlStateNormal];
    pin1.tag = 1;
    [pin1 addTarget:self action:@selector(updatePin:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:pin1];
    
    
    pin2 = [[UIButton alloc] init];
    [pin2 setImage:pin2img forState:UIControlStateNormal];
    pin2.tag = 2;
    
    [pin2 addTarget:self action:@selector(updatePin:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:pin2];
    
    
    pin3 = [[UIButton alloc] init];
    [pin3 setImage:pin3img forState:UIControlStateNormal];
    pin3.tag = 3;
    
    [pin3 addTarget:self action:@selector(updatePin:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:pin3];
    
    pin4 = [[UIButton alloc] init];
    [pin4 setImage:pin4img forState:UIControlStateNormal];
    pin4.tag = 4;
    //
    [pin4 addTarget:self action:@selector(updatePin:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:pin4];
    selectedPin = 1 ;
    [pin1 setHighlighted:YES];
    
    [pin2 setHighlighted:NO];
    
    [pin3 setHighlighted:NO];
    
    [pin4 setHighlighted:NO];
    [pin1 setBackgroundColor:colorH];
    [pin2 setBackgroundColor:[UIColor whiteColor]];
    
    [pin3 setBackgroundColor:[UIColor whiteColor]];
    
    [pin4 setBackgroundColor:[UIColor whiteColor]];
    
}
-(void)updatePin:(id)sender{
    UIButton *btn = sender;
    int tag=(int)btn.tag;
    switch (tag) {
        case 1:
            //
            selectedPin = 1 ;
            [pin1 setHighlighted:YES];
            
            [pin2 setHighlighted:NO];
            
            [pin3 setHighlighted:NO];
            
            [pin4 setHighlighted:NO];
            [pin1 setBackgroundColor:colorH];
            [pin2 setBackgroundColor:[UIColor whiteColor]];
            
            [pin3 setBackgroundColor:[UIColor whiteColor]];
            
            [pin4 setBackgroundColor:[UIColor whiteColor]];
            
            break;
            
        case 2:
            //
            selectedPin = 2 ;
            [pin1 setHighlighted:NO];
            
            [pin2 setHighlighted:YES];
            
            [pin3 setHighlighted:NO];
            
            [pin4 setHighlighted:NO];
            [pin1 setBackgroundColor:[UIColor whiteColor]];
            [pin2 setBackgroundColor:colorH];
            
            [pin3 setBackgroundColor:[UIColor whiteColor]];
            
            [pin4 setBackgroundColor:[UIColor whiteColor]];
            break;
            
        case 3:
            //
            selectedPin = 3 ;
            [pin1 setHighlighted:NO];
            
            [pin2 setHighlighted:NO];
            
            [pin3 setHighlighted:YES];
            
            [pin4 setHighlighted:NO];
            [pin1 setBackgroundColor:[UIColor whiteColor]];
            [pin2 setBackgroundColor:[UIColor whiteColor]];
            
            [pin3 setBackgroundColor:colorH];
            
            [pin4 setBackgroundColor:[UIColor whiteColor]];
            
            break;
            
        case 4:
            //
            selectedPin = 4 ;
            [pin1 setHighlighted:NO];
            
            [pin2 setHighlighted:NO];
            
            [pin3 setHighlighted:NO];
            
            [pin4 setHighlighted:YES];
            [pin1 setBackgroundColor:[UIColor whiteColor]];
            [pin2 setBackgroundColor:[UIColor whiteColor]];
            
            [pin3 setBackgroundColor:[UIColor whiteColor]];
            
            [pin4 setBackgroundColor:colorH];
            
            break;
            
        default:
            selectedPin = 1 ;
            selectedPin = 1 ;
            [pin1 setHighlighted:YES];
            
            [pin2 setHighlighted:NO];
            
            [pin3 setHighlighted:NO];
            
            [pin4 setHighlighted:NO];
            [pin1 setBackgroundColor:colorH];
            [pin2 setBackgroundColor:[UIColor whiteColor]];
            
            [pin3 setBackgroundColor:[UIColor whiteColor]];
            
            [pin4 setBackgroundColor:[UIColor whiteColor]];
            
            
            break;
    }
    
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }
    return YES; // handle the touch
}
- (void)handleSingleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    UIImageView *_imageView=self.photoImageView;
    
    CGPoint point = [tapGestureRecognizer locationInView:_imageView];
    // float squareSize = 10;
    CGRect imgBox=[_imageView imageFrame];
    if(!CGRectContainsPoint(imgBox, point)){
        return; // tap somewhere else
    }
    UIButton *marker;
    if(!marker){
        [_imageView setUserInteractionEnabled:YES];
        UIImage *pin = [UIImage imageNamed:[NSString stringWithFormat:@"pin%d.png",selectedPin]];
        CGRect newrect = CGRectMake(point.x-23, point.y-46, 46, 46);
        
        marker = [[UIButton alloc] initWithFrame:newrect];
        [marker setImage:pin forState:UIControlStateNormal];
        [marker setTag:selectedPin];
        [marker setEnabled:YES];
        marker.autoresizingMask  = UIViewAutoresizingFlexibleMargins;
        [marker addTarget:self action:@selector(removeMarker:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        
        //   [marker setFrame:CGRectMake(point.x, point.y,30, 49)];
    }
    [_imageView addSubview:marker];
    [self.addedAudios addObject:marker];
    
    
       [self performSelector:@selector(launchRecorderView) withObject:nil afterDelay:0.1];
}
-(void)actionMarker:(id)sender{
    int type = (int)[sender tag];
    int index =   (int)[self.addedAudios indexOfObject:sender];

    NSString *placeholder = [NSString stringWithFormat:@"%@",[[self.addedAudiosPath objectAtIndex:index] valueForKey:@"path"]];
    if(type == 5){ // audo added
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Remove Audio" message:@"Press OK to delete" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self removeMarkerConfirm:sender];
        
    }]];
    
    //  [alertController addAction:[UIAlertAction actionWithTitle:@"Button 2" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    // [self loadDropBox];
    //  }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self closeAlertview];
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertController animated:YES completion:nil];
    });
    }
    if(type == 6){ // text added
        
        MKInputBoxView *inputBoxView = [MKInputBoxView boxOfType:PlainTextInput];
        [inputBoxView setTitle:@"Enter Text"];
        [inputBoxView setMessage:@""];
        [inputBoxView setSubmitButtonText:@"OK"];
        [inputBoxView setCancelButtonText:@"Cancel"];
        inputBoxView.tag=index;
        inputBoxView.customise = ^(UITextField *textField) {
            textField.placeholder = placeholder;
            if (textField.secureTextEntry) {
               // textField.placeholder = @"Your password";
            }
            textField.textColor = [UIColor whiteColor];
            textField.layer.cornerRadius = 4.0f;
            textField.tag=index;
            return textField;
        };
        
        inputBoxView.onSubmit = ^(NSString *value1, NSString *value2) {
            NSLog(@"user: %@", value1);
            NSLog(@"pass: %@", value2);
            int selectedIndex = (int)inputBoxView.tag;
            
            [[self.addedAudiosPath objectAtIndex:selectedIndex] setObject:value1 forKey:@"path"];
            return YES;
//            if ([value1 isValid] && [value2 isValid]){
//                return YES; // YES to hide the inputBoxView
//            } else {
//                return NO; // NO will keep the inputBoxView open
//            }
        };
        inputBoxView.onCancel = ^{
            NSLog(@"Cancel!");
        };
        [inputBoxView show];
//        UIAlertView *alrt=[[UIAlertView alloc]initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
//        alrt.alertViewStyle = UIAlertViewStylePlainTextInput;
//        
//        [[alrt textFieldAtIndex:0] setPlaceholder:placeholder];
//        alertText = [alrt textFieldAtIndex:0];
//        alertText.keyboardType = UIKeyboardTypeTwitter;
//        alertText.delegate=self;
//        alertText.tag=index;
//
//        alrt.tag=100;
//        [alrt show];
        
    }
    if(type == 7){ // hyper link added
        MKInputBoxView *inputBoxView = [MKInputBoxView boxOfType:PlainTextInput];
        [inputBoxView setTitle:@"Enter Url"];
        [inputBoxView setMessage:@""];
        [inputBoxView setSubmitButtonText:@"OK"];
        [inputBoxView setCancelButtonText:@"Cancel"];
        inputBoxView.tag=index;
        inputBoxView.customise = ^(UITextField *textField) {
            textField.placeholder = placeholder;
            if (textField.secureTextEntry) {
                // textField.placeholder = @"Your password";
            }
            textField.textColor = [UIColor whiteColor];
            textField.layer.cornerRadius = 4.0f;
            textField.tag=index;
            return textField;
        };
        
        inputBoxView.onSubmit = ^(NSString *value1, NSString *value2) {
            NSLog(@"user: %@", value1);
            NSLog(@"pass: %@", value2);
            int selectedIndex = (int)inputBoxView.tag;
            
            [[self.addedAudiosPath objectAtIndex:selectedIndex] setObject:value1 forKey:@"path"];
            return YES;
            //            if ([value1 isValid] && [value2 isValid]){
            //                return YES; // YES to hide the inputBoxView
            //            } else {
            //                return NO; // NO will keep the inputBoxView open
            //            }
        };
        inputBoxView.onCancel = ^{
            NSLog(@"Cancel!");
        };
        [inputBoxView show];
//        UIAlertView *alrt=[[UIAlertView alloc]initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
//        alrt.alertViewStyle = UIAlertViewStylePlainTextInput;
//        [[alrt textFieldAtIndex:0] setPlaceholder:placeholder];
//        alertUrl = [alrt textFieldAtIndex:0];
//        alertUrl.tag=index;
//        alertUrl.keyboardType = UIKeyboardTypeURL;
//        alertUrl.delegate=self;
//        alrt.tag=101;
//        [alrt show];
    }

    
}
-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(alertText.text.length >= 40 && range.length == 0) {
        return NO;
        
    }
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100){
    if (buttonIndex == 1) {
        NSString *value = [alertView textFieldAtIndex:0].text;
        // name contains the entered value
        int selectedIndex = (int)[[alertView textFieldAtIndex:0] tag];
        
        [[self.addedAudiosPath objectAtIndex:selectedIndex] setObject:value forKey:@"path"];
    }
    }
    
    
    if(alertView.tag == 101){
        if (buttonIndex == 1) {
            NSString *value = [alertView textFieldAtIndex:0].text;
            // name contains the entered value
            int selectedIndex = (int)[[alertView textFieldAtIndex:0] tag];
            
            [[self.addedAudiosPath objectAtIndex:selectedIndex] setObject:value forKey:@"path"];
        }
    }
}

-(void)removeMarker:(id)sender{
    [self removeMarkerConfirm:sender];
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Remove Audio" message:@"Press OK to delete" preferredStyle:UIAlertControllerStyleAlert];
//    
//    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [self removeMarkerConfirm:sender];
//        
//    }]];
//    
//    //  [alertController addAction:[UIAlertAction actionWithTitle:@"Button 2" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//    // [self loadDropBox];
//    //  }]];
//    
//    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [self closeAlertview];
//    }]];
//    
//    dispatch_async(dispatch_get_main_queue(), ^ {
//        [self presentViewController:alertController animated:YES completion:nil];
//    });
    
    
    
}
-(void)removeMarkerConfirm:(id)sender{
    
    NSUInteger index=[self.addedAudios indexOfObject:sender];
    [self.addedAudios removeObject:sender];
    if([self.addedAudiosPath count]>index){
        
        [self.addedAudiosPath removeObjectAtIndex:index];
    }
    [sender removeFromSuperview];
    
    //[self closeAlertview];
    
}
-(void)closeAlertview
{
    
    // [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)launchRecorderView{
    IQAudioRecorderController *controller = [[IQAudioRecorderController alloc] init];
    controller.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentPopUpViewController:controller];
       // [self presentViewController:controller animated:YES completion:nil];
    });
}
# pragma mark - IQAudioRecorderController delegates

-(NSMutableDictionary *)sideToneDictWithType:(int)type value:(NSString *)value{
    
    NSString * typeStr;
     NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if(type == 5){
        typeStr=[NSString stringWithFormat:@""];
        [dict setValue:typeStr forKey:@"type"];
        [dict setValue:value forKey:@"path"];
    }
    if(type == 6){
        typeStr=[NSString stringWithFormat:@""];
        [dict setValue:typeStr forKey:@"type"];
        [dict setValue:value forKey:@"path"];
    }
    if(type == 7){
        typeStr=[NSString stringWithFormat:@""];
        [dict setValue:typeStr forKey:@"type"];
        [dict setValue:value forKey:@"path"];
    }
    if(type == 8){
        typeStr=[NSString stringWithFormat:@""];
        [dict setValue:typeStr forKey:@"type"];
        [dict setValue:@"" forKey:@"path"];
    }
    if(type == 9){
        typeStr=[NSString stringWithFormat:@""];
        [dict setValue:typeStr forKey:@"type"];
        [dict setValue:@"" forKey:@"path"];
    }
    if(type == 10){
        typeStr=[NSString stringWithFormat:@""];
        [dict setValue:typeStr forKey:@"type"];
        [dict setValue:@"" forKey:@"path"];
    }
   
    
    
    return dict;
}
- (void)audioRecorderController:(IQAudioRecorderController *)controller didFinishWithAudioAtPath:(NSString *)path {
    NSMutableDictionary* dict = [self sideToneDictWithType:5 value:path];
    [self.addedAudiosPath addObject:dict];
    //  [self sendMessage:nil withPicture:nil withVideo:nil andWithAudio:path];
}
- (void)audioRecorderControllerDidCancel:(IQAudioRecorderController *)controller {
    
    id sender = [self.addedAudios lastObject];
    
    [self removeMarkerConfirm:sender];
    
}

//-(void)loadMarkers{
//    
//    
//    float yoffSet;
//    float xoffSet;
//    CGRect imageFrame = [self.photoImageView imageFrame];
//    yoffSet = (imageFrame.size.height-self.imgViewFrmSize.size.height)/2;
//    xoffSet = (imageFrame.size.width-self.imgViewFrmSize.size.width)/2;
//    
//    
//    if([self.audio count]>0)
//    {
//        int i=0;
//    for(id marker in self.audio)
//    {
//        
//        UIButton *button= marker;
//        [button setAdjustsImageWhenHighlighted:NO];
//        [button setFrame:CGRectMake(button.frame.origin.x + xoffSet, button.frame.origin.y+yoffSet, button.frame.size.width, button.frame.size.height)];
//        
//        [self.photoImageView addSubview:button];
//        NSString *rect= NSStringFromCGRect(button.frame);
//        NSString *audioPathStr=[self.audioPath objectAtIndex:i];
//        NSInteger index=button.tag;
//        int pinI = (int)index;
//        NSString *pin=[NSString stringWithFormat:@"%d",pinI];
//        NSString *rectFrame = NSStringFromCGRect(imageFrame);
//        NSDictionary *sideToneData=[[NSMutableDictionary alloc] initWithObjectsAndKeys:rect,@"rect",audioPathStr,@"audio" ,rectFrame,@"frame",pin,@"pin",nil];
//       
//        [sidetones addObject:sideToneData];
//        
//        i++;
//        
//        
//        
//    }
//    }
//
//}
- (void)viewDidLoad {
    [super viewDidLoad];
    doneButtonCalled=NO;
    _library = [[ALAssetsLibrary alloc] init];
    self.view.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];;
    [self.navigationItem setHidesBackButton:YES];
    self.navigationItem.titleView = nil;//[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonAction:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", nil) style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonAction:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self shouldUploadImage:self.image];
    
    locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.distanceFilter = kCLDistanceFilterNone;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
#ifdef __IPHONE_8_0
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
#endif
    [locationManager startUpdatingLocation];

}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self doneButtonAction:textField];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    //[self.commentTextField resignFirstResponder];
}


#pragma mark - ()
- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
}

-(void)saveImage:(UIImage *)anImage{
   [self.library saveImage:anImage toAlbum:@"Sidetones" withCompletionBlock:^(NSError *error) {
       //
   }];
}
- (BOOL)shouldUploadImage:(UIImage *)anImage {
    UIImage *resizedImage = [anImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    UIImage *thumbnailImage = [anImage thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:42.0f interpolationQuality:kCGInterpolationDefault];
    
    // JPEG to decrease file size and enable faster uploads & downloads
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
    NSData *thumbnailImageData = UIImagePNGRepresentation(thumbnailImage);
    
    if (!imageData || !thumbnailImageData) {
        return NO;
    }
    
    self.photoFile = [PFFile fileWithData:imageData];
    self.thumbnailFile = [PFFile fileWithData:thumbnailImageData];

    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
    self.fileUploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
    }];
    
    [self.photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
            }];
        } else {
            [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
        }
    }];
    
    return YES;
}


- (void)keyboardWillShow:(NSNotification *)note {
    CGRect keyboardFrameEnd = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize scrollViewContentSize = self.scrollView.bounds.size;
    scrollViewContentSize.height += keyboardFrameEnd.size.height;
    [self.scrollView setContentSize:scrollViewContentSize];
    
    CGPoint scrollViewContentOffset = self.scrollView.contentOffset;
    // Align the bottom edge of the photo with the keyboard
    scrollViewContentOffset.y = scrollViewContentOffset.y + keyboardFrameEnd.size.height*3.0f - [UIScreen mainScreen].bounds.size.height;
    
    [self.scrollView setContentOffset:scrollViewContentOffset animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)note {
    CGRect keyboardFrameEnd = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize scrollViewContentSize = self.scrollView.bounds.size;
    scrollViewContentSize.height -= keyboardFrameEnd.size.height;
    [UIView animateWithDuration:0.200f animations:^{
        [self.scrollView setContentSize:scrollViewContentSize];
    }];
}

- (void)doneButtonAction:(id)sender {
    if(!doneButtonCalled){
    
        doneButtonCalled=YES;
    }else{
        return;
    }
    NSDictionary *userInfo = [NSDictionary dictionary];
    NSString *trimmedComment = @"";[self.commentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmedComment.length != 0) {
      //  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
       //                           trimmedComment,kESEditPhotoViewControllerUserInfoCommentKey,
       //                           nil];
    }
    
    // Make sure there were no errors creating the image files
    if (!self.photoFile || !self.thumbnailFile) {
        [PXAlertView showAlertWithTitle:nil
                                message:NSLocalizedString(@"Couldn't post your photo, a network error occurred.", nil)
                            cancelTitle:@"OK"
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (cancelled) {
                                     NSLog(@"Simple Alert View cancelled");
                                 } else {
                                     NSLog(@"Simple Alert View dismissed, but not cancelled");
                                 }
                             }];
        return;
    }
    
    // both files have finished uploading
    
    // create a photo object
    PFObject *photo = [PFObject objectWithClassName:kESPhotoClassKey];
    photo[@"permission"] = @"private";
    [photo setObject:[PFUser currentUser] forKey:kESPhotoUserKey];
    [photo setObject:self.photoFile forKey:kESPhotoPictureKey];
    //[photo setObject:@"private" forKey:kESPhotoPermission];
    [photo setObject:self.thumbnailFile forKey:kESPhotoThumbnailKey];
    if (localityString && [[[PFUser currentUser] objectForKey:@"locationServices"] isEqualToString:@"YES"]) {
        [photo setObject:localityString forKey:kESPhotoLocationKey];
    }
    
    // photos are public, but may only be modified by the user who uploaded them
    PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [photoACL setPublicReadAccess:YES];
    [photoACL setPublicWriteAccess:YES]; // forUser:[PFUser currentUser]];
    photo.ACL = photoACL;
    
    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
    self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
    }];

    // Save the Photo PFObject
    [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [[ESCache sharedCache] setAttributesForPhoto:photo likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];
            
            if ([[[[PFUser currentUser] objectForKey:@"verified"] lowercaseString] isEqualToString:@"yes"]) {
                PFObject *sponsored = [PFObject objectWithClassName:@"Sponsored"];
                [sponsored setObject:self.photoFile forKey:kESPhotoPictureKey];
                [sponsored setObject:self.thumbnailFile forKey:kESPhotoThumbnailKey];
                [sponsored setObject:[PFUser currentUser] forKey:kESPhotoUserKey];
                [sponsored saveInBackground];
            }
            
            // userInfo might contain any caption which might have been posted by the uploader
            if (userInfo) {
                NSString *commentText = [userInfo objectForKey:kESEditPhotoViewControllerUserInfoCommentKey];
                
                if (commentText && commentText.length != 0) {
                    // create and save photo caption
                    NSRegularExpression *_regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:nil];
                    NSArray *_matches = [_regex matchesInString:trimmedComment options:0 range:NSMakeRange(0, trimmedComment.length)];
                    NSMutableArray *hashtagsArray = [[NSMutableArray alloc]init];
                    for (NSTextCheckingResult *match in _matches) {
                        NSRange wordRange = [match rangeAtIndex:1];
                        NSString* word = [trimmedComment substringWithRange:wordRange];
                        [hashtagsArray addObject:[word lowercaseString]];
                    }
                    
                    PFObject *comment = [PFObject objectWithClassName:kESActivityClassKey];
                    if ([photo objectForKey:kESVideoFileKey]) {
                        [comment setObject:kESActivityTypeCommentVideo forKey:kESActivityTypeKey];
                    } else if ([[photo objectForKey:@"type"] isEqualToString:@"text"]) {
                        [comment setObject:kESActivityTypeCommentPost forKey:kESActivityTypeKey];
                    }
                    else [comment setObject:kESActivityTypeCommentPhoto forKey:kESActivityTypeKey];
                    [comment setObject:photo forKey:kESActivityPhotoKey];
                    [comment setObject:[PFUser currentUser] forKey:kESActivityFromUserKey];
                    [comment setObject:[PFUser currentUser] forKey:kESActivityToUserKey];
                    [comment setObject:commentText forKey:kESActivityContentKey];
                    if (hashtagsArray.count > 0) {
                        [comment setObject:hashtagsArray forKey:@"hashtags"];
                        
                        for (int i = 0; i < hashtagsArray.count; i++) {
                            NSString *hash = [[hashtagsArray objectAtIndex:i] lowercaseString];
                            PFQuery *hashQuery = [PFQuery queryWithClassName:@"Hashtags"];
                            [hashQuery whereKey:@"hashtag" equalTo:hash];
                            [hashQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                                if (!error) {
                                    if (objects.count == 0) {
                                        PFObject *hashtag = [PFObject objectWithClassName:@"Hashtags"];
                                        [hashtag setObject:hash forKey:@"hashtag"];
                                        [hashtag saveInBackground];
                                    }
                                }
                            }];
                        }
                    }

                    PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
                    [ACL setPublicReadAccess:YES];
                    [ACL setWriteAccess:YES forUser:[PFUser currentUser]];
                    comment.ACL = ACL;
                    
                    [comment saveInBackgroundWithBlock:^(BOOL result, NSError *error){
                        if (error) {
                            [comment saveEventually];
                        }
                    }];
                    [[ESCache sharedCache] incrementCommentCountForPhoto:photo];
                    
                    PFObject *mention = [PFObject objectWithClassName:kESActivityClassKey];
                    [mention setObject:[PFUser currentUser] forKey:kESActivityFromUserKey]; // Set fromUser
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:nil];
                    NSArray *matches = [regex matchesInString:trimmedComment options:0 range:NSMakeRange(0, trimmedComment.length)];
                    NSMutableArray *mentionsArray = [[NSMutableArray alloc]init];
                    for (NSTextCheckingResult *match in matches) {
                        NSRange wordRange = [match rangeAtIndex:1];
                        NSString* word = [trimmedComment substringWithRange:wordRange];
                        [mentionsArray addObject:word];
                        
                        
                    }
                    if (mentionsArray.count > 0 ) {
                        PFQuery *mentionQuery = [PFUser query];
                        [mentionQuery whereKey:@"usernameFix" containedIn:mentionsArray];
                        [mentionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            if (!error) {
                                [mention setObject:objects forKey:@"mentions"]; // Set toUser
                                [mention setObject:kESActivityTypeMention forKey:kESActivityTypeKey];
                                [mention setObject:photo forKey:kESActivityPhotoKey];
                                [mention saveInBackgroundWithBlock:^(BOOL result, NSError *error){
                                    if (error) {
                                        [mention saveEventually];
                                    }
                                }];
                            }
                        }];
                    }
                }
            }
            
            // publish sidetones
            UIImage * imageDefault=[UIImage imageWithData:[self.photoFile getData]];// Some image you want to send
            
            NSString * docDirWithSlash = [[self applicationDocumentsDirectory] stringByAppendingString:@"/Sidetones/"];
            NSString * pngFile = [docDirWithSlash stringByAppendingString:[photo objectId ]]; // <-- Change the string "file" to reflect the name you want.
            NSString * pngFileName= [NSString stringWithFormat:@"%@.png",pngFile];

            [UIImagePNGRepresentation(imageDefault) writeToFile:pngFileName atomically:YES];
           // UIImage *imagetosave=[UIImage imageWithContentsOfFile:pngFile];
           // [imagetosave setAccessibilityIdentifier:[photo objectId ]];
            //[self saveImage:imagetosave];
            [self publishNewMarkers:[photo objectId]];
           // [[STParseHelper sharedInstance] publishSideToneData:[sidetones copy] withPhotoId:[;photo objectId]];
            [[NSNotificationCenter defaultCenter] postNotificationName:ESTabBarControllerDidFinishEditingPhotoNotification object:photo];
        } else {
            [PXAlertView showAlertWithTitle:nil
                                    message:NSLocalizedString(@"Couldn't post your photo, a network error occurred.", nil)
                                cancelTitle:@"OK"
                                 completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                     if (cancelled) {
                                         NSLog(@"Simple Alert View cancelled");
                                     } else {
                                         NSLog(@"Simple Alert View dismissed, but not cancelled");
                                     }
                                 }];
        }
        
        
        
        //
        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
    }];
    
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];

//    ESShareWithFollowersViewController *shareWithView = [[ESShareWithFollowersViewController alloc] initWithStyle:UITableViewStyleGrouped andOption:@"Send To" andUser:[PFUser currentUser]];
//    shareWithView.photo = photo;

   // [self.navigationController pushViewController:shareWithView animated:YES];
    
    
//    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray: self.navigationController.viewControllers];
//    [viewControllers removeObjectIdenticalTo:self];
//    [viewControllers addObject:shareWithView];
//    [self.navigationController setViewControllers: viewControllers animated: YES];
//    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

 [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharephoto:photo];
   //  Dismiss this screen
   
   
 //   [self.parentViewController dismissViewControllerAnimated:YES completion:nil];

    
    
   // [self.parentViewController ]
    doneButtonCalled=NO;
}
-(void)publishNewMarkers:(NSString *)photoid{
    NSMutableArray *sidetones_=[[NSMutableArray alloc] init];
    
    float yoffSet;
    
    // yoffSet = (self.photoImageView.frame.size.height-imgViewFrmSize.size.height)/2;
    
    
    if([self.addedAudios count]>0)
    {
        int i=0;
        for(id marker in self.addedAudios)
        {
            
            UIButton *button= marker;
            //  edfd
            //[button setAdjustsImageWhenHighlighted:NO];
            //[button setFrame:CGRectMake(button.frame.origin.x, button.frame.origin.y+yoffSet, button.frame.size.width, button.frame.size.height)];
            
            //[self.photoImageView addSubview:button];
            NSString *rect= NSStringFromCGRect(button.frame);
            NSString *audioPathStr=[[self.addedAudiosPath objectAtIndex:i] valueForKey:@"path"];
            PFFile *imgFile;//[[self.addedAudiosPath objectAtIndex:i] valueForKey:@"img"];

            
            NSInteger index=button.tag;
            int pinI = (int)index;
            if(pinI == 8 || pinI == 9|| pinI == 10){
            imgFile = [[self.addedAudiosPath objectAtIndex:i] valueForKey:@"img"];
            }
            NSString *pin=[NSString stringWithFormat:@"%d",pinI];
            NSString *rectFrame =NSStringFromCGRect(self.frameSize);// NSStringFromCGRect(self.headerView.photoImageView.frame);
            NSDictionary *sideToneData=[[NSMutableDictionary alloc] initWithObjectsAndKeys:rect,@"rect",audioPathStr,@"audio" ,rectFrame,@"frame",pin,@"pin",imgFile,@"img",nil];
            
            [sidetones_ addObject:sideToneData];
            
            i++;
            
            
            
        }
    }
    if(sidetones_)
    {
        //publish
        [[STParseHelper sharedInstance] publishSideToneData:[sidetones_ copy] withPhotoId:photoid];
        
        [self.addedAudiosPath removeAllObjects];
        [self.addedAudios removeAllObjects];
        
    }
    
}


-(void)callSentTo{
}
- (void)cancelButtonAction:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark * placemark in placemarks) {
            localityString = [placemark locality];
            NSLog(@"%@", [placemark locality]);
            [locationManager stopUpdatingLocation];
        }
    }];
	
}
// this delegate method is called if an error occurs in locating your current location
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager:%@ didFailWithError:%@", manager, error);
}
@end