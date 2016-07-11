//
//  ESEditPhotoViewController.h
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

//#import "GPUImage.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import "IQAudioRecorderController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "STParseHelper.h"
#import "VLDContextSheet.h"
#import "TOWebViewController.h"
#import "CruiserWebViewController.h"
#import "DZNWebViewController.h"
 /**
 *  Interface of the EditPhotoViewController. In this last controller before the uplad, the user has the possibility to add a comment to his filtered and edited photo.
 */
@interface ESEditPhotoViewController : UIViewController <UITextFieldDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate, CLLocationManagerDelegate,UIGestureRecognizerDelegate,IQAudioRecorderControllerDelegate,VLDContextSheetDelegate,UIAlertViewDelegate>
{
    /**
     *  Geocoder, containing the geolocation information of the photo.
     */
    CLGeocoder *geocoder;
    /**
     *  Placemark, based on the geolocation we have.
     */
    CLPlacemark *placeMark;
    CLLocationManager *locationManager;
    /**
     *  Location string. This string is displayed and contains the nearest city or state where the photo has been taken.
     */
    NSString *localityString;
    
    NSMutableArray *sidetones;// array of dictionary of marker's CGRect and audiofile path which will be uploaded on server through STparserHelper
    
    int selectedPin ;
    UIButton *pin1;
    
    UIButton *pin2;
    
    UIButton *pin3;
    
    UIButton *pin4;
    UIColor *colorH;
    BOOL doneButtonCalled;
    UITextField *alertText;
    UITextField *alertUrl;
    
    
    UINavigationController *navController; 
    UINavigationController *navController1;
    UINavigationController *navController2;
    TOWebViewController *webViewController1 ;
    TOWebViewController *webViewController;
    TOWebViewController *webViewController2;

    int activeNavbar; // 0 for fb 1 twitter
    int activeIndex;


    
}
/**
 *  Scrollview containing all the subviews.
 */
@property (nonatomic ,retain)VLDContextSheet *contextSheet;
@property (nonatomic)CGPoint longPressPosition;
@property (strong, atomic) ALAssetsLibrary* library;
@property(nonatomic,retain)NSMutableArray *addedAudios,*addedAudiosPath;
@property (nonatomic)CGRect frameSize;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture; /// handle tap gesture to show recording panel
-(void)actionMarker:(id)sender;

/**
 *  The actual photo everything here is all about.
 */
@property (nonatomic, strong) UIImage *image;
/**
 *  Textfield that lets the user type in a comment.
 */
@property (nonatomic, strong) UITextField *commentTextField;
/**
 *  PFFile of the photo, will be uploaded to Parse.
 */
@property (nonatomic, strong) PFFile *photoFile;
/**
 *  PFFile of the photo thumbnail, will be uploaded to Parse.
 */
@property (nonatomic, strong) PFFile *thumbnailFile;
/**
 *  ID of the file upload backgroundtask.
 */
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
/**
 *  ID of the post backgroundtask.
 */
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;
/**
 *  ImageView containing the actual photo.
 */
@property (nonatomic, strong) UIImageView *photoImageView;
/**
 *  Custom init method, we want to init the controller with an image.
 *
 *  @param aImage the actual image we display in the controller
 */
- (id)initWithImage:(UIImage *)aImage;
/**
 *  We call this method right at the beginning, even if the user has not yet decided to upload the photo. This ensures, that the photo has valid data and infos and that a background task is available to upload it later on.
 *
 *  @param anImage the photo that will be uploaded
 *
 *  @return YES if the user presents all the necessary data, NO if not.
 */
- (BOOL)shouldUploadImage:(UIImage *)anImage;
/**
 *  The keyboard will show, slightly displace all the subviews upward so that they are not completely hidden by the keyboard.
 */
- (void)keyboardWillShow:(NSNotification *)note;
/**
 *  Keyboard will hide, displace all the subviews back into their original position.
 */
- (void)keyboardWillHide:(NSNotification *)note;
/**
 *  User wants to upload the photo, thus we upload
 */
- (void)doneButtonAction:(id)sender;
/**
 * User doesn't want to publish the photo and we dismiss the viewcontroller.
 */
- (void)cancelButtonAction:(id)sender;


@end
