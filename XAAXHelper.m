//
//  XAAXHelper.m
//  VoIPClient
//
//  Created by Vinh Thien on 11/15/16.
//  Copyright © 2016 Vinh Thien. All rights reserved.
//

#import "XAAXHelper.h"

#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AVBufferPlayer.h"

#import "xaax_sip_helper.h"

#define DB_NAME @"test.db"


NSString *const kXAAXGetContactMatchedNotification = @"XAAXGetContactMatched";
NSString *const kXAAXGetLastCalledNumberNotification = @"XAAXGetLastCalledNumber";
NSString *const kXAAXAllCallHistoryReturnNotification = @"XAAXAllCallHistoryReturnNotification";
NSString *const kXAAXRegistrationUpdateNotification = @"XAAXRegistrationUpdateNotification";
NSString *const kXAAXCallUpdateNotification     = @"XAAXCallUpdateNotification";

@implementation XAAccount

@end

@implementation XACodec

@end

@implementation XAContact

@end

@interface XADigitMap : NSObject
    @property (nonatomic, assign) char digit;
    @property (nonatomic, assign) int freq1;
    @property (nonatomic, assign) int freq2;
    @property (nonatomic, strong) AVBufferPlayer *player;
@end
@implementation XADigitMap

@end

@implementation XAAXHelper {
    NSMutableArray<XADigitMap *>* digitMaps;
}

static XAAXHelper *_XAAXHelper;



+ (id)shareInstance {
    if (_XAAXHelper == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _XAAXHelper = [[XAAXHelper alloc] init];
            [_XAAXHelper initDigitMap];
        });
    }
    return _XAAXHelper;
}


- (void)initDigitMap {
    digitMaps = [[NSMutableArray<XADigitMap*> alloc] init];
    XADigitMap *map = [[XADigitMap alloc] init];
    map.digit = '0'; map.freq1 = 941; map.freq2 = 1336;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '1'; map.freq1 = 697; map.freq2 = 1209;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '2'; map.freq1 = 697; map.freq2 = 1336;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '3'; map.freq1 = 697; map.freq2 = 1477;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '4'; map.freq1 = 770; map.freq2 = 1209;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '5'; map.freq1 = 770; map.freq2 = 1336;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '6'; map.freq1 = 770; map.freq2 = 1477;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '7'; map.freq1 = 852; map.freq2 = 1209;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '8'; map.freq1 = 852; map.freq2 = 1336;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '9'; map.freq1 = 852; map.freq2 = 1477;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = 'a'; map.freq1 = 697; map.freq2 = 1633;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = 'b'; map.freq1 = 770; map.freq2 = 1633;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = 'c'; map.freq1 = 852; map.freq2 = 1633;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = 'd'; map.freq1 = 941; map.freq2 = 1633;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '*'; map.freq1 = 941; map.freq2 = 1209;
    [digitMaps addObject:map];
    map = [[XADigitMap alloc] init];
    map.digit = '#'; map.freq1 = 941; map.freq2 = 1477;
    [digitMaps addObject:map];
    
    for (XADigitMap *temp in digitMaps) {
        const int freq1 = temp.freq1;
        const int freq2 = temp.freq2;
        const int seconds = 10;
        const int sampleRate = 44100;
        const float gain = 0.5f;
        
        int frames = seconds * sampleRate;
        float *buffer = (float *)malloc(frames * sizeof(float));
        
        for (int i = 0; i < frames; i++)
        {
            // DTMF signal
            buffer[i] = gain * (sinf(i*2.0f*M_PI*freq1/sampleRate) + sinf(i*2.0f*M_PI*freq2/sampleRate));
            
            // Simple 440Hz sine wave
            //buffer[i] = gain * sinf(i*2.0f*M_PI*440.0f/sampleRate)
        }
        
        temp.player = [[AVBufferPlayer alloc] initWithBuffer:buffer frames:frames];
        
        free(buffer);
        
    }
}

