//
//  STParseHelper.h
//  SocialNetwork
//
//  Created by Hardik Rathore on 23/04/16.
//  Copyright © 2016 Eric Schanet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
@interface STParseHelper : NSObject{

}
@property (nonatomic , retain)    NSMutableArray *final;

@property (nonatomic , retain)    NSMutableArray *toUser;
@property (nonatomic , retain)    NSMutableArray *blockList;

@property (nonatomic , retain)    NSMutableArray *fromUser;
@property (nonatomic )       BOOL fetching ;
@property (nonatomic) NSUInteger unreadCount;
@property (nonatomic,retain) NSDate * lastrefresh;

+(STParseHelper *)sharedInstance;
-(void)pullSharedPhotodata;

-(void)publishSideToneData:(NSMutableArray *)sidetones withPhotoId:(NSString *)objectId;
-(NSMutableArray *)getSideToneForImageId:(NSString *)objectId;



-(void)prepareBlockList;
@end
