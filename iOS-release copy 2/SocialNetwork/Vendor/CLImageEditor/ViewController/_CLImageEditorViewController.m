//
//  _CLImageEditorViewController.m
//
//  Created by sho yakushiji on 2013/11/05.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "_CLImageEditorViewController.h"

#import "CLImageToolBase.h"
#import <MapKit/MapKit.h>
#import "UIImageView+ImageFrame.h"
#define UIViewAutoresizingFlexibleMargins                 \
UIViewAutoresizingFlexibleBottomMargin    | \
UIViewAutoresizingFlexibleLeftMargin      | \
UIViewAutoresizingFlexibleRightMargin     | \
UIViewAutoresizingFlexibleTopMargin
#pragma mark- _CLImageEditorViewController

@interface _CLImageEditorViewController()
<CLImageToolProtocol>
@property (nonatomic, strong) CLImageToolBase *currentTool;
@property (nonatomic, strong, readwrite) CLImageToolInfo *toolInfo;
@property (nonatomic, strong) UIImageView *targetImageView;
@end
static NSString* AnnotationIdentifier = @"AnnotationIdentifier";

@implementation _CLImageEditorViewController
{
    UIImage *_originalImage;
    UIView *_bgView;
}
@synthesize toolInfo = _toolInfo;
@synthesize tapGesture,addedAudios,addedAudiosPath;
@synthesize frameSize;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //self.toolInfo = [CLImageToolInfo toolInfoForToolClass:[self class]];
    }
    return self;
}

- (id)init
{
    self = [self initWithNibName:nil bundle:nil];
    if (self){
        
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    return [self initWithImage:image delegate:nil];
}

- (id)initWithImage:(UIImage*)image delegate:(id<CLImageEditorDelegate>)delegate
{
    self = [self init];
    if (self){
        _originalImage = [image deepCopy];
        self.delegate = delegate;
    }
    return self;
}

- (id)initWithDelegate:(id<CLImageEditorDelegate>)delegate
{
    self = [self init];
    if (self){
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [_navigationBar removeFromSuperview];
}

#pragma mark- Custom initialization

- (void)initNavigationBar
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pushedFinishBtn:)];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    if(_navigationBar==nil){
        UINavigationItem *navigationItem  = [[UINavigationItem alloc] init];
        navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pushedCloseBtn:)];
        navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pushedFinishBtn:)];
        
        CGFloat dy = ([UIDevice iosVersion]<7) ? 0 : MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width);
        
        UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, dy, self.view.width, 44)];
        [navigationBar pushNavigationItem:navigationItem animated:NO];
        navigationBar.delegate = self;
        
        if(self.navigationController){
            [self.navigationController.view addSubview:navigationBar];
        }
        else{
            [self.view addSubview:navigationBar];
        }
        _navigationBar = navigationBar;
    }
    
    if(self.navigationController!=nil){
        _navigationBar.frame  = self.navigationController.navigationBar.frame;
        _navigationBar.hidden = YES;
        [_navigationBar popNavigationItemAnimated:NO];
    }
    else{
        _navigationBar.topItem.title = self.title;
    }
    
    if([UIDevice iosVersion] < 7){
        _navigationBar.barStyle = UIBarStyleBlackTranslucent;
    }
}

- (void)initMenuScrollView
{
    if(self.menuView==nil){
        UIScrollView *menuScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 80)];
        menuScroll.top = self.view.height - menuScroll.height;
        menuScroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        menuScroll.showsHorizontalScrollIndicator = NO;
        menuScroll.showsVerticalScrollIndicator = NO;
        
        [self.view addSubview:menuScroll];
        self.menuView = menuScroll;
    }
    self.menuView.backgroundColor = [CLImageEditorTheme toolbarColor];
}

