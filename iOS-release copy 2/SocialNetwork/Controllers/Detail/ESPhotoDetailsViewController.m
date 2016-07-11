//
//  ESPhotoDetailViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//



#import "ESPhotoDetailsViewController.h"
#import "ESBaseTextCell.h"
#import "ESActivityCell.h"
#import "ESPhotoDetailsFooterView.h"
#import "ESConstants.h"
#import "ESAccountViewController.h"
#import "ESLoadMoreCell.h"
#import "ESUtility.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "SCLAlertView.h"
#import "KILabel.h"
#import "ESHashtagTimelineViewController.h"
#import "JTSImageInfo.h"
#import "JTSImageViewController.h"
#import "TOWebViewController.h"
#import "ESShareWithFollowersViewController.h"
#import "UIImageView+ImageFrame.h"
enum ActionSheetTags {
    MainActionSheetTag = 0,
    ConfirmDeleteActionSheetTag = 1,
    ReportPhotoActionSheetTag = 2,
    ThisIsUserTag = 3,
    DeleteCommentTag = 4,
    ReportUserCommentTag = 5,
    ReportUserReasonTag = 6
    
};
#define UIViewAutoresizingFlexibleMargins                 \
UIViewAutoresizingFlexibleBottomMargin    | \
UIViewAutoresizingFlexibleLeftMargin      | \
UIViewAutoresizingFlexibleRightMargin     | \
UIViewAutoresizingFlexibleTopMargin
 static const CGFloat kESCellInsetWidth = 0.0f;

@implementation ESPhotoDetailsViewController

@synthesize commentTextField;
@synthesize photo, headerView,user,disablePin,player;
@synthesize tapGesture,addedAudios,addedAudiosPath,addedAudiosData;
@synthesize enableSend,frameSize;
#pragma mark - Initialization

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ESUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:self.photo];
}

- (id)initWithPhoto:(PFObject *)aPhoto {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // The className to query on
        self.parseClassName = kESActivityClassKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of comments to show per page
        self.objectsPerPage = 30;
        
        self.photo = aPhoto;
       // [self.photo fetch];
        [self.photo fetchIfNeeded];


        self.likersQueryInProgress = NO;
        self.player = [[AVAudioPlayer alloc] init];
    }
    return self;
}


#pragma mark - UIViewController

- (void)updateBarButtonItems:(CGFloat)alpha
{
    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}
- (void)viewWillDisappear:(BOOL)animated {
 


}
-(void)viewWillAppear:(BOOL)animated {
    self.tableView.tag = 3;
    self.navigationController.navigationBar.frame = CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, 44);
    [self updateBarButtonItems:1];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.container.panMode = MFSideMenuPanModeNone;
    [self setupScales];

}
- (void) back:(UIBarButtonItem *)sender {
    // Perform your custom actions
    // ...
    // Go back to the previous ViewController
    if([audioDataArray count]>0)
    if(self.player && self.player.isPlaying)
        [self.player stop];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad {
     NSDictionary *viewsDictionary;
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    audioDataArray=[[NSMutableArray alloc] init];
    audioMarkerArray=[[NSMutableArray alloc] init];
    
     colorH = [UIColor colorWithHue:204.0f/360.0f saturation:76.0f/100.0f brightness:86.0f/100.0f alpha:1];
    selectedPin = 1;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    [super viewDidLoad];
    self.user = [PFUser currentUser] ;
   // self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];
    
    // Set table view properties
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
    // Set table header
//    if ([[self.photo objectForKey:@"type"]isEqualToString:@"text"]) {
//        CGSize labelSize = [[self.photo objectForKey:@"text"] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:16]
//                                                         constrainedToSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 20, 100)
//                                                             lineBreakMode:NSLineBreakByWordWrapping];
//        CGFloat labelHeight = labelSize.height;
//
//        self.headerView = [[ESPhotoDetailsHeaderView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 46+labelHeight+63) photo:self.photo];
//    }
   // else {
        self.headerView = [[ESPhotoDetailsHeaderView alloc] initWithFrame:[ESPhotoDetailsHeaderView rectForView] photo:self.photo];
   // }
    self.headerView.delegate = self;
    //self.headerView.scroller.translatesAutoresizingMaskIntoConstraints = NO;
   // self.headerView.photoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerView.scroller.delegate = self;
    [self.headerView.scroller setContentMode:UIViewContentModeScaleAspectFit];
  //  [imageView sizeToFit];
    [self.headerView.scroller setContentSize:CGSizeMake(self.headerView.photoImageView.frame.size.width, self.headerView.photoImageView.frame.size.height)];
    

    //self.headerView.scroller.contentSize = self.headerView.photoImageView.imageFrame.size;
    self.tableView.tableHeaderView = self.headerView;
    UIScrollView *scrollView=self.headerView.scroller;
//     viewsDictionary = NSDictionaryOfVariableBindings(scrollView);
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:0 views:viewsDictionary]];
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView]-(50)-|" options:0 metrics: 0 views:viewsDictionary]];
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [self.headerView.scroller addGestureRecognizer:doubleTapRecognizer];
    
    UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTwoFingerTapped:)];
    twoFingerTapRecognizer.numberOfTapsRequired = 1;
    twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    [self.headerView.scroller addGestureRecognizer:twoFingerTapRecognizer];
    
    // Set table footer
    ESPhotoDetailsFooterView *footerView = [[ESPhotoDetailsFooterView alloc] initWithFrame:[ESPhotoDetailsFooterView rectForView]];
    commentTextField = footerView.commentField;
    commentTextField.delegate = self;
    self.tableView.tableFooterView = footerView;
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonAction:)];
   // self.navigationItem.rightBarButtonItem = //[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStylePlain target:self action:@selector(shareButtonAction:)];
    
    // Register to be notified when the keyboard will be shown to scroll the view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLikedOrUnlikedPhoto:) name:ESUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:self.photo];
    NSString *notificationName = @"Hashtag";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(useNotificationWithString:) name:notificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(useNotificationWithMentionString:) name:@"Mention" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(useNotificationWithWebsiteString:) name:@"Website" object:nil];
   // if(!disablePin){
