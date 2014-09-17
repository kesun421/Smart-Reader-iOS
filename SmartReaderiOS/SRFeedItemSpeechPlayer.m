//
//  SRPlayFeedItems.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 2/15/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRFeedItemSpeechPlayer.h"
#import "MWFeedItem.h"
#import "MWFeedInfo.h"
#import <AVFoundation/AVFoundation.h>

@interface SRFeedItemSpeechPlayer () <AVSpeechSynthesizerDelegate>
{
    int _index;
    BOOL _spokeTitle;
    BOOL _spokeSummary;
}

@property (nonatomic) AVSpeechSynthesizer *speechSynth;

@end

@implementation SRFeedItemSpeechPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _index = 0;
        self.speechSynth = [AVSpeechSynthesizer new];
        self.speechSynth.delegate = self;
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static SRFeedItemSpeechPlayer *feedItemSpeechPlayer;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
         feedItemSpeechPlayer = [SRFeedItemSpeechPlayer new];
    });
    
    return  feedItemSpeechPlayer;
}

- (void)play
{
    [self.delegate playingFeedItemAtIndex:[NSIndexPath indexPathForRow:_index inSection:0]];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    MWFeedItem *feedItem = self.feedItems[_index];
    
    NSString *utteranceString;
    
    if (!_spokeTitle) {
        DebugLog(@"Reading feed item: %@", feedItem);
        
        if (feedItem.source.feedInfo.title.length && feedItem.title.length) {
            NSString *title = [NSString stringWithFormat:@"Article from \"%@\": %@", feedItem.source.feedInfo.title, feedItem.title];
            utteranceString = title;
        }
        else if (feedItem.title.length) {
            utteranceString = feedItem.title;
        }
        
        _spokeTitle = YES;
    }
    else if (!_spokeSummary){
        if (feedItem.summary.length) {
            utteranceString = feedItem.summary;
        }
        else if (feedItem.content.length) {
            utteranceString = feedItem.content;
        }
        
        _spokeSummary = YES;
    }
    
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:utteranceString];
    utterance.postUtteranceDelay = 1.0;
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.30;
    [self.speechSynth speakUtterance:utterance];
}

- (void)pause
{
    
}

- (void)stop
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    DebugLog(@"Stopping speech synthesizer...");
    
    _index = 0;
    _spokeTitle = _spokeSummary = NO;
    
    // Force the speech synth to reset in order to stop reading...
    [self.speechSynth stopSpeakingAtBoundary:AVSpeechBoundaryWord];
    self.speechSynth.delegate = nil;
    self.speechSynth = nil;
    self.speechSynth = [AVSpeechSynthesizer new];
    self.speechSynth.delegate = self;
}

#pragma mark - Speech Synthesizer Delegates

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    if (_spokeTitle && _spokeSummary) {
        _spokeTitle = _spokeSummary = NO;
        
        [self.delegate finishedPlayingFeedItemAtIndex:[NSIndexPath indexPathForRow:_index inSection:0]];
        
        _index++;
        if (_index > (self.feedItems.count - 1)) {
            [self.delegate finishedPlayingAllFeedItems];
            
            _index = 0;
            [self stop];
            return;
        }
    }
    
    [self play];
}

@end