- (void)initImageScrollView
{
    if(_scrollView==nil){
        UIScrollView *imageScroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        imageScroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageScroll.showsHorizontalScrollIndicator = NO;
        imageScroll.showsVerticalScrollIndicator = NO;
        imageScroll.delegate = self;
        imageScroll.clipsToBounds = NO;
        
        CGFloat y = 0;
        if(self.navigationController){
            if(self.navigationController.navigationBar.translucent){
                y = self.navigationController.navigationBar.bottom;
            }
            y = ([UIDevice iosVersion] < 7) ? y-[UIApplication sharedApplication].statusBarFrame.size.height : y;
        }
        else{
            y = _navigationBar.bottom;
        }
        
        imageScroll.top = y;
        imageScroll.height = self.view.height - imageScroll.top - _menuView.height;
        
        [self.view insertSubview:imageScroll atIndex:0];
        _scrollView = imageScroll;
    }
}

#pragma mark-

- (void)showInViewController:(UIViewController*)controller withImageView:(UIImageView*)imageView;
{
    _originalImage = imageView.image;
    
    self.targetImageView = imageView;
    
    [controller addChildViewController:self];
    [self didMoveToParentViewController:controller];
    
    self.view.frame = controller.view.bounds;
    [controller.view addSubview:self.view];
    [self refreshImageView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    selectedPin = 1 ;
    self.title = self.toolInfo.title;
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = self.theme.backgroundColor;
    self.navigationController.view.backgroundColor = self.view.backgroundColor;
    
    if([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    if([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    [self initNavigationBar];
    [self initMenuScrollView];
    [self initImageScrollView];
    
    [self setMenuView];
    
    if(_imageView==nil){
        _imageView = [UIImageView new];
        [_scrollView addSubview:_imageView];
        [self refreshImageView];
    }
    
    self.addedAudios =[[NSMutableArray alloc] init];
    self.addedAudiosPath =[[NSMutableArray alloc] init];

    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    
    self.tapGesture.delegate = self;
    
    [self.view addGestureRecognizer:self.tapGesture];
    
    
    NSArray *components = [[[PFUser currentUser] objectForKey:@"profileColor"] componentsSeparatedByString:@","];
    CGFloat r = [[components objectAtIndex:0] floatValue];
    CGFloat g = [[components objectAtIndex:1] floatValue];
    CGFloat b = [[components objectAtIndex:2] floatValue];
    CGFloat a = [[components objectAtIndex:3] floatValue];
    colorH = [UIColor colorWithHue:204.0f/360.0f saturation:76.0f/100.0f brightness:86.0f/100.0f alpha:1];[UIColor colorWithRed:r green:g blue:b alpha:a];
    [self addPinSelectButton];
    self.frameSize = [_imageView imageFrame];
}

-(void)addPinSelectButton{
  
    
    UIImage *pin1img = [UIImage imageNamed:[NSString stringWithFormat:@"pin1.png"]];
    
    UIImage *pin2img = [UIImage imageNamed:[NSString stringWithFormat:@"pin2.png"]];
    
    UIImage *pin3img = [UIImage imageNamed:[NSString stringWithFormat:@"pin3.png"]];
    
    UIImage *pin4img = [UIImage imageNamed:[NSString stringWithFormat:@"pin4.png"]];
    float Y_Co = self.view.frame.size.height - 50;
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
-(void)removeMarker:(id)sender{
    
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
        [self presentViewController:controller animated:YES completion:nil];
    });
}
# pragma mark - IQAudioRecorderController delegates

- (void)audioRecorderController:(IQAudioRecorderController *)controller didFinishWithAudioAtPath:(NSString *)path {
    [self.addedAudiosPath addObject:path];
  //  [self sendMessage:nil withPicture:nil withVideo:nil andWithAudio:path];
}
- (void)audioRecorderControllerDidCancel:(IQAudioRecorderController *)controller {
    
    id sender = [self.addedAudios lastObject];
    
    [self removeMarkerConfirm:sender];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    if(self.targetImageView){
        [self expropriateImageView];
    }
    else{
        [self refreshImageView];
    }
}

#pragma mark- View transition

- (void)copyImageViewInfo:(UIImageView*)fromView toView:(UIImageView*)toView
{
    CGAffineTransform transform = fromView.transform;
    fromView.transform = CGAffineTransformIdentity;
    
    toView.transform = CGAffineTransformIdentity;
    toView.frame = [toView.superview convertRect:fromView.frame fromView:fromView.superview];
    toView.transform = transform;
    toView.image = fromView.image;
    toView.contentMode = fromView.contentMode;
    toView.clipsToBounds = fromView.clipsToBounds;
    
    fromView.transform = transform;
}

- (void)expropriateImageView
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    UIImageView *animateView = [UIImageView new];
    [window addSubview:animateView];
    [self copyImageViewInfo:self.targetImageView toView:animateView];
    
    _bgView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:_bgView atIndex:0];
    
    _bgView.backgroundColor = self.view.backgroundColor;
    self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0];
    
    self.targetImageView.hidden = YES;
    _imageView.hidden = YES;
    _bgView.alpha = 0;
    _navigationBar.transform = CGAffineTransformMakeTranslation(0, -_navigationBar.height);
    _menuView.transform = CGAffineTransformMakeTranslation(0, self.view.height-_menuView.top);
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         animateView.transform = CGAffineTransformIdentity;
                         
                         CGFloat dy = ([UIDevice iosVersion]<7) ? [UIApplication sharedApplication].statusBarFrame.size.height : 0;
                         
                         CGSize size = (_imageView.image) ? _imageView.image.size : _imageView.frame.size;
                         if(size.width>0 && size.height>0){
                             CGFloat ratio = MIN(_scrollView.width / size.width, _scrollView.height / size.height);
                             CGFloat W = ratio * size.width;
                             CGFloat H = ratio * size.height;
                             animateView.frame = CGRectMake((_scrollView.width-W)/2 + _scrollView.left, (_scrollView.height-H)/2 + _scrollView.top + dy, W, H);
                         }
                         
                         _bgView.alpha = 1;
                         _navigationBar.transform = CGAffineTransformIdentity;
                         _menuView.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                         self.targetImageView.hidden = NO;
                         _imageView.hidden = NO;
                         [animateView removeFromSuperview];
                     }
     ];
}