- (void) start {
    NSString *documents = [self applicationDocumentsDirectory];
    NSString *dbPath = [documents stringByAppendingPathComponent:DB_NAME];
    xaax_init(dbPath.UTF8String);
    
    xaax_cb_set_contact_matched_returned(&cb_get_contact_matched);
    xaax_cb_set_last_called_number_returned(&cb_get_last_called_number);
    xaax_cb_set_all_call_history_returned(&cb_all_call_history_return);
    xaax_cb_set_registration_update(&cb_registration_update);
    xaax_cb_set_call_update(&cb_call_update);
    
}

- (int) countActiveCalls {
    return xaax_count_active_calls();
}

- (NSString*) getCurrentIncallRemoteUsername {
    return [NSString stringWithUTF8String:get_current_incall_remote_username()];
}

- (XAAccount*) getDefaultAccount {
    const char *username, *domain, *displayName, *proxy, *transport, *port;
    char *password;
    int result = get_default_account(&username, &password, &domain, &transport, &displayName, &proxy, &port);
    if (result == -1) {
        return nil;
    }
    XAAccount *account = [[XAAccount alloc] init];
    account.username = [NSString stringWithUTF8String:username];
    account.password = [NSString stringWithUTF8String:password];
    account.domain = [NSString stringWithUTF8String:domain];
    account.transport = [NSString stringWithUTF8String:transport];
    account.port = [NSString stringWithUTF8String:port];
//    account.displayName = [NSString stringWithUTF8String:displayName];
    
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    int count = [self getCodecsCount];
    for (int index = 0; index < count; index++) {
        XACodec *xacodecs = [self getCodecs:index];
        [list addObject:xacodecs];
    }
    
    account.codecs = list;
    
    account.proxy = account.domain;
    
    return account;
}

- (bool) refreshAccounts {
    int result = xaax_refresh_accounts();
    if (result == 1) { // no account to refresh
        return false;
    }
    return true;
}

- (void) saveAccountWithUsername:(NSString*)username password:(NSString*)password domain:(NSString*)domain transport:(NSString*)transport port:(NSString*)port {
    xaax_remove_all_account();
    xaax_add_account([username UTF8String], [password UTF8String], [domain UTF8String], [transport.lowercaseString UTF8String], [port UTF8String]);
}

- (void) checkAccountRegistrationWithUsername:(NSString*)username domain:(NSString*)domain {
    xaax_check_account_registration(username.UTF8String, domain.UTF8String);
}

- (void) sendDtmf:(NSString*)username digit:(NSString*)digit {
    if (digit.length > 0) {
        xaax_send_dtmf([username UTF8String], [digit UTF8String][0]);
    }
}

- (void) playDtmf:(NSString*)digit {
    if (digit.length > 0 && digitMaps != nil) {
//        xaax_call_play_digit([digit UTF8String][0]);
        
        char digitChar = [digit UTF8String][0];
        
        XADigitMap *selectedMap = nil;
        for (XADigitMap *map in digitMaps) {
            if (map.digit == digitChar) {
                selectedMap = map;
            }
        }
        
        [selectedMap.player play];
    }
}
    
- (void) playDtmf:(NSString*)digit remote:(NSString*)remote {
    if (digit.length > 0) {
        [self playDtmf:digit];
        xaax_call_play_digit_by_remote([digit UTF8String][0], [remote UTF8String]);
    }
}

- (void) stopPlayDtmf {
    for (XADigitMap *map in digitMaps) {
        [map.player stop];
    }
}


- (int) makeSingleCallWithUsername:(NSString*)username contactId:(NSString*)contactId contactName:(NSString*)contactName {
    return xaax_make_single_call([username UTF8String], [contactId UTF8String], [contactName UTF8String]);
}

- (bool) hangupCallWithCallId:(int)callid {
    return xaax_hangup_call_by_callid(callid);
}

- (bool) hangupCallWithRemote:(NSString*)username {
    return xaax_hangup_call_by_remote([username UTF8String]);
}

