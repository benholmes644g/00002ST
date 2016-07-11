//
//  ESFindFriendsViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "ESFindFriendsViewController.h"
#import "ESShareWithFollowersViewController.h"


@implementation ESShareWithFollowersViewController
@synthesize headerView,searchQuery;
@synthesize followStatus;
@synthesize selectedEmailAddress;
@synthesize outstandingFollowQueries;
@synthesize outstandingCountQueries, queriedUsers, user,photo,objectsData;
#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style andOption:(NSString *)option andUser:(PFUser *)_user{
    self = [super initWithStyle:style];
    if (self) {
        
        user = _user;
        self.option = option;
        self.sharedStats = @"NO";
        self.outstandingFollowQueries = [NSMutableDictionary dictionary];
        self.outstandingCountQueries = [NSMutableDictionary dictionary];
        
        self.selectedEmailAddress = @"";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        self.loadingViewEnabled = YES;
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 1000;
        
        // Used to determine Follow/Unfollow All button status
        self.followStatus = ESFindFriendsFollowingSome;
    }
    return self;
}


#pragma mark - UIViewController
- (void)viewWillAppear:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.container.panMode = MFSideMenuPanModeDefault;
}
-(void)refreshClicked:(id)sender {
    
   // NSMutableArray *viewControllers = [NSMutableArray arrayWithArray: self.navigationController.viewControllers];

   // [viewControllers removeObjectIdenticalTo:self];
   // [viewControllers addObject:shareWithView];
    
 //   [self.navigationController setViewControllers: viewControllers animated: YES];

    
    [self.tabBarController setSelectedIndex:0];

    [self.navigationController popToRootViewControllerAnimated:FALSE];
    

//   [self.navigationController popViewControllerAnimated:YES] ;
//    if([viewControllers count]>1){
//        [self.navigationController popViewControllerAnimated:YES] ;
//
//    }
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    objectsData = [[NSMutableArray alloc] init];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(refreshClicked:)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = 0.0;
    self.tableView.sectionFooterHeight = 0.0;
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    [texturedBackgroundView setBackgroundColor:[UIColor colorWithWhite:0.90 alpha:1]];
    self.tableView.backgroundView = texturedBackgroundView;
    
    self.navigationItem.title = self.option;
    
    if ([MFMailComposeViewController canSendMail] || [MFMessageComposeViewController canSendText]) {
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 67)];
        [self.headerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundFindFriendsCell"]]];
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [clearButton setBackgroundColor:[UIColor clearColor]];
        [clearButton addTarget:self action:@selector(inviteFriendsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [clearButton setFrame:self.headerView.frame];
        [self.headerView addSubview:clearButton];
        NSString *inviteString = NSLocalizedString(@"Invite friends", @"Invite friends");
        CGRect boundingRect = [inviteString boundingRectWithSize:CGSizeMake(310.0f, CGFLOAT_MAX)
                                                         options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:18.0f]}
                                                         context:nil];
        CGSize inviteStringSize = boundingRect.size;
        
        UILabel *inviteLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, (self.headerView.frame.size.height-inviteStringSize.height)/2, inviteStringSize.width, inviteStringSize.height)];
        [inviteLabel setText:inviteString];
        [inviteLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [inviteLabel setTextColor:[UIColor colorWithRed:87.0f/255.0f green:72.0f/255.0f blue:49.0f/255.0f alpha:1.0]];
        [inviteLabel setBackgroundColor:[UIColor clearColor]];
        [self.headerView addSubview:inviteLabel];
        UIImageView *separatorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SeparatorTimeline"]];
        [separatorImage setFrame:CGRectMake(0, self.headerView.frame.size.height-2, [UIScreen mainScreen].bounds.size.width, 2)];
        [self.headerView addSubview:separatorImage];
        [self.tableView setTableHeaderView:self.headerView];
    }
    
    
    //Search friends
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    
    self.tableView.tableHeaderView = self.searchBar;
    
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    self.searchController.delegate = self;
    
    self.searchResults = [NSMutableArray array];
    self.queriedUsers = [NSMutableArray array];
}