- (void)restoreImageView:(BOOL)canceled
{
    if(!canceled){
        self.targetImageView.image = _imageView.image;
    }
    self.targetImageView.hidden = YES;
    
    id<CLImageEditorTransitionDelegate> delegate = [self transitionDelegate];
    if([delegate respondsToSelector:@selector(imageEditor:willDismissWithImageView:canceled:)]){
        [delegate imageEditor:self willDismissWithImageView:self.targetImageView canceled:canceled];
    }
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    UIImageView *animateView = [UIImageView new];
    [window addSubview:animateView];
    [self copyImageViewInfo:_imageView toView:animateView];
    
    _menuView.frame = [window convertRect:_menuView.frame fromView:_menuView.superview];
    _navigationBar.frame = [window convertRect:_navigationBar.frame fromView:_navigationBar.superview];
    
    [window addSubview:_menuView];
    [window addSubview:_navigationBar];
    
    self.view.userInteractionEnabled = NO;
    _menuView.userInteractionEnabled = NO;
    _navigationBar.userInteractionEnabled = NO;
    _imageView.hidden = YES;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         _bgView.alpha = 0;
                         _menuView.alpha = 0;
                         _navigationBar.alpha = 0;
                         
                         _menuView.transform = CGAffineTransformMakeTranslation(0, self.view.height-_menuView.top);
                         _navigationBar.transform = CGAffineTransformMakeTranslation(0, -_navigationBar.height);
                         
                         [self copyImageViewInfo:self.targetImageView toView:animateView];
                     }
                     completion:^(BOOL finished) {
                         [animateView removeFromSuperview];
                         [_menuView removeFromSuperview];
                         [_navigationBar removeFromSuperview];
                         
                         [self willMoveToParentViewController:nil];
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                         
                         _imageView.hidden = NO;
                         self.targetImageView.hidden = NO;
                         
                         if([delegate respondsToSelector:@selector(imageEditor:didDismissWithImageView:canceled:)]){
                             [delegate imageEditor:self didDismissWithImageView:self.targetImageView canceled:canceled];
                         }
                     }
     ];
}

#pragma mark- Properties

- (id<CLImageEditorTransitionDelegate>)transitionDelegate
{
    if([self.delegate conformsToProtocol:@protocol(CLImageEditorTransitionDelegate)]){
        return (id<CLImageEditorTransitionDelegate>)self.delegate;
    }
    return nil;
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    self.toolInfo.title = title;
}