//    scroller=[[UIScrollView alloc] init];
//    twoFingerPinch = [[UIPinchGestureRecognizer alloc]
//                      initWithTarget:self
//                      action:@selector(twoFingerPinch:)];
//    [self.headerView.photoImageView setUserInteractionEnabled:YES];
//    [self.headerView.photoImageView addGestureRecognizer:twoFingerPinch];
    if(enableSend)
        
    {
       // [self addPinSelectButton:self.headerView.pinBarView];
        
        [self performSelector:@selector(loadMarkersForPhoto) withObject:nil afterDelay:5];


    }else{
        
       // [self addPinSelectButton:self.headerView.pinBarView];

    self.addedAudios =[[NSMutableArray alloc] init];
    self.addedAudiosPath =[[NSMutableArray alloc] init];
    
//    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
//    
//    self.tapGesture.delegate = self;
//    
//    [self.view addGestureRecognizer:self.tapGesture];
//    
    //[self addPinSelectButton];
    self.frameSize = self.headerView.photoImageView.frame;
        [self performSelector:@selector(loadMarkersForPhoto) withObject:nil afterDelay:0.5];

    }
    
    if (![[[self.photo objectForKey:kESPhotoUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        float size = 60.0f;
        CGRect frame = CGRectMake([UIScreen mainScreen].bounds.size.width - size-5.0,0, size, size);//12.0f, 40, 18.0f
        
        reportUser = [[UIButton alloc]initWithFrame:frame];//CGRectMake([UIScreen mainScreen].bounds.size.width - 140 , 175, 20, 20)
        [reportUser setImage:[UIImage imageNamed:@"ButtonImageSettings"] forState:UIControlStateNormal];
        [reportUser setImage:[UIImage imageNamed:@"ButtonImageSettingsSelected"] forState:UIControlStateHighlighted];
        [reportUser addTarget:self action:@selector(ReportTap) forControlEvents:UIControlEventTouchUpInside];
        [self.headerView.nameHeaderView addSubview:reportUser];
    }

   

}

- (void) ReportTap {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    
    if ([self currentUserOwnsPhoto]) {
        // Else we only want to show an action button if the user owns the photo and has permission to delete it.
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
        actionSheet.tag = ThisIsUserTag;
    }
    else {
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Report", nil)];
        actionSheet.tag = MainActionSheetTag;
    }
    if (NSClassFromString(@"UIActivityViewController")) {
       // [actionSheet addButtonWithTitle:NSLocalizedString(@"Send", nil)];
    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }
    return YES; // handle the touch
}
- (void)handleSingleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    
    if(self.player && self.player.isPlaying){
        [self.player stop];
    
    }
    CGPoint point = [tapGestureRecognizer locationInView:self.headerView.photoImageView];
    // float squareSize = 10;
    CGRect imgBox=[self.headerView.photoImageView imageFrame];
    if(!CGRectContainsPoint(imgBox, point)){
        return; // tap somewhere else
    }
    UIButton *marker;
    if(!marker){
        [self.headerView.photoImageView setUserInteractionEnabled:YES];
        UIImage *pin = [UIImage imageNamed:[NSString stringWithFormat:@"pin%d.png",selectedPin]];
        CGRect newrect = CGRectMake(point.x-23, point.y-46, 46, 46);
        
        marker = [[UIButton alloc] initWithFrame:newrect];
        [marker setImage:pin forState:UIControlStateNormal];
        [marker setTag:selectedPin];
        [marker setEnabled:YES];
        marker.autoresizingMask  = UIViewAutoresizingFlexibleMargins;
        [marker addTarget:self action:@selector(removeMarker:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        
       // [marker setFrame:CGRectMake(point.x, point.y,30, 49)];
    }
    [self.headerView.photoImageView addSubview:marker];
    [self.addedAudios addObject:marker];
    
    
    //    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
    //    annotationView.canShowCallout = YES;
    //    annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"F.png"]];
    //    UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    //    [rightButton addTarget:self action:@selector(writeSomething:) forControlEvents:UIControlEventTouchUpInside];
    //    [rightButton setTitle:annotation.title forState:UIControlStateNormal];
    //
    //    annotationView.rightCalloutAccessoryView = rightButton;
    //    annotationView.canShowCallout = YES;
    //    annotationView.draggable = NO;
    
    // UIGraphicsBeginImageContextWithOptions(self.imageView.frame.size, YES, 0);
    //
    //    [self.imageView.image drawInRect:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
    //
    //    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), point.x-squareSize, point.y - squareSize);
    //    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), point.x+squareSize, point.y-squareSize);
    //    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), point.x+squareSize, point.y+squareSize);
    //    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), point.x-squareSize, point.y+squareSize);
    //    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), point.x-squareSize, point.y-squareSize);
    //    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    //    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 1);
    //    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0,0,0,1);
    //    CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
    //
    //    CGContextStrokePath(UIGraphicsGetCurrentContext());
    //    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    //    [self.imageView setAlpha:1.0];
    //    UIGraphicsEndImageContext();
    [self performSelector:@selector(launchRecorderView) withObject:nil afterDelay:0.1];
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
-(NSMutableDictionary *)sideToneDictWithType:(int)type value:(NSString *)value{

    NSString * typeStr;
    if(type == 5){
    typeStr=[NSString stringWithFormat:@""];
    }
    if(type == 6){
        typeStr=[NSString stringWithFormat:@""];
    }
    if(type == 7){
        typeStr=[NSString stringWithFormat:@""];
    }
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:typeStr forKey:@"type"];
    [dict setValue:value forKey:@"path"];
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

-(void)loadMarkersForPhoto{

    if(!markersArray){
       markersArray = [[NSMutableArray alloc] init];
    }
    NSString *objectId = [self.photo objectId];
    [audioDataArray removeAllObjects];
    [audioMarkerArray removeAllObjects];
    markersArray = [[STParseHelper sharedInstance] getSideToneForImageId:objectId];
    if(markersArray){
    
        NSLog(@"%@ *** markers loaded from server ",markersArray);
        
        for (PFObject *object in markersArray) {
            
            NSString *rect = [object objectForKey:kSideToneCGRectKey];
            NSString *rectImgV = [object objectForKey:kSideToneFrameKey];

            
            CGRect currentViewFrame =[self.headerView.photoImageView imageFrame];
            CGRect rectVal = CGRectFromString(rect);
            CGRect imgFrame = CGRectFromString(rectImgV);
            float  scaleX = currentViewFrame.size.width/imgFrame.size.width;
            float  scaleY = currentViewFrame.size.height/imgFrame.size.height;
            UIButton  *marker;
            NSString *pinIndex= [object objectForKey:kSideTonePinKey];
            NSString *pinStr = [NSString stringWithFormat:@"pin%@.png",pinIndex];
               [self.headerView.photoImageView setUserInteractionEnabled:YES];
            UIImage *pin = [UIImage imageNamed:pinStr];
            float yoffSet;
            CGRect rectValFinal = CGRectMake(rectVal.origin.x*scaleX, rectVal.origin.y*scaleY, rectVal.size.width, rectVal.size.height);

            yoffSet = (self.headerView.photoImageView.frame.size.height-imgFrame.size.height)/2;
            
            marker = [[UIButton alloc] initWithFrame:rectValFinal];
            [marker addTarget:self action:@selector(buttonPlay:) forControlEvents:UIControlEventTouchUpInside];
            [marker setImage:pin forState:UIControlStateNormal];
            [marker setEnabled:YES];
            marker.tag=[markersArray indexOfObject:object];
            marker.autoresizingMask  = UIViewAutoresizingFlexibleMargins;
            [self.headerView.photoImageView addSubview:marker];
            
          //  PFObject *object = [markersArray objectAtIndex:index];
            if([[object objectForKey:kSideTonePinKey] isEqualToString:@"5"]){
            PFFile *audio = [object objectForKey:kSideToneAudioKey];
            [audio getDataInBackgroundWithBlock:^(NSData *result, NSError *error) {
                // do something in here with NSData object 'result' which contains the audio file.
                if(!error){
                    
                    [audioDataArray addObject:result];
                    [audioMarkerArray addObject:marker];
                    if([markersArray indexOfObject:object] >= ([markersArray count]-1)){
                        
                        [self playAudioOnLoad];
                    }
                }
            }];
            }
            
            
        }
       // [self.headerView.photoImageView ]
    }
   
}
-(void)playAudioOnLoad{
    autoplayIndex = 0 ;
    autoPlay = YES;
    if(markersArray>0){
        [self withoutButtonPlay:autoplayIndex];
    
    }
   // Looper * looper = [[Looper alloc] initWithFileNameQueue:[NSArray arrayWithObjects: audioFile, audioFile2, nil ]];


}
-(void)withoutButtonPlay:(int)_index
{
    //UIButton * btn = sender;
    int index = _index;//(int)btn.tag;
    if(index< [audioDataArray count])
    {
        
//        PFObject *object = [markersArray objectAtIndex:index];
//        PFFile *audio = [object objectForKey:kSideToneAudioKey];
//        [audio getDataInBackgroundWithBlock:^(NSData *result, NSError *error) {
//            // do something in here with NSData object 'result' which contains the audio file.
//            if(!error){
        
                self.player=[[AVAudioPlayer alloc] initWithData:[audioDataArray objectAtIndex:index] error:nil];
                
                [self.player setDelegate:self];
                [self.player play];
        UIButton *button = [audioMarkerArray objectAtIndex:autoplayIndex];
        CABasicAnimation *theAnimation;
        theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];///use transform
        theAnimation.duration=0.2;
        [theAnimation setRepeatCount:UIViewAnimationOptionRepeat];
        theAnimation.autoreverses=YES;
        theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
        theAnimation.toValue=[NSNumber numberWithFloat:-20];
        [button.layer addAnimation:theAnimation forKey:@"animateTranslation"];//ani
                autoplayIndex++;
//            }
//        }];
        
        
    }
    
    
}

-(void)buttonPlay:(id)sender
{
    
    autoPlay=NO;
    UIButton * btn = sender;
    int index = (int)btn.tag;
    if(index< [markersArray count])
    {
    
        
        PFObject *object = [markersArray objectAtIndex:index];
        if([[object objectForKey:kSideTonePinKey] isEqualToString:@"6"] ){
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:[object objectForKey:@"textvalue"] preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                //[self removeMarkerConfirm:sender];
                
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
        // show text popup
        }else if([[object objectForKey:kSideTonePinKey]isEqualToString:@"7"]){
            // open URL
            
            NSString *myURLString= [object objectForKey:@"textvalue"];
            NSURL *myURL;
            if ([myURLString.lowercaseString hasPrefix:@"http://"]) {
                myURL = [NSURL URLWithString:myURLString];
            } else {
                myURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",myURLString]];
            }
            [[UIApplication sharedApplication] openURL:myURL];
            
        }else if([[object objectForKey:kSideTonePinKey]isEqualToString:@"8"]){
            
            
          PFFile *imgFIle =   [object objectForKey:@"img"];
            
            [imgFIle getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (!error) {
                    UIImage *image = [UIImage imageWithData:data];
                    
                    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
#if TRY_AN_ANIMATED_GIF == 1
                    imageInfo.imageURL = [NSURL URLWithString:@"http://media.giphy.com/media/O3QpFiN97YjJu/giphy.gif"];
#else
                    imageInfo.image =image;// _headerView.photoImageView.image;
#endif
                    imageInfo.referenceRect = self.headerView.photoImageView.frame;
                    imageInfo.referenceView = self.headerView.photoImageView.superview;
                    imageInfo.referenceContentMode = self.headerView.photoImageView.contentMode;
                    imageInfo.referenceCornerRadius = self.headerView.photoImageView.layer.cornerRadius;
                    
                    // Setup view controller
                    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                           initWithImageInfo:imageInfo
                                                           mode:JTSImageViewControllerMode_Image
                                                           backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
                    
                    // Present the view controller.
                    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
                    // image can now be set on a UIImageView
                }
            }];
            
            
            
        }else if([[object objectForKey:kSideTonePinKey]isEqualToString:@"9"]){
            PFFile *imgFIle =   [object objectForKey:@"img"];
            
            [imgFIle getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (!error) {
                    UIImage *image = [UIImage imageWithData:data];
                    
                    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
#if TRY_AN_ANIMATED_GIF == 1
                    imageInfo.imageURL = [NSURL URLWithString:@"http://media.giphy.com/media/O3QpFiN97YjJu/giphy.gif"];
#else
                    imageInfo.image =image;// _headerView.photoImageView.image;
#endif
                    imageInfo.referenceRect = self.headerView.photoImageView.frame;
                    imageInfo.referenceView = self.headerView.photoImageView.superview;
                    imageInfo.referenceContentMode = self.headerView.photoImageView.contentMode;
                    imageInfo.referenceCornerRadius = self.headerView.photoImageView.layer.cornerRadius;
                    
                    // Setup view controller
                    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                           initWithImageInfo:imageInfo
                                                           mode:JTSImageViewControllerMode_Image
                                                           backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
                    
                    // Present the view controller.
                    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
                }
            }];

        }
            else if([[object objectForKey:kSideTonePinKey]isEqualToString:@"10"]){
                PFFile *imgFIle =   [object objectForKey:@"img"];
                
                [imgFIle getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!error) {
                        UIImage *image = [UIImage imageWithData:data];
                        
                        JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
#if TRY_AN_ANIMATED_GIF == 1
                        imageInfo.imageURL = [NSURL URLWithString:@"http://media.giphy.com/media/O3QpFiN97YjJu/giphy.gif"];
#else
                        imageInfo.image =image;// _headerView.photoImageView.image;
#endif
                        imageInfo.referenceRect = self.headerView.photoImageView.frame;
                        imageInfo.referenceView = self.headerView.photoImageView.superview;
                        imageInfo.referenceContentMode = self.headerView.photoImageView.contentMode;
                        imageInfo.referenceCornerRadius = self.headerView.photoImageView.layer.cornerRadius;
                        
                        // Setup view controller
                        JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                               initWithImageInfo:imageInfo
                                                               mode:JTSImageViewControllerMode_Image
                                                               backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
                        
                        // Present the view controller.
                        [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
                    }
                }];
                
            }else{
        PFFile *audio = [object objectForKey:kSideToneAudioKey];
        [audio getDataInBackgroundWithBlock:^(NSData *result, NSError *error) {
            // do something in here with NSData object 'result' which contains the audio file.
            if(!error){
 
                self.player=[[AVAudioPlayer alloc] initWithData:result error:&error];
            
                 [self.player setDelegate:self];
                [self.player play];
                CABasicAnimation *theAnimation;
                theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];///use transform
                theAnimation.duration=0.2;
                [theAnimation setRepeatCount:UIViewAnimationOptionRepeat];
                theAnimation.autoreverses=YES;
                theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
                theAnimation.toValue=[NSNumber numberWithFloat:-20];
                [btn.layer addAnimation:theAnimation forKey:@"animateTranslation"];//ani
            }
        }];
        }

        
    }


}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (autoPlay) {
        [self withoutButtonPlay:autoplayIndex];
    } else {
        //reached end of queue
    }
}
-(void)addPinSelectButton:(UIView *)view{

    
    
    UIImage *pin1img = [UIImage imageNamed:[NSString stringWithFormat:@"pin1.png"]];
    
    UIImage *pin2img = [UIImage imageNamed:[NSString stringWithFormat:@"pin2.png"]];
    
    UIImage *pin3img = [UIImage imageNamed:[NSString stringWithFormat:@"pin3.png"]];
    
    UIImage *pin4img = [UIImage imageNamed:[NSString stringWithFormat:@"pin4.png"]];
    float Y_Co = view.frame.size.height - 50;
    float X_Co = view.frame.size.width;
    
    UIStackView *stack = [[UIStackView alloc] init];
    [stack setFrame: CGRectMake(0 , Y_Co, X_Co, 46)];
    [view addSubview:stack];
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
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
     [self.headerView reloadLikeBar];
    
    // we will only hit the network if we have no cached data for this photo
    BOOL hasCachedLikers = [[ESCache sharedCache] attributesForPhoto:self.photo] != nil;
    if (!hasCachedLikers) {
        [self loadLikers];
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) { // A comment row
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        
        if (object) {
            NSString *commentString = [self.objects[indexPath.row] objectForKey:kESActivityContentKey];
            
            PFUser *commentAuthor = (PFUser *)[object objectForKey:kESActivityFromUserKey];
            
            NSString *nameString = @"";
            if (commentAuthor) {
                nameString = [commentAuthor objectForKey:kESUserDisplayNameKey];
            }
            
            return [ESActivityCell heightForCellWithName:nameString contentString:commentString cellInsetWidth:kESCellInsetWidth];
        }
    }
    
    // The pagination row
    return 44.0f;
}