- (void) acceptCallWithCallId:(int)callid {
    xaax_accept_call_by_callid(callid);
}
- (void) acceptCallWithRemote:(NSString*)username {
    xaax_accept_call_by_remote([username UTF8String]);
}

- (void) pauseCallWithCallId:(int)callid {
    xaax_pause_call_by_callid(callid);
}
- (void) pauseCallWithRemote:(NSString*)username {
    xaax_pause_call_by_remote([username UTF8String]);
}
- (void) resumeCallWithCallId:(int)callid {
    xaax_resume_call_by_callid(callid);
}
- (void) resumeCallWithRemote:(NSString*)username {
    xaax_resume_call_by_remote([username UTF8String]);
}

- (void) muteWithCallId:(int)callid {
    xaax_mute_by_callid(callid);
}
- (void) muteWithRemote:(NSString*)username {
    xaax_mute_by_remote([username UTF8String]);
}


- (void) unmuteWithCallId:(int)callid {
    xaax_unmute_by_callid(callid);
}
- (void) unmuteWithRemote:(NSString*)username {
    xaax_unmute_by_remote([username UTF8String]);
}

- (void) getLastCalledNumber {
    xaax_get_last_called_number();
}

- (int) getAllCallHistory {
    int count = 0;
    xaax_get_all_call_history(&count);
    return count;
}

- (void) deleteCallHistory:(int) callHistoryId {
    xaax_delete_call_history(callHistoryId);
}

- (void) deleteAllCallHistory {
    xaax_delete_all_call_history();
}

- (int) getCodecsCount {
    unsigned int count = 0;
    xaax_codecs_get_count(&count);
    return count;
}

- (XACodec*) getCodecs:(int)index  {
    char *codec;
    unsigned priority;
    
    xaax_codecs_get_id(index, &codec, &priority);
    
    XACodec *xacodecs = [[XACodec alloc] init];
    xacodecs.codecId = [NSString stringWithUTF8String:codec];
    xacodecs.index = index;
    xacodecs.priority = priority;
    xacodecs.enabled = (priority > 0);
    return xacodecs;
}

- (void) changeCodecProWithCodecId:(int)codecId enable:(bool)enable {
    xaax_codecs_change(codecId, true);
}


- (void) saveContactWithContactId:(NSString*)contactId contactName:(NSString*)contactName phoneNumber1:(NSString*)phoneNumber1 phoneNumber2:(NSString*)phoneNumber2 phoneNumber3:(NSString*)phoneNumber3 {
    
    
    
    NSString *outboundNumber1 = [[NSString alloc] initWithUTF8String:""];
    NSString *outboundNumber2 = [[NSString alloc] initWithUTF8String:""];
    NSString *outboundNumber3 = [[NSString alloc] initWithUTF8String:""];
    if (phoneNumber1.length > 0) {
        outboundNumber1 = [NSString stringWithFormat:@"00%@", phoneNumber1];
    }
    if (phoneNumber2.length > 0) {
        outboundNumber2 = [NSString stringWithFormat:@"00%@", phoneNumber2];
    }
    if (phoneNumber3.length > 0) {
        outboundNumber3 = [NSString stringWithFormat:@"00%@", phoneNumber3];
    }
    
    xaax_insert_contact([contactId UTF8String], [contactName UTF8String], [phoneNumber1 UTF8String], [phoneNumber2 UTF8String], [phoneNumber3 UTF8String], XA_FALSE, XA_FALSE, XA_FALSE, [outboundNumber1 UTF8String], [outboundNumber2 UTF8String], [outboundNumber3 UTF8String], XA_FALSE);
}

- (XAContact*) selectContactMatched:(NSString*)sipNumber {
    int count;
    char *contactId;
    char *contactName;
    xaax_select_contact_matched([sipNumber UTF8String], &count, &contactId, &contactName);
    if (count > 0) {
        XAContact *contact = [[XAContact alloc] init];
        contact.contactId = [NSString stringWithUTF8String:contactId];
        contact.contactName = [NSString stringWithUTF8String:contactName];
        return contact;
    }
    return nil;
}

