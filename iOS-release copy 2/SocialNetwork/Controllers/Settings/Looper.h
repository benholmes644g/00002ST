#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Looper : NSObject <AVAudioPlayerDelegate> {
    AVAudioPlayer* player;
    NSArray* fileNameQueue;
    int index;
}

@property (nonatomic, retain) AVAudioPlayer* player;
@property (nonatomic, retain) NSArray* fileNameQueue;

- (id)initWithFileNameQueue:(NSArray*)queue;
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
- (void)play:(int)i;
- (void)stop;

@end