#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:kESActivityPhotoKey equalTo:self.photo];
    [query whereKeyDoesNotExist:@"noneread"];
    [query includeKey:kESActivityFromUserKey];
    [self.photo fetch];
   // if ([[self.photo objectForKey:@"type"] isEqualToString:@"text"]) {
      //  [query whereKey:kESActivityTypeKey equalTo:kESActivityTypeCommentPost];
   // }
    //else {
       // [query whereKey:kESActivityTypeKey equalTo:kESActivityTypeCommentPhoto];
   // }
    [query orderByAscending:@"createdAt"];
    
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
    if (self.objects.count == 0 || ![[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]) {
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
   [self.headerView reloadLikeBar];
    [self loadLikers];
     //[self setupScales];
   // [self performSelector:@selector(loadMarkersForPhoto) withObject:nil afterDelay:0.5];

}

#pragma mark -
#pragma mark - Scroll View scales setup and center

-(void)setupScales {
    // Set up the minimum & maximum zoom scales
    CGRect scrollViewFrame = self.headerView.scroller.frame;
    CGFloat scaleWidth = scrollViewFrame.size.width / self.headerView.scroller.contentSize.width;
    CGFloat scaleHeight = scrollViewFrame.size.height / self.headerView.scroller.contentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    
    self.headerView.scroller.minimumZoomScale = minScale;
    self.headerView.scroller.maximumZoomScale = 2.0f;
    self.headerView.scroller.zoomScale = minScale;
    
    [self centerScrollViewContents];
}

- (void)centerScrollViewContents {
    // This method centers the scroll view contents also used on did zoom
    CGSize boundsSize = self.headerView.scroller.bounds.size;
    CGRect contentsFrame = self.headerView.photoImageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.headerView.photoImageView.frame = contentsFrame;
}

#pragma mark -
#pragma mark - ScrollView Delegate methods
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that we want to zoom
    return self.headerView.photoImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so we need to re-center the contents
    [self centerScrollViewContents];
}

