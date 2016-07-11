//
//  STParseHelper.m
//  SocialNetwork
//
//  Created by Hardik Rathore on 23/04/16.
//  Copyright © 2016 Eric Schanet. All rights reserved.
//

#import "STParseHelper.h"
 @implementation STParseHelper

@synthesize toUser,fromUser,final,fetching,blockList,unreadCount,lastrefresh;

+(STParseHelper *)sharedInstance{

    static STParseHelper *sharedInstance = nil;
    @synchronized(self) {
        if (sharedInstance == nil)
            
            sharedInstance = [[self alloc] init];
        sharedInstance.fetching = NO;
        sharedInstance.unreadCount=0;
    }
    return sharedInstance;


}

-(void)pullSharedPhotodata{
    [self performSelectorInBackground:@selector(parseUser) withObject:nil];
 }

-(void)parseUser{
    // to user
    if(self.fetching){
        return;
    }else{
        self.fetching = YES;
        self.unreadCount=0;
    }
    if (![PFUser currentUser]) {
        PFQuery *query = [PFQuery queryWithClassName:kESActivityClassKey];
        [query setLimit:0];
//query;
    }
    
    
    PFQuery *query = [PFQuery queryWithClassName:kESActivityClassKey];
    [query whereKey:kESActivityToUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kESActivityFromUserKey notEqualTo:[PFUser currentUser]];
    [query whereKey:kESActivityTypeKey equalTo:kESActivityTypeShare];
    [query whereKeyExists:kESActivityFromUserKey];
    [query whereKeyExists:kESActivityPhotoKey];
    [query orderByDescending:@"createdAt"];


    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
   


    //[query_ setCachePolicy:kPFCachePolicyNetworkOnly];
    
    //PFQuery *joint = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects: query,query_, nil]];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self fromUser:objects];
        
        }
    }];
    
    

}

-(void)fromUser:(NSArray *)objectstouser{
// get objectsfromuser
    PFQuery *query_= [PFQuery queryWithClassName:kESActivityClassKey];
    [query_ whereKey:kESActivityToUserKey notEqualTo:[PFUser currentUser]];
    [query_ whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
    [query_ whereKey:kESActivityTypeKey equalTo:kESActivityTypeShare];
    [query_ whereKeyExists:kESActivityToUserKey];
    [query_ whereKeyExists:kESActivityPhotoKey];
    [query_ orderByDescending:@"createdAt"];
    [query_ setCachePolicy:kPFCachePolicyNetworkOnly];



    
    
    [query_ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            
          //  BOOL done=NO;
            //[self fromUser:objects];
            self.lastrefresh = [NSDate date];
            [[NSUserDefaults standardUserDefaults] setObject:self.lastrefresh forKey:kESUserDefaultsActivityFeedViewControllerLastRefreshKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
           self.toUser = [self distinctUserShares:objectstouser isSender:NO];
            self.fromUser = [self distinctUserShares:objects isSender:YES];
            // BOOL done=NO;
[self swaparrays];
            self.fetching =NO;

        }
    }];
    
}
-(void)swaparrays{
    
    NSMutableArray *tempArra=[[NSMutableArray alloc] init];
    for (PFObject *activity in self.toUser) {
        
        PFUser *from = [activity objectForKey:kESActivityFromUserKey];
        for (PFObject *activityIn in self.fromUser) {
            PFUser *to = [activityIn objectForKey:kESActivityToUserKey];
            
            if([[from objectId] isEqual:[to objectId]]){
                [tempArra addObject:activityIn];
                //[self.fromUser removeObject:activityIn];
            }
            
        }
        
        
    }
    
    [self.fromUser removeObjectsInArray:tempArra];
    //return YE

}

