//
//  XAAXHelper.h
//  VoIPClient
//
//  Created by Vinh Thien on 11/15/16.
//  Copyright © 2016 Vinh Thien. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "xaax_common.h"


extern NSString *const kXAAXGetContactMatchedNotification;
extern NSString *const kXAAXGetLastCalledNumberNotification;
extern NSString *const kXAAXAllCallHistoryReturnNotification;
extern NSString *const kXAAXRegistrationUpdateNotification;
extern NSString *const kXAAXCallUpdateNotification;


@interface XAAccount : NSObject

@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* domain;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) NSString* transport;
@property (nonatomic, strong) NSString* displayName;
@property (nonatomic, strong) NSString* port;

@property (nonatomic, strong) NSArray* codecs;

@property (nonatomic, strong) NSString* proxy;


@end


@interface XACodec : NSObject

@property (nonatomic, assign) int index;
@property (nonatomic, strong) NSString* codecId;
@property (nonatomic, assign) bool enabled;
@property (nonatomic, assign) int priority;

@end

@interface XAContact : NSObject

@property (nonatomic, strong) NSString* contactId;
@property (nonatomic, strong) NSString* contactName;

@end

@interface XAAXHelper : NSObject

+ (XAAXHelper*)shareInstance;

- (void) start;
- (int) countActiveCalls;
- (NSString*) getCurrentIncallRemoteUsername;
- (XAAccount*) getDefaultAccount;
- (bool) refreshAccounts;
- (void) saveAccountWithUsername:(NSString*)username password:(NSString*)password domain:(NSString*)domain transport:(NSString*)transport port:(NSString*)port;
- (void) checkAccountRegistrationWithUsername:(NSString*)username domain:(NSString*)domain;
- (void) sendDtmf:(NSString*)username digit:(NSString*)digit;
- (void) playDtmf:(NSString*)digit;
- (void) playDtmf:(NSString*)digit remote:(NSString*)remote;
- (void) stopPlayDtmf;
- (int) makeSingleCallWithUsername:(NSString*)username contactId:(NSString*)contactId contactName:(NSString*)contactName;
- (bool) hangupCallWithCallId:(int)callid;
- (bool) hangupCallWithRemote:(NSString*)username;
- (void) acceptCallWithCallId:(int)callid;
- (void) acceptCallWithRemote:(NSString*)username;
- (void) pauseCallWithCallId:(int)callid;
- (void) pauseCallWithRemote:(NSString*)username;
- (void) resumeCallWithCallId:(int)callid;
- (void) resumeCallWithRemote:(NSString*)username;

- (void) muteWithCallId:(int)callid;
- (void) muteWithRemote:(NSString*)username;
- (void) unmuteWithCallId:(int)callid;
- (void) unmuteWithRemote:(NSString*)username;

- (void) getLastCalledNumber;
- (int) getAllCallHistory;
- (void) deleteCallHistory:(int) callHistoryId;
- (void) deleteAllCallHistory;

- (void)setSpeakerEnabled:(BOOL)enable;

- (int) getCodecsCount;
- (XACodec*) getCodecs:(int)codecId;
- (void) changeCodecProWithCodecId:(int)codecId enable:(bool)enable;

- (void) saveContactWithContactId:(NSString*)contactId contactName:(NSString*)contactName phoneNumber1:(NSString*)phoneNumber1 phoneNumber2:(NSString*)phoneNumber2 phoneNumber3:(NSString*)phoneNumber3;
- (XAContact*) selectContactMatched:(NSString*)sipNumber;
- (void) deleteAllContacts;

@end