#pragma mark -
#pragma mark - ScrollView gesture methods
- (void)scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer {
    // Get the location within the image view where we tapped
    CGPoint pointInView = [recognizer locationInView:self.headerView.photoImageView];
    
    // Get a zoom scale that's zoomed in slightly, capped at the maximum zoom scale specified by the scroll view
    CGFloat newZoomScale = self.headerView.scroller.zoomScale * 1.5f;
    newZoomScale = MIN(newZoomScale, self.headerView.scroller.maximumZoomScale);
    
    // Figure out the rect we want to zoom to, then zoom to it
    CGSize scrollViewSize = self.headerView.scroller.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0f);
    CGFloat y = pointInView.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    [self.headerView.scroller zoomToRect:rectToZoomTo animated:YES];
}

- (void)scrollViewTwoFingerTapped:(UITapGestureRecognizer*)recognizer {
    // Zoom out slightly, capping at the minimum zoom scale specified by the scroll view
    CGFloat newZoomScale = self.headerView.scroller.zoomScale / 1.5f;
    newZoomScale = MAX(newZoomScale, self.headerView.scroller.minimumZoomScale);
    [self.headerView.scroller setZoomScale:newZoomScale animated:YES];
}

#pragma mark -
#pragma mark - Rotation

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // When the orientation is changed the contentSize is reset when the frame changes. Setting this back to the relevant image size
    self.headerView.scroller.contentSize = self.headerView.photoImageView.image.size;
    // Reset the scales depending on the change of values
    [self setupScales];
}
# pragma mark - UITableView data source and delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *cellID = @"CommentCell";
    
    // Try to dequeue a cell and create one if necessary
    ESBaseTextCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[ESBaseTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.cellInsetWidth = kESCellInsetWidth;
        cell.delegate = self;
    }
    
    [cell setUser:[object objectForKey:kESActivityFromUserKey]];
    [cell setContentText:[object objectForKey:kESActivityContentKey]];
    [cell setDate:[object createdAt]];
    
    if ([[(PFUser *)[object objectForKey:kESActivityFromUserKey] objectId] isEqualToString:[PFUser currentUser].objectId]) {
        cell.replyButton.hidden = YES;
    }
    
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"NextPage";
    
    ESLoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[ESLoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.cellInsetWidth = kESCellInsetWidth;
        cell.hideSeparatorTop = YES;
    }
    
    return cell;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
}
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject *object = [self.objects objectAtIndex:indexPath.row];
    if ([[[object objectForKey:@"fromUser"] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            // show UIActionSheet
            UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"Do you really want to delete this comment?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles: nil];
            [actionSheet showInView:self.view];
            actionSheet.tag = DeleteCommentTag;
            savedIndexPath = indexPath;
            
        }];
        deleteAction.backgroundColor = [UIColor redColor];
        return @[deleteAction];
        
    }
    else {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Report User", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            // show UIActionSheet
            UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"Do you really want to report this user?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Report", nil) otherButtonTitles: nil];
            [actionSheet showInView:self.view];
            actionSheet.tag = ReportUserCommentTag;
            savedIndexPath = indexPath;
            
        }];
        deleteAction.backgroundColor = [UIColor redColor];
        return @[deleteAction];
        
    }
    
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //We make some changes to the comment and verify everything is alright before we actually upload it.
    //We also search for mentions, hashtags and links.
    
    NSString *dummyComment = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *trimmedComment = [NSString stringWithFormat:@"%@ ",dummyComment];
    if (trimmedComment.length != 0 && [self.photo objectForKey:kESPhotoUserKey]) {
                NSRegularExpression *_regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:nil];
        NSArray *_matches = [_regex matchesInString:trimmedComment options:0 range:NSMakeRange(0, trimmedComment.length)];
        NSMutableArray *hashtagsArray = [[NSMutableArray alloc]init];
        for (NSTextCheckingResult *match in _matches) {
            NSRange wordRange = [match rangeAtIndex:1];
            NSString* word = [trimmedComment substringWithRange:wordRange];
            [hashtagsArray addObject:[word lowercaseString]];
        }
        
        PFObject *comment = [PFObject objectWithClassName:kESActivityClassKey];
        [comment setObject:trimmedComment forKey:kESActivityContentKey]; // Set comment text
        [comment setObject:[self.photo objectForKey:kESPhotoUserKey] forKey:kESActivityToUserKey]; // Set toUser
        [comment setObject:[PFUser currentUser] forKey:kESActivityFromUserKey]; // Set fromUser
        if ([photo objectForKey:kESVideoFileKey]) {
            [comment setObject:kESActivityTypeCommentVideo forKey:kESActivityTypeKey];
        }else if ([[photo objectForKey:@"type"] isEqualToString:@"text"]) {
            [comment setObject:kESActivityTypeCommentPost forKey:kESActivityTypeKey];
        }else [comment setObject:kESActivityTypeCommentPhoto forKey:kESActivityTypeKey];
        [comment setObject:self.photo forKey:kESActivityPhotoKey];
        if (hashtagsArray.count > 0) {
            [comment setObject:hashtagsArray forKey:@"hashtags"];
            
            for (int i = 0; i < hashtagsArray.count; i++) {
                
                //In the Hashtags class, if the hashtag doesn't already exist, we add it to the list a user can search through.
                
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
        
        [[ESCache sharedCache] incrementCommentCountForPhoto:self.photo];
        
        // Show HUD view
        [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
        
        
        // If more than 5 seconds pass since we post a comment, stop waiting for the server to respond
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:8.0f target:self selector:@selector(handleCommentTimeout:) userInfo:@{@"comment": comment} repeats:NO];
        
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
                    [mention setObject:self.photo forKey:kESActivityPhotoKey];
                    [mention saveEventually];
                }
            }];
        }
        
        [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [timer invalidate];
            
            if (error && error.code == kPFErrorObjectNotFound) {
                NSLog(@"ERROR:%@",error);
                [[ESCache sharedCache] decrementCommentCountForPhoto:self.photo];
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                        subTitle:NSLocalizedString(@"We were unable to post your comment because this photo is no longer available.", nil)
                closeButtonTitle:@"OK" duration:0.0f];
                
                [self.navigationController popViewControllerAnimated:YES];
            }else if (error){
                [comment saveEventually];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ESPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:self.photo userInfo:@{@"comments": @(self.objects.count + 1)}];
            
            [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
            [self loadObjects];
        }];
    }
    
    [textField setText:@""];
    return [textField resignFirstResponder];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == MainActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to report this photo? This can not be undone and might have consequences for the author.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Yes, report this photo", nil) otherButtonTitles:nil];
            actionSheet.tag = ReportPhotoActionSheetTag;
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        } else if (buttonIndex == 1){
            [self activityButtonAction:actionSheet];
        }
        
    }
    else if (actionSheet.tag == ThisIsUserTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            // prompt to delete
            if ([[self.photo objectForKey:@"type"] isEqualToString:@"text"]) {
                
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this post? This can not be undone.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Yes, delete post", nil) otherButtonTitles:nil];
                actionSheet.tag = ConfirmDeleteActionSheetTag;
                [actionSheet showFromTabBar:self.tabBarController.tabBar];
            }
            else {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this photo? This can not be undone.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Yes, delete photo", nil) otherButtonTitles:nil];
                actionSheet.tag = ConfirmDeleteActionSheetTag;
                [actionSheet showFromTabBar:self.tabBarController.tabBar];
            }
            
        } else if (buttonIndex == 1){
            [self activityButtonAction:actionSheet];
        }
        
    }
    else if (actionSheet.tag == ConfirmDeleteActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            
            [self shouldDeletePhoto];
        }
    } else if (actionSheet.tag == ReportPhotoActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            
            [self shouldReportPhoto];
        }
    }
    else if (actionSheet.tag == DeleteCommentTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {

            PFObject *object = [self.objects objectAtIndex:savedIndexPath.row];
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    SCLAlertView *alert = [[SCLAlertView alloc] init];
                    [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                            subTitle:NSLocalizedString(@"We were unable to delete your comment, retry later", nil)
                    closeButtonTitle:@"OK" duration:0.0f];
                }
                else {
                    SCLAlertView *alert = [[SCLAlertView alloc] init];
                    [alert showSuccess:self.tabBarController title:NSLocalizedString(@"Congratulations", nil) subTitle:NSLocalizedString(@"Your comment has been successfully deleted", nil) closeButtonTitle:NSLocalizedString(@"Done", nil) duration:0.0f];
                    
                    [self loadObjects];
                    [self.tableView reloadData];
                }
            }];
        }
        
    }
    else if (actionSheet.tag == ReportUserCommentTag) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"What do you want the user to be reported for?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Sexual content", nil), NSLocalizedString(@"Offensive content", nil), NSLocalizedString(@"Spam", nil), NSLocalizedString(@"Other", nil), nil];
        //actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = ReportUserReasonTag;
        [actionSheet showInView:self.view];
    }
    else if (actionSheet.tag == ReportUserReasonTag) {
        PFObject *object = [self.objects objectAtIndex:savedIndexPath.row];
        PFUser *user1 = [object objectForKey:kESActivityFromUserKey];
        if (buttonIndex == 0) {
            [ESUtility reportUser:0 withUser:user1 andObject:object];
        }
        else if (buttonIndex == 1) {
            [ESUtility reportUser:1 withUser:user1 andObject:object];
        }
        else if (buttonIndex == 2) {
            [ESUtility reportUser:2 withUser:user1 andObject:object];
        }
        else if (buttonIndex == 3) {
            [ESUtility reportUser:3 withUser:user1 andObject:object];
        }
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [commentTextField resignFirstResponder];
}