- (UIScrollView*)scrollView
{
    return _scrollView;
}

#pragma mark- ImageTool setting

+ (NSString*)defaultIconImagePath
{
    return nil;
}

+ (CGFloat)defaultDockedNumber
{
    return 0;
}

+ (NSString*)defaultTitle
{
    return NSLocalizedStringWithDefaultValue(@"CLImageEditor_DefaultTitle", nil, [CLImageEditorTheme bundle], @"Edit", @"");
}

+ (BOOL)isAvailable
{
    return YES;
}

+ (NSArray*)subtools
{
    return [CLImageToolInfo toolsWithToolClass:[CLImageToolBase class]];
}

+ (NSDictionary*)optionalInfo
{
    return nil;
}

#pragma mark- 

- (void)setMenuView
{
    CGFloat x = 0;
    CGFloat W = 70;
    CGFloat H = _menuView.height;
    
    for(CLImageToolInfo *info in self.toolInfo.sortedSubtools){
        if(!info.available){
            continue;
        }
        
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedMenuView:) toolInfo:info];
        [_menuView addSubview:view];
        x += W;
    }
    _menuView.contentSize = CGSizeMake(MAX(x, _menuView.frame.size.width+1), 0);
}

- (void)resetImageViewFrame
{
    CGSize size = (_imageView.image) ? _imageView.image.size : _imageView.frame.size;
    if(size.width>0 && size.height>0){
        CGFloat ratio = MIN(_scrollView.frame.size.width / size.width, _scrollView.frame.size.height / size.height);
        CGFloat W = ratio * size.width * _scrollView.zoomScale;
        CGFloat H = ratio * size.height * _scrollView.zoomScale;
        
        _imageView.frame = CGRectMake(MAX(0, (_scrollView.width-W)/2), MAX(0, (_scrollView.height-H)/2), W, H);
    }
}

- (void)fixZoomScaleWithAnimated:(BOOL)animated
{
    CGFloat minZoomScale = _scrollView.minimumZoomScale;
    _scrollView.maximumZoomScale = 0.95*minZoomScale;
    _scrollView.minimumZoomScale = 0.95*minZoomScale;
    [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:animated];
}

- (void)resetZoomScaleWithAnimated:(BOOL)animated
{
    CGFloat Rw = _scrollView.frame.size.width / _imageView.frame.size.width;
    CGFloat Rh = _scrollView.frame.size.height / _imageView.frame.size.height;
    
    //CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat scale = 1;
    Rw = MAX(Rw, _imageView.image.size.width / (scale * _scrollView.frame.size.width));
    Rh = MAX(Rh, _imageView.image.size.height / (scale * _scrollView.frame.size.height));
    
    _scrollView.contentSize = _imageView.frame.size;
    _scrollView.minimumZoomScale = 1;
    _scrollView.maximumZoomScale = MAX(MAX(Rw, Rh), 1);
    
    [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:animated];
}

- (void)refreshImageView
{
    _imageView.image = _originalImage;
    
    [self resetImageViewFrame];
    [self resetZoomScaleWithAnimated:NO];
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark- Tool actions

- (void)setCurrentTool:(CLImageToolBase *)currentTool
{
    if(currentTool != _currentTool){
        [_currentTool cleanup];
        _currentTool = currentTool;
        [_currentTool setup];
        
        [self swapToolBarWithEditting:(_currentTool!=nil)];
    }
}

#pragma mark- Menu actions

- (void)swapMenuViewWithEditting:(BOOL)editting
{
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         if(editting){
                             _menuView.transform = CGAffineTransformMakeTranslation(0, self.view.height-_menuView.top);
                         }
                         else{
                             _menuView.transform = CGAffineTransformIdentity;
                         }
                     }
     ];
}