-(NSMutableArray *)distinctUserShares:(NSArray *)objects isSender:(BOOL)sender{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sortKey=[[NSString alloc] init];
    NSString *sortKeyR=[[NSString alloc] init];

    if(sender){
    //fromuser is sender   kESActivityToUserKey
        sortKey = [NSString stringWithString:kESActivityToUserKey];
        sortKeyR = [NSString stringWithString:kESActivityFromUserKey];

        
    }else{
        //touser is sender kESActivityFromUserKey
        sortKey = [NSString stringWithString:kESActivityFromUserKey];
        sortKeyR = [NSString stringWithString:kESActivityToUserKey];


     }
    
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    NSMutableArray *tempObject = [NSMutableArray arrayWithArray:[objects copy]];
    for (PFObject *activity in tempObject) {
        [activity fetchIfNeeded];
        
        // if ([lastRefresh compare:[activity createdAt]] == NSOrderedAscending && ![[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeJoined]) {
      //  BOOL willAddObject = true;
        PFUser *user = [activity objectForKey:sortKey];
        PFUser *user_ = [activity objectForKey:sortKeyR];
        PFObject *photo = [activity objectForKey:kESActivityPhotoKey];
        [user fetchIfNeeded];
        if([temp count] <1){
            
            [temp addObject:[user objectId]];
          [user_ fetchIfNeeded];
           [photo fetchIfNeeded];
            if(![self.blockList containsObject:[user objectId]])
            { [result addObject:activity];}
            
            if ([self.lastrefresh compare:[activity createdAt]] == NSOrderedAscending && ![[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeJoined]) {
                self.unreadCount++;
            }
            NSLog(@"********ADD OBJECT %@",[user objectId]);
        }else{
            
            if([temp containsObject:[user objectId]]){
               // willAddObject = false;
                
            }else{
                [temp addObject:[user objectId]];
                [user_ fetchIfNeeded];
                [photo fetchIfNeeded];
                if(![self.blockList containsObject:[user objectId]])
                    [result  addObject:activity];
                NSLog(@"********ADD OBJECT");
                if ([self.lastrefresh compare:[activity createdAt]] == NSOrderedAscending && ![[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeShare]) {
                    self.unreadCount++;
                }
                
            }
            
        }
        
        
    }
    
    return result;

}


#pragma side tone audio publishing


-(void)publishSideToneData:(NSMutableArray *)sidetones withPhotoId:(NSString *)objectId{

    NSMutableDictionary *args=[[NSMutableDictionary alloc] initWithObjectsAndKeys:sidetones,@"sidetones",objectId,@"objectId", nil];
    
    [self performSelectorInBackground:@selector(publishSTD:) withObject:args];

}

-(void)publishSTD:(NSMutableDictionary *)args{
    // Field keys
//    NSString *const kSideToneUserKey                 =@"userid";
//    NSString *const kSideTonePhotoIdKey              =@"photoid";
//    NSString *const kSideToneCGRectKey               =@"location";
//    NSString *const kSideToneAudioKey                =@"tone";

    NSLog(@"**** sidetones : %@",args);
    
    NSMutableArray * sidetones = [args objectForKey:@"sidetones"];
    NSString *objectId = [args objectForKey:@"objectId"];// id of photo
    //int pinTag = [args objectForKey:@"pin"];
    for(NSDictionary *sidetone in sidetones){
        
        NSString * rect = [sidetone objectForKey:@"rect"];
        NSString * audioPath = [sidetone objectForKey:@"audio"];
        NSString * pinTag = [sidetone objectForKey:@"pin"];
        NSString *fileName= [audioPath lastPathComponent];
        NSString * frame = [sidetone objectForKey:@"frame"];
        PFFile * imgFile = [sidetone objectForKey:@"img"];

        if([pinTag isEqualToString:@"5"]){
        NSData *audioData = [NSData dataWithContentsOfFile:audioPath];
        PFFile *audioFile = [PFFile fileWithName:fileName data:audioData];
        [audioFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            
            if(succeeded){
                PFObject * object = [PFObject objectWithClassName:kSideToneClassKey];
                [object setObject:rect forKey:kSideToneCGRectKey];
                [object setObject:objectId forKey:kSideTonePhotoIdKey];
                [object setObject:audioFile forKey:kSideToneAudioKey];
                [object setObject:@"" forKey:@"textvalue"];

               // [object setObject:audioFile forKey:kSideToneAudioKey];
                [object setObject:pinTag forKey:kSideTonePinKey];
                [object setObject:frame forKey:kSideToneFrameKey];


                [object setObject:[[PFUser currentUser] objectId] forKey:kSideToneUserKey];
                [object saveInBackground];
            
            }
            
        }];
        }else if([pinTag isEqualToString:@"8"]){
            PFObject * object = [PFObject objectWithClassName:kSideToneClassKey];
            [object setObject:rect forKey:kSideToneCGRectKey];
            [object setObject:objectId forKey:kSideTonePhotoIdKey];
            [object setObject:audioPath forKey:@"textvalue"];
            [object removeObjectForKey:kSideToneAudioKey];
            // [object setObject:audioFile forKey:kSideToneAudioKey];
            [object setObject:pinTag forKey:kSideTonePinKey];
            [object setObject:frame forKey:kSideToneFrameKey];
            
            [object setObject:imgFile forKey:@"img"];
            [object setObject:[[PFUser currentUser] objectId] forKey:kSideToneUserKey];
            [object saveInBackground];

            
        }else if([pinTag isEqualToString:@"9"]){
            PFObject * object = [PFObject objectWithClassName:kSideToneClassKey];
            [object setObject:rect forKey:kSideToneCGRectKey];
            [object setObject:objectId forKey:kSideTonePhotoIdKey];
            [object setObject:audioPath forKey:@"textvalue"];
            [object setObject:imgFile forKey:@"img"];
            
            [object removeObjectForKey:kSideToneAudioKey];
            // [object setObject:audioFile forKey:kSideToneAudioKey];
            [object setObject:pinTag forKey:kSideTonePinKey];
            [object setObject:frame forKey:kSideToneFrameKey];
            
            
            [object setObject:[[PFUser currentUser] objectId] forKey:kSideToneUserKey];
            [object saveInBackground];
            
        }else if([pinTag isEqualToString:@"10"]){
            PFObject * object = [PFObject objectWithClassName:kSideToneClassKey];
            [object setObject:rect forKey:kSideToneCGRectKey];
            [object setObject:objectId forKey:kSideTonePhotoIdKey];
            [object setObject:audioPath forKey:@"textvalue"];
            [object setObject:imgFile forKey:@"img"];
            
            [object removeObjectForKey:kSideToneAudioKey];
            // [object setObject:audioFile forKey:kSideToneAudioKey];
            [object setObject:pinTag forKey:kSideTonePinKey];
            [object setObject:frame forKey:kSideToneFrameKey];
            
            
            [object setObject:[[PFUser currentUser] objectId] forKey:kSideToneUserKey];
            [object saveInBackground];
            
        }else{
            PFObject * object = [PFObject objectWithClassName:kSideToneClassKey];
            [object setObject:rect forKey:kSideToneCGRectKey];
            [object setObject:objectId forKey:kSideTonePhotoIdKey];
            [object setObject:audioPath forKey:@"textvalue"];
            [object removeObjectForKey:kSideToneAudioKey];
            // [object setObject:audioFile forKey:kSideToneAudioKey];
            [object setObject:pinTag forKey:kSideTonePinKey];
            [object setObject:frame forKey:kSideToneFrameKey];
            
            
            [object setObject:[[PFUser currentUser] objectId] forKey:kSideToneUserKey];
            [object saveInBackground];
        }
        


    }
    
    
}


-(NSMutableArray *)getSideToneForImageId:(NSString *)objectId{
    NSMutableArray *sidetones;// = [[NSMutableArray alloc] init];
    
    PFQuery *query = [PFQuery queryWithClassName:kSideToneClassKey];
    [query whereKey:kSideTonePhotoIdKey equalTo:objectId];
    //[query whereKeyExists:kSideToneAudioKey];
    
    NSArray *array = [query findObjects];
    sidetones=[[NSMutableArray alloc] initWithArray:array];
    return sidetones;
}


-(void)prepareBlockList{
    
    if(self.blockList == nil){
        self.blockList = [[NSMutableArray alloc] init];
    
    }
    //block
    PFQuery *query = [PFQuery queryWithClassName:@"blocklist"];
    
     [query whereKey:kESActivityToUserKey notEqualTo:[PFUser currentUser]];

    [query whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kESActivityTypeKey equalTo:kESActivityBlockKey];
    [query whereKeyExists:kESActivityToUserKey];
    [query orderByAscending:@"createdAt"];

      [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    
    
    
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if([self.blockList count]>0){
                [self.blockList removeAllObjects];
            
            }
           // NSLog(@"%@",objects);
            for (PFObject *obj in objects) {
            
                PFUser *blockedUser= [obj objectForKey:kESActivityToUserKey];
                [self.blockList addObject:[blockedUser objectId]];
            
            }

           
            
        }
    }];

    
 
   // return blocked;


}

@end