#pragma mark - ESBaseTextCellDelegate

- (void)cell:(ESBaseTextCell *)cellView didTapUserButton:(PFUser *)aUser {
    [self shouldPresentAccountViewForUser:aUser];
}
- (void)cell:(ESBaseTextCell *)cellView didTapReplyButton:(PFUser *)aUser {
    NSString *string = [NSString stringWithFormat:@"@%@ ",[aUser objectForKey:@"usernameFix"]];
    [commentTextField setText:string];
    [commentTextField becomeFirstResponder];
    
}


#pragma mark - ESPhotoDetailsHeaderViewDelegate
- (void)twoFingerPinch:(UIPinchGestureRecognizer *)recognizer
{
    //    NSLog(@"Pinch scale: %f", recognizer.scale);
    if (recognizer.scale >1.0f && recognizer.scale < 2.5f) {
        CGAffineTransform transform = CGAffineTransformMakeScale(recognizer.scale, recognizer.scale);
        self.headerView.photoImageView.transform = transform;
    }
}
-(void)photoDetailsHeaderView:(ESPhotoDetailsHeaderView *)headerView didTapUserButton:(UIButton *)button user:(PFUser *)user {
    [self shouldPresentAccountViewForUser:user];
}
- (void)photoDetailsHeaderView:(ESPhotoDetailsHeaderView *)_headerView didTapPhotoButton:(UIButton *)button {
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
#if TRY_AN_ANIMATED_GIF == 1
    imageInfo.imageURL = [NSURL URLWithString:@"http://media.giphy.com/media/O3QpFiN97YjJu/giphy.gif"];
#else
    imageInfo.image = _headerView.photoImageView.image;
#endif
    imageInfo.referenceRect = _headerView.photoImageView.frame;
    imageInfo.referenceView = _headerView.photoImageView.superview;
    imageInfo.referenceContentMode = _headerView.photoImageView.contentMode;
    imageInfo.referenceCornerRadius = _headerView.photoImageView.layer.cornerRadius;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
    
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
    
}
- (void)shareButtonAction:(id)sender {
    
    if(enableSend){
    ESShareWithFollowersViewController *shareWithView = [[ESShareWithFollowersViewController alloc] initWithStyle:UITableViewStyleGrouped andOption:@"Send To" andUser:self.user];
    shareWithView.photo=self.photo;
//    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonAction:)];
//[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    //UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                 //     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                   //   target:self action:@selector(refreshClicked:)] ;
    [self.navigationController pushViewController:shareWithView animated:YES];
    }else{
    
    //save data
       
        [self publishNewMarkers];
        
        PFUser *sidetoneOwner =    (PFUser *)     [self.photo objectForKey:kESPhotoUserKey];
        PFUser *cUser = [PFUser currentUser];
        if([[sidetoneOwner objectId] isEqual:[cUser objectId]]){
            
            ESShareWithFollowersViewController *shareWithView = [[ESShareWithFollowersViewController alloc] initWithStyle:UITableViewStyleGrouped andOption:@"Send To" andUser:self.user];
            shareWithView.photo=self.photo;
            //    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonAction:)];
            //[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            //UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
            //     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
            //   target:self action:@selector(refreshClicked:)] ;
            [self.navigationController pushViewController:shareWithView animated:YES];
            
        }
    
    }
   
    return;
    
 
    
}

