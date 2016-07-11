//
//  _CLImageEditorViewController.h
//
//  Created by sho yakushiji on 2013/11/05.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageEditor.h"
#import "IQAudioRecorderController.h"

@interface _CLImageEditorViewController : CLImageEditor
<UIScrollViewDelegate, UIBarPositioningDelegate, UINavigationBarDelegate,UIGestureRecognizerDelegate,IQAudioRecorderControllerDelegate>
{
    IBOutlet __weak UINavigationBar *_navigationBar;
    IBOutlet __weak UIScrollView *_scrollView;
    int selectedPin ;
    UIButton *pin1;
    
    UIButton *pin2;
    
    UIButton *pin3;
    
    UIButton *pin4;
    UIColor *colorH;
   // UIButton *marker;
}
@property (nonatomic,retain)NSMutableArray *addedAudios; // contains array of markers
@property (nonatomic,retain)NSMutableArray *addedAudiosPath; // contains array of markers
@property (nonatomic) CGRect frameSize;
@property (nonatomic, strong) UIImageView  *imageView;
@property (nonatomic, weak) IBOutlet UIScrollView *menuView;
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture; /// handle tap gesture to show recording panel

- (IBAction)pushedCloseBtn:(id)sender;
- (IBAction)pushedFinishBtn:(id)sender;


- (id)initWithImage:(UIImage*)image;


- (void)fixZoomScaleWithAnimated:(BOOL)animated;
- (void)resetZoomScaleWithAnimated:(BOOL)animated;

@end