- (void)swapNavigationBarWithEditting:(BOOL)editting
{
    if(self.navigationController==nil){
        return;
    }
    
    if(editting){
        _navigationBar.hidden = NO;
        _navigationBar.transform = CGAffineTransformMakeTranslation(0, -_navigationBar.height);
        
        [UIView animateWithDuration:kCLImageToolAnimationDuration
                         animations:^{
                             self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.height-20);
                             _navigationBar.transform = CGAffineTransformIdentity;
                         }
         ];
    }
    else{
        [UIView animateWithDuration:kCLImageToolAnimationDuration
                         animations:^{
                             self.navigationController.navigationBar.transform = CGAffineTransformIdentity;
                             _navigationBar.transform = CGAffineTransformMakeTranslation(0, -_navigationBar.height);
                         }
                         completion:^(BOOL finished) {
                             _navigationBar.hidden = YES;
                             _navigationBar.transform = CGAffineTransformIdentity;
                         }
         ];
    }
}

- (void)swapToolBarWithEditting:(BOOL)editting
{
    [self swapMenuViewWithEditting:editting];
    [self swapNavigationBarWithEditting:editting];
    
    if(self.currentTool){
        UINavigationItem *item  = [[UINavigationItem alloc] initWithTitle:self.currentTool.toolInfo.title];
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"CLImageEditor_OKBtnTitle", nil, [CLImageEditorTheme bundle], @"OK", @"") style:UIBarButtonItemStyleDone target:self action:@selector(pushedDoneBtn:)];
        item.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"CLImageEditor_BackBtnTitle", nil, [CLImageEditorTheme bundle], @"Back", @"") style:UIBarButtonItemStylePlain target:self action:@selector(pushedCancelBtn:)];
        
        [_navigationBar pushNavigationItem:item animated:(self.navigationController==nil)];
    }
    else{
        [_navigationBar popNavigationItemAnimated:(self.navigationController==nil)];
    }
}

- (void)setupToolWithToolInfo:(CLImageToolInfo*)info
{
    if(self.currentTool){ return; }
    
    Class toolClass = NSClassFromString(info.toolName);
    
    if(toolClass){
        id instance = [toolClass alloc];
        if(instance!=nil && [instance isKindOfClass:[CLImageToolBase class]]){
            instance = [instance initWithImageEditor:self withToolInfo:info];
            self.currentTool = instance;
        }
    }
}

- (void)tappedMenuView:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    [self setupToolWithToolInfo:view.toolInfo];
}

- (IBAction)pushedCancelBtn:(id)sender
{
    _imageView.image = _originalImage;
    [self resetImageViewFrame];
    
    self.currentTool = nil;
}

- (IBAction)pushedDoneBtn:(id)sender
{
    self.view.userInteractionEnabled = NO;
    
    [self.currentTool executeWithCompletionBlock:^(UIImage *image, NSError *error, NSDictionary *userInfo) {
        if(error){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if(image){
            _originalImage = image;
            _imageView.image = image;
            
            [self resetImageViewFrame];
            self.currentTool = nil;
        }
        self.view.userInteractionEnabled = YES;
    }];
}

- (void)pushedCloseBtn:(id)sender
{
    if(self.targetImageView==nil){
        if([self.delegate respondsToSelector:@selector(imageEditorDidCancel:)]){
            [self.delegate imageEditorDidCancel:self];
        }
        else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else{
        _imageView.image = self.targetImageView.image;
        [self restoreImageView:YES];
    }
}

- (void)pushedFinishBtn:(id)sender
{
    if(self.targetImageView==nil){
        if([self.delegate respondsToSelector:@selector(imageEditor:didFinishEdittingWithImage:)]){
            [self.delegate imageEditor:self didFinishEdittingWithImage:_originalImage];
        }
        else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else{
        _imageView.image = _originalImage;
        [self restoreImageView:NO];
    }
}

#pragma mark- ScrollView delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
        return nil;
   // return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat Ws = _scrollView.frame.size.width - _scrollView.contentInset.left - _scrollView.contentInset.right;
    CGFloat Hs = _scrollView.frame.size.height - _scrollView.contentInset.top - _scrollView.contentInset.bottom;
    CGFloat W = _imageView.frame.size.width;
    CGFloat H = _imageView.frame.size.height;
    
    CGRect rct = _imageView.frame;
    rct.origin.x = MAX((Ws-W)/2, 0);
    rct.origin.y = MAX((Hs-H)/2, 0);
    _imageView.frame = rct;
}

@end