-(void)publishNewMarkers{
    NSMutableArray *sidetones=[[NSMutableArray alloc] init];
    
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
            NSString *audioPathStr=[self.addedAudiosPath objectAtIndex:i];
            NSInteger index=button.tag;
            int pinI = (int)index;
            NSString *pin=[NSString stringWithFormat:@"%d",pinI];
            NSString *rectFrame = NSStringFromCGRect(self.headerView.photoImageView.frame);
            NSDictionary *sideToneData=[[NSMutableDictionary alloc] initWithObjectsAndKeys:rect,@"rect",audioPathStr,@"audio" ,rectFrame,@"frame",pin,@"pin",nil];
            
            [sidetones addObject:sideToneData];
            
            i++;
            
            
            
        }
    }
    if(sidetones)
    {
    //publish
        [[STParseHelper sharedInstance] publishSideToneData:[sidetones copy] withPhotoId:[photo objectId]];

        [self.addedAudiosPath removeAllObjects];
        [self.addedAudios removeAllObjects];
    
    }
    
}
- (void)activityButtonAction:(id)sender {
    
    
    
    ESShareWithFollowersViewController *shareWithView = [[ESShareWithFollowersViewController alloc] initWithStyle:UITableViewStyleGrouped andOption:@"Send To" andUser:self.user];
    [self.navigationController pushViewController:shareWithView animated:YES];
    shareWithView.photo=self.photo;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                       target:self action:@selector(refreshClicked:)] ;
  //  self.navigationItem.rightBarButtonItem = refreshButton;
   /* if (NSClassFromString(@"UIActivityViewController")) {
        // TODO: Need to do something when the photo hasn't finished downloading!
        if ([[self.photo objectForKey:kESPhotoPictureKey] isDataAvailable]) {
            [self showShareSheet];
        } else if ([[self.photo objectForKey:@"type"] isEqualToString:@"text"]) {
            [self showShareSheet];
        }
        else {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[self.photo objectForKey:kESPhotoPictureKey] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (!error) {
                    [self showShareSheet];
                }
            }];
        }
        
    }*/
}