//search query
-(void)filterResults:(NSString *)searchTerm {
    if ([searchTerm isEqualToString:@""]) {
        return;
    }
    if (self.searchQuery) {
        [self.searchQuery cancel];
    }
    [self.searchResults removeAllObjects];
    
    searchQuery = [PFQuery queryWithClassName:@"_User"];
    [searchQuery whereKeyExists:kESUserDisplayNameKey];  //this is based on whatever query you are trying to accomplish
    [searchQuery whereKeyExists:@"username"]; //this is based on whatever query you are trying to accomplish
    [searchQuery whereKey:kESUserDisplayNameLowerKey containsString:[searchTerm lowercaseString]];
    [searchQuery whereKey:@"usernameFix" notEqualTo:[user objectForKey:@"usernameFix"]];
    [searchQuery whereKey:kESUserObjectIdKey containedIn:self.queriedUsers];
    [self.searchQuery findObjectsInBackgroundWithBlock:^(NSArray
                                                         *objects, NSError *error)
     {
         [self.searchResults removeAllObjects];
         [self.searchResults addObjectsFromArray:objects];
         [self.searchController.searchResultsTableView
          reloadData];
         self.searchQuery = nil;
     }];
}


-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterResults:searchString];
    return YES;
}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    

    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
   // [query whereKey:kESActivityTypeKey equalTo:kESActivityTypeFollow];
    [query orderByAscending:kESUserDisplayNameKey];

    if ([self.option isEqualToString:@"Following"]) {
      //  [query whereKey:kESActivityFromUserKey equalTo:user];
     //   [query includeKey:kESActivityToUserKey];
    }
    else {
      //  [query whereKey:kESActivityToUserKey equalTo:user];
       // [query includeKey:kESActivityFromUserKey];
    }
    return query;
    
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"%@",self.objects);
    [self.objectsData removeAllObjects];
    for (PFUser *object in self.objects) {
        
        
      if(![([STParseHelper sharedInstance]).blockList containsObject:[object objectId]]){
          [queriedUsers addObject:object.objectId];
          [self.objectsData addObject:object];
          
      }

       // if ([self.option isEqualToString:@"Following"]) {
       // PFUser *_user = (PFUser *)object ;//objectForKey:kESActivityToUserKey];
          //  [queriedUsers addObject:_user.objectId];
     //   }
       // else {
          //  PFUser *_user = (PFUser *)[object objectForKey:kESActivityFromUserKey];
           // [queriedUsers addObject:_user.objectId];
      //  }
    }
    [self.tableView reloadData];
}
- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    // overridden, since we want to implement sections
    if (indexPath.row < self.objectsData.count) {
        return [self.objectsData objectAtIndex:indexPath.row];
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate and DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objectsData.count) {
       // NSLog(@"HEIGHT_____ %f", [ESFindFriendsCell heightForCell]);
        return [ESFindFriendsCell heightForCell];
    } else {
        return 44.0f;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        //  if (tableView == self.searchDisplayController.searchResultsTableView) {
        NSInteger rows = self.objectsData.count;
        if (self.paginationEnabled && rows != 0)
            rows++;
        return rows;
        
    } else {
        
        return self.searchResults.count;
        
    }

    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    if (tableView == self.tableView) {
        // this is complete list of users
        static NSString *FriendCellIdentifier = @"FriendCell";
        
        if (indexPath.row== self.objectsData.count) {
            // this behavior is normally handled by PFQueryTableViewController, but we are using sections for each object and we must handle this ourselves
            UITableViewCell *cell = [self tableView:tableView cellForNextPageAtIndexPath:indexPath];
            return cell;
        } else {
            PFUser *_user = [[PFUser alloc]init];
            ESFindFriendsCell *cell = [tableView dequeueReusableCellWithIdentifier:FriendCellIdentifier];
            if (cell == nil) {
                cell = [[ESFindFriendsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FriendCellIdentifier];
                [cell.followButton setTitle:@"Send" forState:UIControlStateNormal];
                [cell.followButton setTitle:@"Sent" forState:UIControlStateSelected];
                [cell.followButton setSelected:NO];

                [cell setDelegate:self];
            }
            if ([self.sharedStats isEqualToString:@"YES"]) {

                 //[cell.followButton setSelected:YES];
                _user = (PFUser*)object;//[object objectForKey:kESActivityToUserKey];
                if ([user.objectId isEqualToString:[PFUser currentUser].objectId]) {
                    [cell.followButton setEnabled:NO];
                }
                
            }
            else {
                _user = (PFUser*)object;// objectForKey:kESActivityFromUserKey];
            }
            if (!_user) {
                [object deleteInBackground];
                
                [self loadObjects];
                
            }
            [cell setUser:_user];
            [cell.photoLabel setHidden:YES];
            
            NSDictionary *attributes = [[ESCache sharedCache] attributesForUser:_user];
            
            cell.followButton.selected = NO;
            cell.tag = indexPath.row;
            if ([self.option isEqualToString:@"Following"]) {
              //  [cell.followButton setSelected:YES];
            }
            else if (self.followStatus == ESFindFriendsFollowingSome) {
                if (attributes) {
                  //  [cell.followButton setSelected:[[ESCache sharedCache] followStatusForUser:_user]];
                } else {
                    @synchronized(self) {
                        NSNumber *outstandingQuery = [self.outstandingFollowQueries objectForKey:indexPath];
                        if (!outstandingQuery) {
                            [self.outstandingFollowQueries setObject:[NSNumber numberWithBool:YES] forKey:indexPath];
                            PFQuery *isFollowingQuery = [PFQuery queryWithClassName:kESActivityClassKey];
                            [isFollowingQuery whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
                            [isFollowingQuery whereKey:kESActivityTypeKey equalTo:kESActivityTypeShare];
                            [isFollowingQuery whereKey:kESActivityToUserKey equalTo:_user];
                            [isFollowingQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
                            
                            [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                                @synchronized(self) {
                                    [self.outstandingFollowQueries removeObjectForKey:indexPath];
                                   // [[ESCache sharedCache] setFollowStatus:(!error && number > 0) user:_user];
                                }
                                if (cell.tag == indexPath.row) {
                                   // [cell.followButton setSelected:(!error && number > 0)];
                                }
                            }];
                        }
                    }
                }
            } else {
                //[cell.followButton setSelected:(self.followStatus == ESFindFriendsFollowingAll)];
            }
            if ([_user.objectId isEqualToString:[PFUser currentUser].objectId]) {
                [cell.followButton setEnabled:NO];
            }
            return cell;
        }
    }
    else {
        NSString *uniqueIdentifier = @"peopleCell";
        ESFindFriendsCell *cell = nil;
        
        //cell = (UITableViewCell *) [self.tableView dequeueReusableCellWithIdentifier:uniqueIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:uniqueIdentifier];
        
        if (!cell) {
            cell = [[ESFindFriendsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:uniqueIdentifier];
            [cell setDelegate:self];
        }
        PFUser *obj2 = [self.searchResults objectAtIndex:indexPath.row];
        [cell setUser:(PFUser *)obj2];
        cell.followButton.selected = NO;
        cell.tag = indexPath.row;
        NSDictionary *attributes = [[ESCache sharedCache] attributesForUser:(PFUser *)obj2];
        [cell.photoLabel setText:NSLocalizedString(@"0 photos", nil)];
        
        if (attributes) {
            // set them now
            NSNumber *number = [[ESCache sharedCache] photoCountForUser:(PFUser *)obj2];
            [cell.photoLabel setText:[NSString stringWithFormat:@"%@ photo%@", number, [number intValue] == 1 ? @"": NSLocalizedString(@"s", nil)]];
        } else {
            @synchronized(self) {
                NSNumber *outstandingCountQueryStatus = [self.outstandingCountQueries objectForKey:indexPath];
                if (!outstandingCountQueryStatus) {
                    [self.outstandingCountQueries setObject:[NSNumber numberWithBool:YES] forKey:indexPath];
                    PFQuery *photoNumQuery = [PFQuery queryWithClassName:kESPhotoClassKey];
                    [photoNumQuery whereKey:kESPhotoUserKey equalTo:(PFObject *)obj2];
                    [photoNumQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
                    [photoNumQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                        @synchronized(self) {
                            [[ESCache sharedCache] setPhotoCount:[NSNumber numberWithInt:number] user:(PFUser *)obj2];
                            [self.outstandingCountQueries removeObjectForKey:indexPath];
                        }
                        ESFindFriendsCell *actualCell = (ESFindFriendsCell*)[tableView cellForRowAtIndexPath:indexPath];
                        NSString *photoString = [NSString stringWithFormat:NSLocalizedString(@"photo", nil)];
                        [actualCell.photoLabel setText:[NSString stringWithFormat:@"%d %@%@", number, photoString, number == 1 ? @"" : NSLocalizedString(@"s", nil)]];
                    }];
                };
            }
        }
        
        if (self.followStatus == ESFindFriendsFollowingSome) {
            if (attributes) {
                [cell.followButton setSelected:[[ESCache sharedCache] followStatusForUser:obj2]];
            } else {
                @synchronized(self) {
                    NSNumber *outstandingQuery = [self.outstandingFollowQueries objectForKey:indexPath];
                    if (!outstandingQuery) {
                        [self.outstandingFollowQueries setObject:[NSNumber numberWithBool:YES] forKey:indexPath];
                        PFQuery *isFollowingQuery = [PFQuery queryWithClassName:kESActivityClassKey];
                        [isFollowingQuery whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
                        [isFollowingQuery whereKey:kESActivityTypeKey equalTo:kESActivityTypeFollow];
                        [isFollowingQuery whereKey:kESActivityToUserKey equalTo:(PFObject *)obj2];
                        [isFollowingQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
                        
                        [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                            @synchronized(self) {
                                [self.outstandingFollowQueries removeObjectForKey:indexPath];
                                [[ESCache sharedCache] setFollowStatus:(!error && number > 0) user:(PFUser *)obj2];
                            }
                            if (cell.tag == indexPath.row) {
                                [cell.followButton setSelected:(!error && number > 0)];
                            }
                        }];
                    }
                }
            }
        } else {
           // [cell.followButton setSelected:(self.followStatus == ESFindFriendsFollowingAll)];
        }
        
        
        return cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
    
    ESLoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
    if (!cell) {
        cell = [[ESLoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
        cell.selectionStyle =UITableViewCellSelectionStyleGray;
        cell.separatorImageTop.image = [UIImage imageNamed:@"SeparatorTimelineDark"];
        cell.hideSeparatorBottom = YES;
        cell.mainView.backgroundColor = [UIColor clearColor];
        
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == self.objectsData.count && self.paginationEnabled) {
        // Load More Cell
        [self loadNextPage];
    }
}


#pragma mark - ESFindFriendsCellDelegate

- (void)cell:(ESFindFriendsCell *)cellView didTapUserButton:(PFUser *)aUser {
    // Push account view controller
    ESAccountViewController *accountViewController = [[ESAccountViewController alloc] initWithStyle:UITableViewStylePlain];
    [accountViewController setUser:aUser];
    [self.navigationController pushViewController:accountViewController animated:YES];
}

- (void)cell:(ESFindFriendsCell *)cellView didTapFollowButton:(PFUser *)aUser {
    [self shouldToggleFollowFriendForCell:cellView];
    
    
}


#pragma mark - ABPeoplePickerDelegate

/* Called when the user cancels the address book view controller. We simply dismiss it. */
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/* Called when a member of the address book is selected, we return YES to display the member's details. */
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    return YES;
}

/* Called when the user selects a property of a person in their address book (ex. phone, email, location,...)
 This method will allow them to send a text or email inviting them to d'Netzwierk.  */
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    if (property == kABPersonEmailProperty) {
        
        ABMultiValueRef emailProperty = ABRecordCopyValue(person,property);
        NSString *email = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emailProperty,identifier);
        self.selectedEmailAddress = email;
        
        if ([MFMailComposeViewController canSendMail]) {
            // go directly to mail
            [self presentMailComposeViewController:email];
        } else if ([MFMessageComposeViewController canSendText]) {
            // go directly to iMessage
            [self presentMessageComposeViewController:email];
        }
        
    } else if (property == kABPersonPhoneProperty) {
        ABMultiValueRef phoneProperty = ABRecordCopyValue(person,property);
        NSString *phone = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneProperty,identifier);
        
        if ([MFMessageComposeViewController canSendText]) {
            [self presentMessageComposeViewController:phone];
        }
    }
    
    return NO;
}

#pragma mark - MFMailComposeDelegate

/* Simply dismiss the MFMailComposeViewController when the user sends an email or cancels */
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MFMessageComposeDelegate

/* Simply dismiss the MFMessageComposeViewController when the user sends a text or cancels */
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    if (buttonIndex == 0) {
        [self presentMailComposeViewController:self.selectedEmailAddress];
    } else if (buttonIndex == 1) {
        [self presentMessageComposeViewController:self.selectedEmailAddress];
    }
}

#pragma mark - ()

- (void)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)inviteFriendsButtonAction:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        ESPhoneContacts *addressBookView = [[ESPhoneContacts alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addressBookView];
        [self presentViewController:navController animated:YES completion:nil];
    });
}

