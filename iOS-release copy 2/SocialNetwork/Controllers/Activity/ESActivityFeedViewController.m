//
//  ESActivityFeedViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "ESActivityFeedViewController.h"
#import "ESPhotoTimelineViewController.h"
#import "STParseHelper.h"
@implementation ESActivityFeedViewController

@synthesize settingsActionSheetDelegate;
@synthesize lastRefresh;
@synthesize blankTimelineView,dataset,dataset_;
static STParseHelper *myInstance;

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // The className to query on
        self.parseClassName = kESActivityClassKey;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        self.loadingViewEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 100;
    }
    return self;
}

#pragma mark - UIViewController
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // Your code to update the parent view
    
    //[self tryLoadingData];

}
- (void)viewWillAppear:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.container.panMode = MFSideMenuPanModeDefault;
    [myInstance pullSharedPhotodata];

    //[self tryLoadingData];
    
}

-(void)tryLoadingData{
//[self loadTableView];
  //  return;
    if(myInstance.fetching){
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                       ^(void){
                           //your code here
                           [self tryLoadingData];
                       });
       // [self performSelector:@selector(tryLoadingData) withObject:nil afterDelay:1.0f];
    }else{
        if(!enableCustomPullToRefresh){
            enableCustomPullToRefresh=YES;
        }
        [self loadTableView];
    }

}

- (void)viewDidLoad {
    
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(tapBtn)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
    bgjob=FALSE;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.dataset = [[NSMutableArray alloc] init];
    self.dataset_ = [[NSMutableArray alloc] init];

    [super viewDidLoad];
    myInstance = [STParseHelper sharedInstance];
    myInstance.refActivity = self;
     [myInstance pullSharedPhotodata];
    UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    [texturedBackgroundView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundLeather"]]];
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
    
    // self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveRemoteNotification:) name:ESAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    
    self.blankTimelineView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:[UIImage imageNamed:@"ActivityFeedBlank"] forState:UIControlStateNormal];
    [button setFrame:CGRectMake( [UIScreen mainScreen].bounds.size.width/2 - 253/2, 103.0f, 253.0f, 165.0f)];
    [button addTarget:self action:@selector(inviteFriendsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.blankTimelineView addSubview:button];
    
    lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:kESUserDefaultsActivityFeedViewControllerLastRefreshKey];
   // [self tryLoadingData];
    
}
-(void)tapBtn {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        //[self setupMenuBarButtonItems];
    }];
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   
     if(indexPath.section == 0){
    if (indexPath.row < self.dataset.count) {
        PFObject *object = [self.dataset objectAtIndex:indexPath.row];
        NSString *activityString;
        
       
           // activityString = [ESActivityFeedViewController stringForActivityType: :NO];
            activityString = [ESActivityFeedViewController stringForActivityType:(NSString*)[object objectForKey:kESActivityTypeKey] type:NO];
       

        
        PFUser *user = (PFUser*)[object objectForKey:kESActivityFromUserKey];
        NSString *nameString = NSLocalizedString(@"Someone", nil);
        if (user && [user objectForKey:kESUserDisplayNameKey] && [[user objectForKey:kESUserDisplayNameKey] length] > 0) {
            nameString = [user objectForKey:kESUserDisplayNameKey];
        }
        
        return [ESActivityCell heightForCellWithName:nameString contentString:activityString];
    } else {
        return 44.0f;
    }
     }else{
     
         if (indexPath.row < self.dataset_.count) {
             PFObject *object = [self.dataset_ objectAtIndex:indexPath.row];
             NSString *activityString;
             
             
             // activityString = [ESActivityFeedViewController stringForActivityType: :NO];
             activityString = [ESActivityFeedViewController stringForActivityType:(NSString*)[object objectForKey:kESActivityTypeKey] type:YES];
             
             
             
             PFUser *user = (PFUser*)[object objectForKey:kESActivityToUserKey];
             NSString *nameString = NSLocalizedString(@"Someone", nil);
             if (user && [user objectForKey:kESUserDisplayNameKey] && [[user objectForKey:kESUserDisplayNameKey] length] > 0) {
                 nameString = [user objectForKey:kESUserDisplayNameKey];
             }
             
             return [ESActivityCell heightForCellWithName:nameString contentString:activityString];
         } else {
             return 44.0f;
         }

     }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *dataSource = [[NSMutableArray alloc] init];
    if(indexPath.section == 1){
        dataSource = [self.dataset_ copy];
    }else{
        dataSource = [self.dataset copy];

    
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < dataSource.count) {
        PFObject *activity = [dataSource objectAtIndex:indexPath.row];
        if ([activity objectForKey:kESActivityPhotoKey]) {
            PFObject *photo = [activity objectForKey:kESActivityPhotoKey];
            if ([photo objectForKeyedSubscript:@"videoThumbnail"]) {
                ESVideoDetailViewController *photoViewController = [[ESVideoDetailViewController alloc] initWithPhoto:photo];
                [self.navigationController pushViewController:photoViewController animated:YES];
            }
            else {
                ESPhotoTimelineViewController *photoViewController =[[ESPhotoTimelineViewController alloc] init];
               
                if(indexPath.section == 1){
                    photoViewController.queryType = 0;
                        photoViewController.user1=[activity objectForKey:kESActivityFromUserKey];
                      photoViewController.user2=[activity objectForKey:kESActivityToUserKey];
                }else{
                    photoViewController.queryType = 4;

                    photoViewController.user1=[activity objectForKey:kESActivityFromUserKey];
                    photoViewController.user2=[activity objectForKey:kESActivityToUserKey];
                    
                }
               
                
                // ESPhotoDetailsViewController *photoViewController = [[ESPhotoDetailsViewController alloc] initWithPhoto:photo];
                [self.navigationController pushViewController:photoViewController animated:YES];
            }
            
        } else if ([activity objectForKey:kESActivityFromUserKey]) {
            ESAccountViewController *detailViewController = [[ESAccountViewController alloc] initWithStyle:UITableViewStylePlain];
            [detailViewController setUser:[activity objectForKey:kESActivityFromUserKey]];
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
    } else if (self.paginationEnabled) {
        // load more
        [self loadNextPage];
    }
}

