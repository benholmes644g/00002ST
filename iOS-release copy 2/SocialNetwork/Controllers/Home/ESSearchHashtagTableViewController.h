//
//  ESSearchHashtagTableViewController.h
//  d'Netzwierk
//
//  Created by Eric Schanet on 04.12.14.
//
//

#import <UIKit/UIKit.h>

@interface ESSearchHashtagTableViewController : UITableViewController <UISearchBarDelegate, UIAlertViewDelegate>

{
    int count;
}
@property (nonatomic,retain)NSMutableArray  *dataList;
@property (nonatomic,retain)NSMutableArray  *searchResult;

@end