- (void)shouldToggleFollowFriendForCell:(ESFindFriendsCell*)cell {
    PFUser *cellUser = cell.user;
    if ([cell.followButton isSelected]) {
        // unshare
        cell.followButton.selected = NO;
        [ESUtility unshareUserEventually:cellUser image:self.photo];

               // [ESUtility unfollowUserEventually:cellUser];
       // [[NSNotificationCenter defaultCenter] postNotificationName:ESUtilityUserFollowingChangedNotification object:nil];
    } else {
        // share
        cell.followButton.selected = YES;
        [ESUtility shareUserEventually:cellUser image:self.photo block:^(BOOL succeeded, NSError *error) {
            if (!error) {
                //  [[NSNotificationCenter defaultCenter] postNotificationName:ESUtilityUserFollowingChangedNotification object:nil];
            } else {
                cell.followButton.selected = NO;
            }
        }];

       //        [ESUtility followUserEventually:cellUser block:^(BOOL succeeded, NSError *error) {
//            if (!error) {
//              //  [[NSNotificationCenter defaultCenter] postNotificationName:ESUtilityUserFollowingChangedNotification object:nil];
//            } else {
//                cell.followButton.selected = NO;
//            }
//        }];
    }
}

- (void)presentMailComposeViewController:(NSString *)recipient {
    // Create the compose email view controller
    MFMailComposeViewController *composeEmailViewController = [[MFMailComposeViewController alloc] init];
    
    // Set the recipient to the selected email and a default text
    [composeEmailViewController setMailComposeDelegate:self];
    [composeEmailViewController setSubject:NSLocalizedString(@"Join me on d'Netzwierk", nil)];
    [composeEmailViewController setToRecipients:[NSArray arrayWithObjects:recipient, nil]];
    [composeEmailViewController setMessageBody:@"<h2>Share your pictures, share your story.</h2><p><a href=\"itms-apps://itunes.apple.com/app/id887017458\">d'Netzwierk</a> is the easiest way to share photos with your friends. Get the app and share your fun photos with the world.</p><p><a href=\"itms-apps://itunes.apple.com/app/id887017458\">d'Netzwierk</a> is fully powered by the luxembourgish developers Eric Schanet and Yannick Erpelding." isHTML:YES];
    
    // Dismiss the current modal view controller and display the compose email one.
    // Note that we do not animate them. Doing so would require us to present the compose
    // mail one only *after* the address book is dismissed.
    [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:composeEmailViewController animated:NO completion:nil];
}

- (void)presentMessageComposeViewController:(NSString *)recipient {
    // Create the compose text message view controller
    MFMessageComposeViewController *composeTextViewController = [[MFMessageComposeViewController alloc] init];
    
    // Send the destination phone number and a default text
    [composeTextViewController setMessageComposeDelegate:self];
    [composeTextViewController setRecipients:[NSArray arrayWithObjects:recipient, nil]];
    [composeTextViewController setBody:NSLocalizedString(@"Check out d'Netzwierk! itms-apps://itunes.apple.com/app/id887017458", nil)];
    
    // Dismiss the current modal view controller and display the compose text one.
    // See previous use for reason why these are not animated.
    [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:composeTextViewController animated:NO completion:nil];
}

@end