-(void)refreshClicked:(id)sender{
    
    self.tabBarController.selectedIndex = 0;
 }
#pragma mark - ()

- (void)showShareSheet {
    if ([[self.photo objectForKey:@"type"] isEqualToString:@"text"]) {
        NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:3];
        
        // Prefill caption if this is the original poster of the photo, and then only if they added a caption initially.
        if ([[[PFUser currentUser] objectId] isEqualToString:[[self.photo objectForKey:kESPhotoUserKey] objectId]] && [self.objects count] > 0) {
            PFObject *firstActivity = self.objects[0];
            if ([[[firstActivity objectForKey:kESActivityFromUserKey] objectId] isEqualToString:[[self.photo objectForKey:kESPhotoUserKey] objectId]]) {
                NSString *commentString = [firstActivity objectForKey:kESActivityContentKey];
                [activityItems addObject:commentString];
            }
        }
        
        //[activityItems addObject:[NSURL URLWithString:[NSString stringWithFormat:@"https://.org/#pic/%@", self.photo.objectId]]];
        [activityItems addObject:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/"]]];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            activityViewController.popoverPresentationController.sourceView = self.navigationController.navigationBar;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
        });
    } else {
    
        [[self.photo objectForKey:kESPhotoPictureKey] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                
                NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:3];
                
                // Prefill caption if this is the original poster of the photo, and then only if they added a caption initially.
                if ([[[PFUser currentUser] objectId] isEqualToString:[[self.photo objectForKey:kESPhotoUserKey] objectId]] && [self.objects count] > 0) {
                    PFObject *firstActivity = self.objects[0];
                    if ([[[firstActivity objectForKey:kESActivityFromUserKey] objectId] isEqualToString:[[self.photo objectForKey:kESPhotoUserKey] objectId]]) {
                        NSString *commentString = [firstActivity objectForKey:kESActivityContentKey];
                        [activityItems addObject:commentString];
                    }
                }
                
                [activityItems addObject:[UIImage imageWithData:data]];
                //[activityItems addObject:[NSURL URLWithString:[NSString stringWithFormat:@"https://Netzwierk.org/#pic/%@", self.photo.objectId]]];
                [activityItems addObject:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id887017458"]]];
                
                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
                    activityViewController.popoverPresentationController.sourceView = self.navigationController.navigationBar;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
                });
                
            }
        }];

    }
    
}