#pragma mark - PFQueryTableViewController
- (nullable PFObject *)objectAtIndexPath:(nullable NSIndexPath *)indexPath{
    
    switch (indexPath.section) {
        case 0:
            //
            if([self.dataset count]>0){
                return [self.dataset objectAtIndex:indexPath.row];
            }

            break;
            
        case 1:
            //
            if([self.dataset_ count]>0){
                return [self.dataset_ objectAtIndex:indexPath.row];
            }

            break;
            
        default:
            return nil;

    }
    return nil;

}
- (PFQuery *)queryForTable {
    if(enableCustomPullToRefresh){

     [myInstance pullSharedPhotodata];
    [self tryLoadingData];
    }
    return nil;

   
    if (![PFUser currentUser]){
        PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
        [query setLimit:0];
        return query;
    }
    PFQuery *mentionQuery = [PFQuery queryWithClassName:self.parseClassName];
    [mentionQuery whereKey:@"mentions" equalTo:[PFUser currentUser]];
    [mentionQuery whereKey:kESActivityFromUserKey notEqualTo:[PFUser currentUser]];
    [mentionQuery whereKeyExists:kESActivityFromUserKey];
    
    [mentionQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:kESActivityToUserKey equalTo:[PFUser currentUser]];
    //[query whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
    [query whereKeyExists:kESActivityFromUserKey];
    
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
   
    
    PFQuery *endQuery = [PFQuery queryWithClassName:self.parseClassName];
    [endQuery orderByDescending:@"createdAt"];
    // [endQuery includeKey:kESActivityFromUserKey];
    [endQuery includeKey:kESActivityPhotoKey];
    [endQuery whereKey:kESActivityToUserKey equalTo:[PFUser currentUser]];
    [endQuery whereKey:kESActivityTypeKey equalTo:kESActivityTypeShare];
    
    PFQuery *startQuery = [PFQuery queryWithClassName:self.parseClassName];
    // [startQuery orderByDescending:@"createdAt"];
    //  [startQuery includeKey:kESActivityToUserKey];
    //  [startQuery includeKey:kESActivityPhotoKey];
    [startQuery whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
    [startQuery whereKey:kESActivityTypeKey equalTo:kESActivityTypeShare];
    
    
    //[endQuery includeKey:@"mentions"];
    PFQuery *querys = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects: startQuery,endQuery, nil]];
    // [query includeKey:kESPhotoUserKey];
    [querys orderByDescending:@"createdAt"];
    [querys includeKey:kESActivityPhotoKey];
    [querys includeKey:kESActivityPhotoKey];
    
    // A pull-to-refresh should always trigger a network request.
    [querys setCachePolicy:kPFCachePolicyNetworkOnly];
    if (self.dataset.count == 0 || ![[[UIApplication sharedApplication]delegate] performSelector:@selector(isParseReachable)]) {
        [endQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
    if (self.dataset.count == 0 || ![[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]) {
        [querys setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }
    
    
    return query;
}

-(void)loadTableView{
    //
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [MBProgressHUD hideHUDForView:self.tableView animated:YES];

    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//        
//        
//        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
//        UIView *topView = window.rootViewController.view;
//        if([topView isKindOfClass:[MBProgressHUD class]]){
//            [topView removeFromSuperview];
//        }
//        
//
//    });
       // [self egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    
    
    NSUInteger unreadCount = 0;
    
    if(myInstance.fetching){
    }else{
        unreadCount =0;//= myInstance.unreadCount;//[myInstance.fromUser count] + [myInstance.toUser count];
        self.lastRefresh =myInstance.lastrefresh;
        [self.dataset removeAllObjects];
        [self.dataset_ removeAllObjects];
        [self.dataset addObjectsFromArray:myInstance.toUser];

        [self.dataset_ addObjectsFromArray:myInstance.fromUser];
       // self.dataset = [myInstance.fromUser copy];
    }
    if ((self.dataset.count == 0 && self.dataset_.count == 0)&& ![[self queryForTable] hasCachedResult]) {
        self.tableView.scrollEnabled = NO;
        self.navigationController.tabBarItem.badgeValue = nil;
        
        if (!self.blankTimelineView.superview) {
            self.blankTimelineView.alpha = 0.0f;
            self.tableView.tableHeaderView = self.blankTimelineView;
            
            [UIView animateWithDuration:0.200f animations:^{
                self.blankTimelineView.alpha = 1.0f;
            }];
        }
    } else {
        self.tableView.tableHeaderView = nil;
        self.tableView.scrollEnabled = YES;
        
        
        
        if (unreadCount > 0) {
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)unreadCount];
        } else {
            self.navigationController.tabBarItem.badgeValue = nil;
        }
        
    }
    
    //if(self.pullToRefreshEnabled)
        [self.tableView reloadData];
    //[MBProgressHUD hideHUDForView:self.view animated:YES];
    NSError *error;
    [super objectsDidLoad:error];
    
    [self.refreshControl endRefreshing];
    

}
/*- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
         lastRefresh = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:lastRefresh forKey:kESUserDefaultsActivityFeedViewControllerLastRefreshKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    NSUInteger unreadCount = 0;
    
    if(myInstance.fetching){
    }else{
        unreadCount = [myInstance.fromUser count];
        self.dataset = [myInstance.fromUser copy];
    }
        if (self.dataset.count == 0 && ![[self queryForTable] hasCachedResult]) {
            self.tableView.scrollEnabled = NO;
            self.navigationController.tabBarItem.badgeValue = nil;
            
            if (!self.blankTimelineView.superview) {
                self.blankTimelineView.alpha = 0.0f;
                self.tableView.tableHeaderView = self.blankTimelineView;
                
                [UIView animateWithDuration:0.200f animations:^{
                    self.blankTimelineView.alpha = 1.0f;
                }];
            }
        } else {
            self.tableView.tableHeaderView = nil;
            self.tableView.scrollEnabled = YES;
            
           
            
            if (unreadCount > 0) {
                self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)unreadCount];
            } else {
                self.navigationController.tabBarItem.badgeValue = nil;
            }
            
        }
         // [self.dataset removeAllObjects];
        //[self performSelectorInBackground:@selector(backgroundDataSet) withObject:nil];
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //            [self backgroundDataSet];
        //        });
    
}
*/
//- (void)objectsDidLoad:(NSError *)error {
//    [super objectsDidLoad:error];
//    if(!bgjob){
//        bgjob=TRUE;
//        lastRefresh = [NSDate date];
//        [[NSUserDefaults standardUserDefaults] setObject:lastRefresh forKey:kESUserDefaultsActivityFeedViewControllerLastRefreshKey];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        
//        [MBProgressHUD hideHUDForView:self.view animated:YES];
//        
//        if (self.dataset.count == 0 && ![[self queryForTable] hasCachedResult]) {
//            self.tableView.scrollEnabled = NO;
//            self.navigationController.tabBarItem.badgeValue = nil;
//            
//            if (!self.blankTimelineView.superview) {
//                self.blankTimelineView.alpha = 0.0f;
//                self.tableView.tableHeaderView = self.blankTimelineView;
//                
//                [UIView animateWithDuration:0.200f animations:^{
//                    self.blankTimelineView.alpha = 1.0f;
//                }];
//            }
//        } else {
//            self.tableView.tableHeaderView = nil;
//            self.tableView.scrollEnabled = YES;
//            
//            NSUInteger unreadCount = 0;
//            
//            NSMutableArray *temp = [[NSMutableArray alloc] init];
//            
//            NSMutableArray *tempObject = [NSMutableArray arrayWithArray:[self.objects copy]];
//            for (PFObject *activity in tempObject) {
//                [activity fetch];
//                // if ([lastRefresh compare:[activity createdAt]] == NSOrderedAscending && ![[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeJoined]) {
//                BOOL willAddObject = true;
//                if([temp count] <1){
//                    PFUser *fromUser = [activity objectForKey:kESActivityFromUserKey];
//                    [fromUser fetch];
//                    [temp addObject:[fromUser objectId]];
//                    unreadCount++;
//                    [self.dataset addObject:activity];
//                    NSLog(@"********ADD OBJECT %@",[fromUser objectId]);
//                }else{
//                    PFUser *fromUser = [activity objectForKey:kESActivityFromUserKey];
//                    [fromUser fetch];
//                    if([temp containsObject:[fromUser objectId]]){
//                        willAddObject = false;
//                        
//                    }else{
//                        
//                        unreadCount++;
//                        [self.dataset addObject:activity];
//                        NSLog(@"********ADD OBJECT");
//                        
//                    }
//                    
//                }
//                
//                if(willAddObject){
//                }
//                // }
//            }
//            
//            if (unreadCount > 0) {
//                self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)unreadCount];
//            } else {
//                self.navigationController.tabBarItem.badgeValue = nil;
//            }
//            
//        }
//        bgjob = false;
//       // [self.dataset removeAllObjects];
//        //[self performSelectorInBackground:@selector(backgroundDataSet) withObject:nil];
////        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
////            [self backgroundDataSet];
////        });
//    }
//}

-(void)backgroundDataSet{
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2; //one shred to your and share by you
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return [self.dataset count];
    }
    else{
        return [self.dataset_ count];
}
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"ActivityCell";
    
    ESActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ESActivityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setDelegate:self];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    }
    if(indexPath.section==1){
        [cell setSender:YES];
        [cell hideSeparator:(indexPath.row == self.dataset_.count - 1)];
        
    }else{
        [cell setSender:NO];
        
        [cell hideSeparator:(indexPath.row == self.dataset.count - 1)];
        
    }
    
    [cell setActivity:object];
    
    if ([lastRefresh compare:[object createdAt]] == NSOrderedAscending) {
        [cell setIsNew:YES];
    } else {
        [cell setIsNew:NO];
    }
    
    
    
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
    
    ESLoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
    if (!cell) {
        cell = [[ESLoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.hideSeparatorBottom = YES;
        cell.mainView.backgroundColor = [UIColor clearColor];
    }
    return cell;
}


#pragma mark - ESActivityCellDelegate Methods

- (void)cell:(ESActivityCell *)cellView didTapActivityButton:(PFObject *)activity {
    // Get image associated with the activity
    PFObject *photo = [activity objectForKey:kESActivityPhotoKey];
    if ([photo objectForKeyedSubscript:@"videoThumbnail"]) {
        ESVideoDetailViewController *photoViewController = [[ESVideoDetailViewController alloc] initWithPhoto:photo];
        [self.navigationController pushViewController:photoViewController animated:YES];
    }
    else {
        
      //  ESPhotoTimelineViewController *photoViewController =[[ESPhotoTimelineViewController alloc] init];
      //  photoViewController.queryType = 1;
        //photoViewController.user1=[activity objectForKey:kESActivityFromUserKey];
         ESPhotoDetailsViewController *photoViewController = [[ESPhotoDetailsViewController alloc] initWithPhoto:photo];
        [self.navigationController pushViewController:photoViewController animated:YES];
    }
}

- (void)cell:(ESBaseTextCell *)cellView didTapUserButton:(PFUser *)user {
    // Push account view controller
    ESAccountViewController *accountViewController = [[ESAccountViewController alloc] initWithStyle:UITableViewStylePlain];
    [accountViewController setUser:user];
    [self.navigationController pushViewController:accountViewController animated:YES];
}


#pragma mark - ESActivityFeedViewController

+ (NSString *)stringForActivityType:(NSString *)activityType type:(BOOL)sender{
    if ([activityType isEqualToString:kESActivityTypeLikePhoto]) {
        return NSLocalizedString(@"liked your photo", nil);
    } else if ([activityType isEqualToString:kESActivityTypeLikeVideo]) {
        return NSLocalizedString(@"liked your video", nil);
    } else if ([activityType isEqualToString:kESActivityTypeLikePost]) {
        return NSLocalizedString(@"liked your post", nil);
    } else if ([activityType isEqualToString:kESActivityTypeCommentVideo]) {
        return NSLocalizedString(@"commented on your video", nil);
    } else if ([activityType isEqualToString:kESActivityTypeCommentPost]) {
        return NSLocalizedString(@"commented on your post", nil);
    } else if ([activityType isEqualToString:kESActivityTypeFollow]) {
        return NSLocalizedString(@"started following you", nil);
    } else if ([activityType isEqualToString:kESActivityTypeCommentPhoto]) {
        return NSLocalizedString(@"commented on your photo", nil);
    } else if ([activityType isEqualToString:kESActivityTypeJoined]) {
        return NSLocalizedString(@"joined d'Netzwierk", nil);
    } else if ([activityType isEqualToString:kESActivityTypeMention]) {
        return NSLocalizedString(@"mentioned you in a comment", nil);
    }else if ([activityType isEqualToString:kESActivityTypeShare] && !sender) {
        return NSLocalizedString(@"has sent you a Sidetone.", nil);
    } else  if ([activityType isEqualToString:kESActivityTypeShare] && sender) {
        return NSLocalizedString(@"received a Sidetone from you.", nil);
    } else {
        return nil;
    }
}


#pragma mark - ()

- (void)settingsButtonAction:(id)sender {
    settingsActionSheetDelegate = [[ESSettingsActionSheetDelegate alloc] initWithNavigationController:self.navigationController];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:settingsActionSheetDelegate cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"My Profile", nil), NSLocalizedString(@"Find Friends", nil), NSLocalizedString(@"Log Out", nil), nil];
    
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)inviteFriendsButtonAction:(id)sender {
    ESFindFriendsViewController *detailViewController = [[ESFindFriendsViewController alloc] init];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)applicationDidReceiveRemoteNotification:(NSNotification *)note {
   // [self tryLoadingData];
}
@end