- (void) deleteAllContacts {
    xaax_delete_all_contacts();
}


#pragma mark - Audio route Functions

- (void)setSpeakerEnabled:(BOOL)enable {
    OSStatus ret;
    UInt32 override = kAudioSessionUnspecifiedError;
    
    if (override != kAudioSessionNoError) {
        if (enable) {
            override = kAudioSessionOverrideAudioRoute_Speaker;
            ret = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(override), &override);
        } else {
            override = kAudioSessionOverrideAudioRoute_None;
            ret = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(override), &override);
        }
    }
    
    if (ret != kAudioSessionNoError) {
        NSLog(@"Failed to change audio route: err %d", (int)ret);
    }
}

#pragma - CALLBACK functions


static void cb_get_contact_matched(const char * contact_id) {
    
    NSDictionary *objects = @{ @"contact_id"   : [NSString stringWithUTF8String:contact_id] };
    [[NSNotificationCenter defaultCenter] postNotificationName:kXAAXGetContactMatchedNotification object:nil userInfo:objects];
}

static void cb_get_last_called_number(const char * last_called_number) {
    
    NSDictionary *objects = @{ @"last_called_number"   : [NSString stringWithUTF8String:last_called_number] };
    [[NSNotificationCenter defaultCenter] postNotificationName:kXAAXGetLastCalledNumberNotification object:nil userInfo:objects];
}

static void cb_all_call_history_return(int call_history_id,
                                       int call_id,
                                       const char * caller_username,
                                       const char * callee_username,
                                       const char * domain,
                                       const char * remote_username,
                                       int duration,
                                       time_t start_date,
                                       int direction,
                                       int state,
                                       const char * callee_contact_number,
                                       const char * callee_contact_name,
                                       const char * callee_contact_id) {

    NSDictionary *objects = @{ @"call_history_id"   : [NSNumber numberWithInt:call_history_id],
                               @"call_id"   : [NSNumber numberWithInt:call_id],
                               @"caller_username"   : [NSString stringWithUTF8String:caller_username],
                               @"callee_username"   : [NSString stringWithUTF8String:callee_username],
                               @"domain"   : [NSString stringWithUTF8String:domain],
                               @"remote_username"   : [NSString stringWithUTF8String:remote_username],
                               @"duration"   : [NSNumber numberWithInt:duration],
                               @"start_date"   : [NSNumber numberWithLong:start_date],
                               @"direction"   : [NSNumber numberWithInt:direction],
                               @"state"   : [NSNumber numberWithInt:state],
                               @"callee_contact_number"   : callee_contact_number ? [NSString stringWithUTF8String:callee_contact_number] : @"",
                               @"callee_contact_name"   : callee_contact_name ? [NSString stringWithUTF8String:callee_contact_name] : @"",
                               @"callee_contact_id"   : callee_contact_id ? [NSString stringWithUTF8String:callee_contact_id] : @""};
    [[NSNotificationCenter defaultCenter] postNotificationName:kXAAXAllCallHistoryReturnNotification object:nil userInfo:objects];
}

static void cb_registration_update( const char * username, const char * domain, xaax_status_t status ) {
    
    NSDictionary *objects = @{ @"username" : [NSString stringWithUTF8String:username],
                               @"status"   : [NSNumber numberWithInt:status] };
    [[NSNotificationCenter defaultCenter] postNotificationName:kXAAXRegistrationUpdateNotification object:nil userInfo:objects];
}

static void cb_call_update( const char * username, const char * remote_contact_name, const char * domain, long duration, xaax_status_t status ) {
    NSDictionary *objects = @{ @"remote_username" : [NSString stringWithUTF8String:username],
                               @"remote_contact_name" : [NSString stringWithUTF8String:remote_contact_name],
                               @"status"   : [NSNumber numberWithInt:status],
                               @"duration"   : [NSNumber numberWithLong:duration]};
    [[NSNotificationCenter defaultCenter] postNotificationName:kXAAXCallUpdateNotification object:nil userInfo:objects];
}


#pragma - Private functions

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}



@end
