

#import "Looper.h"
@implementation Looper
@synthesize player, fileNameQueue;

- (id)initWithFileNameQueue:(NSArray*)queue {
    if ((self = [super init])) {
        self.fileNameQueue = queue;
        index = 0;
        [self play:index];
    }
    return self;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (index < fileNameQueue.count) {
        [self play:index];
    } else {
        //reached end of queue
    }
}

- (void)play:(int)i {
    
    
    NSError *error = [[NSError alloc] init];
    self.player=[[AVAudioPlayer alloc] initWithData:[fileNameQueue objectAtIndex:i] error:&error];

    //self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:[fileNameQueue objectAtIndex:i] ofType:nil]] error:nil];
   // [player release];
    player.delegate = self;
    [player prepareToPlay];
    [player play];
    index++;
}

- (void)stop {
    if (self.player.playing) [player stop];
}

- (void)dealloc {
    self.fileNameQueue = nil;
    self.player = nil;
    //[super dealloc];
}
@end