- (void)handleCommentTimeout:(NSTimer *)aTimer {
    [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
            subTitle:NSLocalizedString(@"Your comment will be posted next time there is an Internet connection.", nil)
    closeButtonTitle:@"OK" duration:0.0f];
}

- (void)shouldPresentAccountViewForUser:(PFUser *)user {
    ESAccountViewController *accountViewController = [[ESAccountViewController alloc] initWithStyle:UITableViewStylePlain];
    [accountViewController setUser:user];
    [self.navigationController pushViewController:accountViewController animated:YES];
}

- (void)backButtonAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)userLikedOrUnlikedPhoto:(NSNotification *)note {
    [self.headerView reloadLikeBar];
}

- (void)keyboardWillShow:(NSNotification*)note {
    // Scroll the view to the comment text box
    NSDictionary* info = [note userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [self.tableView setContentOffset:CGPointMake(0.0f, self.tableView.contentSize.height-kbSize.height) animated:YES];
}

- (void)loadLikers {
    if (self.likersQueryInProgress) {
        return;
    }

    self.likersQueryInProgress = YES;
    
    PFQuery *query = [ESUtility queryForActivitiesOnPhoto:photo cachePolicy:kPFCachePolicyNetworkOnly];
    if ([photo objectForKey:kESVideoFileKey]) {
        query = [ESUtility queryForActivitiesOnVideo:photo cachePolicy:kPFCachePolicyNetworkOnly];
    }
    if ([[photo objectForKey:@"type"] isEqualToString:@"text"])
    {
        query = [ESUtility queryForActivitiesOnPost:photo cachePolicy:kPFCachePolicyNetworkOnly];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.likersQueryInProgress = NO;
        if (error) {
            [self.headerView reloadLikeBar];
            return;
        }
        
        NSMutableArray *likers = [NSMutableArray array];
        NSMutableArray *commenters = [NSMutableArray array];
        
        BOOL isLikedByCurrentUser = NO;
        
        for (PFObject *activity in objects) {
            if (([[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikePhoto] || [[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikeVideo] || [[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikePost])&& [activity objectForKey:kESActivityFromUserKey]) {
                [likers addObject:[activity objectForKey:kESActivityFromUserKey]];
            } else if (([[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeCommentPhoto]||[[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeCommentVideo] || [[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeCommentPost]) && [activity objectForKey:kESActivityFromUserKey]) {
                [commenters addObject:[activity objectForKey:kESActivityFromUserKey]];
            }
            
            if ([[[activity objectForKey:kESActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                if ([[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikePhoto] || [[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikeVideo] || [[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikePost]) {
                    isLikedByCurrentUser = YES;
                }
            }
        }
        
        
      //  [[ESCache sharedCache] setAttributesForPhoto:photo likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
       // [self.headerView reloadLikeBar];
    }];
}

- (BOOL)currentUserOwnsPhoto {
    return [[[self.photo objectForKey:kESPhotoUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]];
}

- (void)shouldDeletePhoto {
    // Delete all activites related to this photo
    PFQuery *query = [PFQuery queryWithClassName:kESActivityClassKey];
    [query whereKey:kESActivityPhotoKey equalTo:self.photo];
    [query findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity deleteEventually];
            }
        }
        
        // Delete photo
        [self.photo deleteInBackgroundWithBlock:^(BOOL result, NSError *error){
            if (!error) {
                NSLog(@"gay");
            }
        }];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:ESPhotoDetailsViewControllerUserDeletedPhotoNotification object:[self.photo objectId]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)shouldReportPhoto {
    PFObject *object = [PFObject objectWithClassName:@"Report"];
    [object setObject:photo forKey:@"ReportedPhoto"];
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            alert.backgroundType = Blur;
            [alert showNotice:self.tabBarController title:NSLocalizedString(@"Notice", nil) subTitle:NSLocalizedString(@"Photo has been successfully reported.", nil) closeButtonTitle:@"OK" duration:0.0f];
            
        }
        else {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                    subTitle:NSLocalizedString(@"Check your internet connection.", nil)
            closeButtonTitle:@"OK" duration:0.0f];
            NSLog(@"error %@",error);
        }
        
    }];
    
}

- (void)useNotificationWithString:(NSNotification *)notification {
    NSString *key = @"CommunicationStringValue";
    NSDictionary *dictionary = [notification userInfo];
    NSString *stringValueToUse = [dictionary valueForKey:key];
    ESHashtagTimelineViewController *hashtagSearch = [[ESHashtagTimelineViewController alloc] initWithStyle:UITableViewStyleGrouped andHashtag:stringValueToUse];
    [self.navigationController pushViewController:hashtagSearch animated:YES];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}
- (void)useNotificationWithMentionString:(NSNotification *)notification {
    NSString *key = @"CommunicationStringValue";
    NSDictionary *dictionary = [notification userInfo];
    NSString *stringValueToUse = [dictionary valueForKey:key];

    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"usernameFix" equalTo:stringValueToUse];
    //[ProgressHUD show:@"Loading..."];
    [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        [ProgressHUD dismiss];
        if (!error) {
            PFUser *mentionnedUser = (PFUser *)object;
            ESAccountViewController *accountViewController = [[ESAccountViewController alloc] initWithStyle:UITableViewStylePlain];
            [accountViewController setUser:mentionnedUser];
            [self.navigationController pushViewController:accountViewController animated:YES];
        }
        else [ProgressHUD showError:@"Network error"];
    }];
}
- (void)useNotificationWithWebsiteString:(NSNotification *)notification {
    NSString *key = @"CommunicationStringValue";
    NSDictionary *dictionary = [notification userInfo];
    NSString *stringValueToUse = [dictionary valueForKey:key];
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:stringValueToUse]];
    webViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:webViewController animated:YES];
}

@end
