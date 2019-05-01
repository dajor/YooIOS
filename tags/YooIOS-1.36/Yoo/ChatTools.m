//
//  ChatTools.m
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "ChatTools.h"
#import "Reachability.h"
#import "XMPPJID.h"
#import "DDTTYLogger.h"
#import "XMPPMessage.h"
#import "XMPPPresence.h"
#import "XMPPIQ.h"
#import "YooMessage.h"
#import "YooUser.h"
#import "ChatDAO.h"
#import "UserDAO.h"
#import "ContactManager.h"
#import "Contact.h"
#import "LabelledValue.h"
#import "LocationTools.h"
#import "AppDelegate.h"
#include <CommonCrypto/CommonDigest.h>
#import "ContactDAO.h"
#import "YooGroup.h"
#import "YooBroadcast.h"
#import "GroupDAO.h"
#import "EqualsCriteria.h"
#import "XMLTools.h"
#import "UICustomAlertViewVC.h"
#import "UITools.h"

@implementation ChatTools

static ChatTools *instance = nil;

+ (ChatTools *)sharedInstance {
    if (instance == nil) {
        instance = [[ChatTools alloc] init];
    }
    return instance;
}

+ (SystemSoundID) createSoundID: (NSString*)name
{
    NSString *path = [NSString stringWithFormat: @"%@/%@", [[NSBundle mainBundle] resourcePath], name];
    NSURL* filePath = [NSURL fileURLWithPath: path isDirectory: NO];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    return soundID;
}

+(void)stopSound{
    if ([ChatTools sharedInstance].audioPlayer) {
        [[ChatTools sharedInstance].audioPlayer stop];
        [ChatTools sharedInstance].audioPlayer = nil;
    }
}

- (void)playSound:(BOOL )repeat{
    NSString *path = [NSString stringWithFormat: @"%@/%@", [[NSBundle mainBundle] resourcePath], @"ringtone.mp3"];
    NSURL *urlForSoundFile = [NSURL fileURLWithPath: path isDirectory: NO];;// ... whatever but it must be a valid URL for your sound file
    NSError *error;
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:urlForSoundFile error:&error];
    if (self.audioPlayer) {
        if (repeat) [self.audioPlayer setNumberOfLoops:repeat?-1:0];// -1 for the forever looping
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
    } else {
        NSLog(@"%@", error);
    }
}

- (id)init {
    self = [super init];
    self.listeners = [NSMutableArray array];
    self.present = [NSMutableArray array];
    self.invisible = [NSMutableArray array];
    self.tested = [NSMutableArray array];
    self.pending = [NSMutableArray array];
    self.roomUsers = [NSMutableDictionary dictionary];
    self.roomAliases = [NSMutableDictionary dictionary];
    self.countryCode = nil;
    self.countryReady = NO;
    self.contactsReady = NO;
    self.myConfNumber = nil;
    self.confMembers = [NSMutableDictionary dictionary];
    self.callHistory = [NSMutableDictionary dictionary];
    [[ContactManager sharedInstance] addListener:self];
    return self;
}

- (void)addListener:(NSObject <ChatListener> *)listener {
    [self.listeners addObject:listener];
    if ([listener respondsToSelector:@selector(removeListener:)]) {
        
    }
}

- (void)removeListener:(NSObject<ChatListener> *)listener {
    [self.listeners removeObject:listener];
}

- (void)broadcast:(SEL)selector param:(id)param {
    NSArray *tmp = [NSArray arrayWithArray:self.listeners];
    for (NSObject <ChatListener> *listener in tmp) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        [listener performSelector:selector withObject:param];
        [listener performSelectorOnMainThread:selector withObject:param waitUntilDone:NO];
#pragma clang diagnostic pop
    }
}

- (void)sendPending {
    while (self.pending.count > 0) {
        DDXMLElement *first = [self.pending objectAtIndex:0];
        [self.pending removeObjectAtIndex:0];
        [self.xmppStream sendElement:first];
    }
    
    //unsent messages
    if (![self.login isEqualToString:REGISTRATION_USER]) {
        NSObject<YooRecipient> *me = [UserDAO findByJid:[self getMyJid]];
        NSArray *unsentMessage = [ChatDAO unsentList:me];
        for (YooMessage *msg in unsentMessage) {
            [self sendMessage:msg];
            [self broadcast:@selector(didReceiveMessage:) param:msg];
        }
    }
}

- (void)mustSend:(DDXMLElement *)element {
    if (self.xmppStream != nil && [self.xmppStream isConnected] && [self.xmppStream isAuthenticated]) {
        [self.xmppStream sendElement:element];
        
        if ([element.name isEqualToString:@"message"]) {
            NSString *msgId = [[element attributeForName:@"id"] stringValue];
            if (msgId.length > 0) {
                [ChatDAO markAsSent:[self getMyJid] ident:msgId];
            }
        }
    } else {
        [self.pending addObject:element];
    }
}

- (void)disconnect {
    if (self.xmppStream != nil && ![self.xmppStream isDisconnected] && [self.xmppStream isConnected]) {
        [self.xmppStream disconnect];
        self.xmppStream = nil;
    }
}

- (void)login:(NSString *)pLogin password:(NSString *)pPassword {
    self.login = pLogin;
    self.password = pPassword;
    self.xmppStream = [[XMPPStream alloc] init];
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.xmppStream.myJID = [XMPPJID jidWithUser:self.login domain:YOO_DOMAIN resource:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
    self.xmppStream.hostName = YOO_DOMAIN;
    NSError *error = nil;
    if (![self.xmppStream connectWithTimeout:10000 error:&error]) {
        NSLog(@"Connect error: %@", error.description);
        [self broadcast:@selector(didLogin:) param:error.description];
    } else {
        // nothing to do yet, wait for authentication
    }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    [self broadcast:@selector(didLogin:) param:@"DISCONNECT"];
}

- (void)logout {
    [self.xmppStream disconnectAfterSending];
    self.xmppStream = nil;
    self.login = nil;
    self.password = nil;
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSError *error = nil;
    if (![self.xmppStream authenticateWithPassword:self.password error:&error]) {
        DDLogWarn(@"Authentication failed: %@", error.description);
        [self broadcast:@selector(didLogin:) param:error.description];
    } else {
        // nothing to do yet
    }
}

- (void)sendPresence {
    // we sent presence directly, not go through pending messages
    XMPPPresence *presence = [[XMPPPresence alloc] init];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"hideStatus"] boolValue]) {
        NSXMLElement *status = [NSXMLElement elementWithName:@"status"];
        [status setStringValue:@"invisible"];
        [presence addChild:status];
    }
    [self.xmppStream sendElement:presence];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    YooUser *me = [UserDAO find:self.login domain:YOO_DOMAIN];
    // if we don't exists, create our user
    if (me == nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *nickname = [userDefaults objectForKey:@"nickname"];
        NSInteger callingCode = [userDefaults integerForKey:@"callingCode"];
        YooUser *yooUser = [[YooUser alloc] initWithName:self.login domain:YOO_DOMAIN];
        yooUser.alias = nickname;
        yooUser.callingCode = callingCode;
        [UserDAO upsert:yooUser];
    }
    
    // After establishing a session, a client SHOULD send initial presence to the server in order to signal its availability for communications.
    [self sendPresence];
    
    // send the pending XMPP messages
    [self sendPending];
    
    [self broadcast:@selector(didLogin:) param:nil];
    
    if (![self.login isEqualToString:REGISTRATION_USER]) {
        // get friend list
        NSXMLElement *queryElement = [NSXMLElement elementWithName: @"query" URI: @"jabber:iq:roster"];
        NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
        [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"get"]];
        [iqStanza addChild: queryElement];
        
        [self mustSend:iqStanza];
        
        // check presence of phone contacts : we need the country code
        [[LocationTools sharedInstance] getCountryCode:self];
        
        // set device token
        [self setDevice:((AppDelegate *)[UIApplication sharedApplication].delegate).deviceToken];
        
        // send presence to all groups
        for (YooGroup *group in [GroupDAO list]) {
            // send presence to the group
            XMPPPresence *presence = [[XMPPPresence alloc] initWithType:nil to:[XMPPJID jidWithUser:group.name domain:@"conference.yoo-app.com" resource:self.login]];
            [self mustSend:presence];
        }

        // if our profile has no picture, ask for the VCard to get one
        if (me.picture == nil) {
            [self requestVCard:[self getMyJid]];
        }
    }
}

- (void)setCountry:(NSString *)pCountry {
    if (self.countryCode == nil || ![self.countryCode isEqualToString:pCountry]) {
        self.countryCode = pCountry;
    }
    if (self.countryReady == NO) {
        self.countryReady = YES;
        [self getUsersFromContacts];
    }
}

- (void)contactsLoaded {
    self.contactsReady = YES;
    [self getUsersFromContacts];
}

- (void)registerUser:(NSString *)phone code:(NSString *)code {
    // <query xmlns=\"yoo:iq:register\"><name>John Smith</name><phone>0085592652053</phone></query>
    NSXMLElement *queryElt = [NSXMLElement elementWithName:@"query" URI: @"yoo:iq:register"];
    NSXMLElement *phoneElt = [NSXMLElement elementWithName:@"phone"];
    [phoneElt setStringValue:phone];
    [queryElt addChild:phoneElt];
    NSXMLElement *codeElt = [NSXMLElement elementWithName:@"code"];
    [codeElt setStringValue:code];
    [queryElt addChild:codeElt];
    
    NSXMLElement *iqStanza = [NSXMLElement elementWithName:@"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addChild: queryElt];
    
    [self mustSend: iqStanza];
}

- (void)registerUser:(NSString *)name phone:(NSString *)phone countryCode:(NSInteger)countryCode {
    // <query xmlns=\"yoo:iq:register\"><name>John Smith</name><phone>0085592652053</phone></query>
    NSXMLElement *queryElt = [NSXMLElement elementWithName:@"query" URI: @"yoo:iq:register"];
    NSXMLElement *nameElt = [NSXMLElement elementWithName:@"name"];
    [nameElt setStringValue:name];
    [queryElt addChild:nameElt];
    NSXMLElement *phoneElt = [NSXMLElement elementWithName:@"phone"];
    [phoneElt setStringValue:phone];
    [queryElt addChild:phoneElt];
    NSXMLElement *countryElt = [NSXMLElement elementWithName:@"country"];
    [countryElt setStringValue:[NSString stringWithFormat:@"%ld", (long)countryCode]];
    [queryElt addChild:countryElt];

    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addChild: queryElt];
    [self mustSend:iqStanza];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)errorXML {
    DDLogWarn(@"Authentication failed: %@", errorXML.description);
    if (errorXML.childCount == 1 && [[errorXML childAtIndex:0].name isEqualToString:@"not-authorized"]) {
        [self broadcast:@selector(didLogin:) param:@"Wrong Login or Password"];
    } else {
        [self broadcast:@selector(didLogin:) param:errorXML.description];
    }
}

- (NSArray *)messagesForRecipient:(NSObject<YooRecipient> *)recipient withPicture:(BOOL)pict limit:(int)limit {
    return [ChatDAO list:recipient withPictures:pict limit:limit];
}

- (void)addInHistory:(YooMessage *)yooMsg {
    [ChatDAO insert:yooMsg];
}

- (NSArray *)getContactFields {
    return @[@"firstName", @"lastName", @"company", @"jobTitle"];
}

-(void)processMessage:(XMPPMessage *)message{
    Contact *shared = nil;
    YooMessage *yooMsg = [[YooMessage alloc] init];
    if ([message.from.domain isEqualToString:CONFERENCE_DOMAIN]) {
        YooGroup *group = [[YooGroup alloc] initWithName:message.from.user alias:message.from.user];
        group.member = message.from.resource;
        yooMsg.from = group;
    } else {
        yooMsg.from = [[YooUser alloc] initWithName:message.from.user domain:message.from.domain];
    }
    yooMsg.to = [[YooUser alloc] initWithName:self.login domain:YOO_DOMAIN];
    yooMsg.message = [XMLTools unescapeEmoji:message.body];
    yooMsg.thread = message.thread;
    yooMsg.ident = message.elementID;
    
    // handle message properties
    NSArray *propertiesElts = [message elementsForName:@"properties"];
    if (propertiesElts.count > 0) {
        NSArray *propertyElts = [(DDXMLElement *)[propertiesElts objectAtIndex:0] elementsForName:@"property"];
        for (DDXMLElement *propertyElt in propertyElts) {
            NSArray *nameElts = [propertyElt elementsForName:@"name"];
            NSArray *valueElts = [propertyElt elementsForName:@"value"];
            if (nameElts.count == 1 && valueElts.count == 1) {
                NSString *propName = [[(DDXMLElement *)[nameElts objectAtIndex:0] childAtIndex:0] stringValue];
                NSString *propValue = [[(DDXMLElement *)[valueElts objectAtIndex:0] childAtIndex:0] stringValue];
                // attached sound
                if ([propName isEqualToString:@"sound"]) {
                    yooMsg.sound = [[NSData alloc] initWithBase64EncodedString:propValue options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    //[[NSData alloc] initWithBase64Encoding:propValue];
                }
                // attached picture
                if ([propName hasPrefix:@"picture"]) {
                    //NSData *imageData = [[NSData alloc] initWithBase64Encoding:propValue];
                    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:propValue options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    if (yooMsg.pictures == nil) yooMsg.pictures = [NSMutableArray array];
                    [(NSMutableArray *)yooMsg.pictures addObject:imageData];
                }
                // location
                if ([propName isEqualToString:@"location"]) {
                    NSArray *parts = [propValue componentsSeparatedByString:@"/"];
                    yooMsg.location = CLLocationCoordinate2DMake([[parts objectAtIndex:0] doubleValue], [[parts objectAtIndex:1] doubleValue]);
                }
                // call conference
                if ([propName isEqualToString:@"conferenceNumber"]){
                    yooMsg.conferenceNumber = propValue;
                }
                if ([propName isEqualToString:@"callReqId"]) {
                    yooMsg.callReqId = propValue;
                }
                // group
                if ([propName hasPrefix:@"group-"]) {
                    if (yooMsg.group == nil) {
                        yooMsg.group = [[YooGroup alloc] init];
                    }
                    if ([propName isEqualToString:@"group-name"]) {
                        yooMsg.group.name = propValue;
                    }
                    if ([propName isEqualToString:@"group-alias"]) {
                        yooMsg.group.alias = propValue;
                    }
                }
                // contact
                if ([propName hasPrefix:@"contact-"]) {
                    if (shared == nil) shared = [[Contact alloc] init];
                    if ([propName hasPrefix:@"contact-phone"] || [propName hasPrefix:@"contact-messaging"] || [propName hasPrefix:@"contact-email"]) {
                        NSString *code = [propName substringFromIndex:[propName rangeOfString:@"-" options:NSBackwardsSearch].location + 1];
                        NSInteger num = [code integerValue];
                        NSMutableArray *list = nil;
                        if ([propName hasPrefix:@"contact-phone"]) {
                            list = shared.phones;
                        } else if ([propName hasPrefix:@"contact-email"]) {
                            list = shared.emails;
                        } else {
                            list = shared.messaging;
                        }
                        // add phones, emails or messaging if needed
                        while (list.count < num+1) {
                            [list addObject:[[LabelledValue alloc] init]];
                        }
                        LabelledValue *labVal = [list objectAtIndex:num];
                        if ([propName rangeOfString:@"-label-"].location != NSNotFound) {
                            labVal.label = propValue;
                        }
                        if ([propName rangeOfString:@"-value-"].location != NSNotFound) {
                            labVal.value = propValue;
                        }
                    } else {
                        for (NSString *field in [self getContactFields]) {
                            if ([propName hasSuffix:field]) {
                                [shared setValue:propValue forKey:field];
                            }
                        }
                    }
                }
                // message type
                if ([propName isEqualToString:@"type"]) {
                    yooMsg.type = [propValue integerValue];
                }
                // message type
                if ([propName isEqualToString:@"callStatus"]) {
                    yooMsg.callStatus = [propValue integerValue];
                }
                if ([propName isEqualToString:@"sendDate"]) {
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    [df setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
                    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
                    yooMsg.date = [df dateFromString:propValue];
                }
            }
        }
    }
    
    // Handle call status from recipient
    if (yooMsg.type == ymtCallStatus) {
        
        //In case user offline and back to online then receive old call cancelled status receive to fast
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSLog(@"Do some work");
            YooMessage *reqMsg = [ChatDAO findById:yooMsg.callReqId];
            NSLog(@"callID = %@",yooMsg.callReqId);
            [ChatTools stopSound];
            if (!reqMsg) {
                NSLog(@"cannot find callrequest");
                [self.callHistory setObject:yooMsg forKey:[NSString stringWithFormat:@"%@",yooMsg.callReqId]];
                return;
            }
            if (reqMsg.callStatus != csCancelled) {
                NSString *userJid = [self getMyJid];
                [ChatDAO updateCall:userJid ident:yooMsg.callReqId status:yooMsg.callStatus];
                // dismiss the call popup if visible
                if (self.callAlert.visible) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOutCall:) object:[self lastCall]];
                    [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
                }
                if (yooMsg.callStatus == csAccepted) {
                    // show the window to call the conference number
                    [self connectPhoneCall];
                }
                [self broadcast:@selector(handlePhoneCall:) param:yooMsg];
               // don't add this message in history
            }
        });
        return;
    }
    
    if (yooMsg.type == ymtCallRequest) {
        BOOL showPopup = YES;
        if ([yooMsg.from isKindOfClass:[YooGroup class]]) {
            YooGroup *group = (YooGroup *)yooMsg.from;
            if ([group.member isEqualToString:self.login]) {
                showPopup = NO;
            }
        }
        NSInteger seconds = -[yooMsg.date timeIntervalSinceNow];
        if (seconds >= CALL_MAX_DELAY) {
            showPopup = NO;
        }
        
        NSLog(@"callID = %@",yooMsg.ident);
        
        YooMessage *cancelled = [self.callHistory objectForKey:[NSString stringWithFormat:@"%@",yooMsg.ident]];
        if (cancelled) {
            showPopup = NO;
            yooMsg.callStatus = cancelled.callStatus;
        }
        
        if (showPopup) {
            [self showCallPopup:yooMsg];
            [[ChatTools sharedInstance] playSound:YES];
        }
    }
    
    // create other user
    if (shared != nil) {
        Contact *existing = [[ContactManager sharedInstance] findByName:shared.fullName];
        if (existing == nil) {
            NSInteger contactId = [[ContactManager sharedInstance] create:shared];
            if (contactId != -1) {
                shared.contactId = contactId;
                [ContactDAO upsert:shared];
                NSString *jid = nil;
                for (LabelledValue *messaging in shared.messaging) {
                    if ([messaging.value hasSuffix:YOO_DOMAIN]) {
                        jid = messaging.value;
                        break;
                    }
                }
                if (jid != nil) {
                    YooUser *newUser = [[YooUser alloc] initWithJID:jid];
                    newUser.alias = shared.fullName;
                    newUser.contactId = contactId;
                    __weak typeof(YooUser) *weaknewUser = newUser;
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        typeof(newUser) strongMessage = weaknewUser;
                        [UserDAO upsert:strongMessage];
                    });
                    
                }
                [self broadcast:@selector(addressBookChanged) param:nil];
                yooMsg.shared = [NSNumber numberWithInteger:contactId];
            }
        } else {
            yooMsg.shared = [NSNumber numberWithInteger:existing.contactId];
        }
    }
    // create/update group
    if (yooMsg.type == ymtInvite && yooMsg.group != nil) {
        if (yooMsg.group.alias != nil) {
            [self.roomAliases setObject:yooMsg.group.alias forKey:yooMsg.group.name];
        }
        [self checkGroup:yooMsg.group.name];
    }
    // remove from group
    if (yooMsg.type == ymtRevoke && yooMsg.group != nil) {
        if (![yooMsg.from isMe]) {
            [GroupDAO remove:[yooMsg.group toJID]];
            // update UI
            [self broadcast:@selector(friendListChanged:) param:@[]];
        }
    }
    
    // handle "received" tag
    NSArray *receivedElts = [message elementsForName:@"received"];
    if (receivedElts.count > 0) {
        DDXMLElement *receivedElt = [receivedElts objectAtIndex:0];
        NSString *idMsg = [[receivedElt attributeForName:@"id"] stringValue];
        yooMsg.ident = idMsg;
        yooMsg.type = ymtAck;
    }
    // handle request/receipt tag
    NSArray *reqElts = [message elementsForName:@"request"];
    if (reqElts.count > 0) {
        DDXMLElement *reqElt = [reqElts objectAtIndex:0];
        NSString *nsReq = [[reqElt namespaceForPrefix:@""] stringValue];
        if ([nsReq isEqualToString:@"urn:xmpp:receipts"]) {
            // send receipt
            XMPPMessage *receipt = [[XMPPMessage alloc] initWithType:nil to:[XMPPJID jidWithString:yooMsg.from.toJID]];
            DDXMLNode *attrId = [DDXMLNode attributeWithName:@"id" stringValue:yooMsg.ident];
            DDXMLNode *attrNs = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"urn:xmpp:receipts"];
            DDXMLNode *received = [DDXMLNode elementWithName:@"received" children:nil attributes:@[attrId, attrNs]];
            [receipt addChild:received];
            [self mustSend:receipt];
        }
    }
    
    //handle ymtMessageRead
    if (yooMsg.type ==  ymtMessageRead && ![yooMsg.from isMe]) {
        [self markasReadByOther:yooMsg];
    }
    if (yooMsg.type ==  ymtMessageRead && [yooMsg.from isMe])return;
    
    if (yooMsg.type != ymtAck && yooMsg.type != ymtMessageRead && yooMsg.type != ymtInvite && yooMsg.type != ymtRevoke) {
        if ([message.type isEqualToString:@"groupchat"]) {
            if ([message.from.resource isEqualToString:self.login]) {
                // ignore own messages on group chat
                return;
            }
            if (message.from.resource.length == 0) {
                // ignore message from the room itself
                return;
            }
        }
        [self addInHistory:yooMsg];
        [self broadcast:@selector(didReceiveMessage:) param:yooMsg];
    } else if (yooMsg.type == ymtAck) {
        YooMessage *originalMsg = [ChatDAO acknowledge:yooMsg.ident];
        [self broadcast:@selector(didReceiveMessage:) param:originalMsg];
    }else if(yooMsg.type == ymtMessageRead){
        YooMessage *originalMsg = [ChatDAO findById:yooMsg.ident];
        [self broadcast:@selector(didReceiveMessage:) param:originalMsg];
    }
    
    
    // Add in roster the sender
    if ([yooMsg.from isKindOfClass:[YooUser class]]) {
        NSString *login = [[NSUserDefaults standardUserDefaults] stringForKey:@"login"];
        YooUser *me = [UserDAO find:login domain:YOO_DOMAIN];
        YooUser *existing = [UserDAO find:((YooUser *)yooMsg.from).name domain:((YooUser *)yooMsg.from).domain];
        if (existing == nil && ![[me contactName] isEqualToString:[existing contactName]]
            && ![message.from.user isEqualToString:REGISTRATION_USER]) {
            XMPPIQ *add = [[XMPPIQ alloc] initWithType:@"set"];
            DDXMLNode *attrJid = [DDXMLNode attributeWithName:@"jid" stringValue:[message.from full]];
            DDXMLNode *item = [DDXMLNode elementWithName:@"item" children:nil attributes:@[attrJid]];
            DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"];
            DDXMLNode *query = [DDXMLNode elementWithName:@"query" children:@[item] attributes:@[attrNS]];
            [add addChild:query];
            [self mustSend:add];
        }
    }
}

-(void)connectPhoneCall{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", self.myConfNumber]]];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    DDLogInfo(@"Received message %@", message.body);
    if ([message.type isEqualToString:@"error"]) {
        return;
    }
    //[self processMessage:message];
   [NSThread detachNewThreadSelector:@selector(processMessage:) toTarget:self withObject:message];
}

-(void)markasReadByOther:(YooMessage *)message{
    [ChatDAO markAsReadByOther:[self getMyJid] ident:message.ident];
}

-(BOOL)canalert:(YooMessage *)message{
    BOOL showPopup = YES;
    if ([message.from isKindOfClass:[YooGroup class]]) {
        YooGroup *group = (YooGroup *)message.from;
        if ([group.member isEqualToString:self.login]) {
            showPopup = NO;
        }
    }
    NSInteger seconds = -[message.date timeIntervalSinceNow];
    if (message.date == nil || seconds>=CALL_MAX_DELAY) {
        showPopup = NO;
    }
    if (message.type == ymtMessageRead || message.type == ymtAck) showPopup = NO;
    
    return showPopup;
}

- (void)showCallPopup:(YooMessage *)call {
    NSString *message = call.toDisplay;
    
    if (self.callAlert && self.callAlert.visible) {
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
    }
    
    self.callAlert = [[UICustomAlertViewVC alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:NSLocalizedString(@"CALL_DECLINE", nil) otherButtonTitles:NSLocalizedString(@"CALL_ACCEPT", nil), nil];
    self.callAlert.call = call;
    [self.callAlert show];
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOutCall:) object:[self lastCall]];
        self.lastCall = call;
        [self performSelector:@selector(timeOutCall:) withObject:call afterDelay:CALL_MAX_DELAY];
    });
}

-(void)timeOutCall:(YooMessage *)message{
    if (self.callAlert.visible) {
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        [ChatTools stopSound];
        [self answerCall:message accept:NO];
    }
}
- (void)removeFriend:(NSString *)jid {
    XMPPIQ *remove = [[XMPPIQ alloc] initWithType:@"set"];
    DDXMLNode *attrJid = [DDXMLNode attributeWithName:@"jid" stringValue:jid];
    DDXMLNode *attrSub = [DDXMLNode attributeWithName:@"subscription" stringValue:@"remove"];
    DDXMLNode *item = [DDXMLNode elementWithName:@"item" children:nil attributes:@[attrJid, attrSub]];
    DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"];
    DDXMLNode *query = [DDXMLNode elementWithName:@"query" children:@[item] attributes:@[attrNS]];
    [remove addChild:query];
    [self mustSend:remove];
    
}

- (YooGroup *)checkGroup:(NSString *)code {
    YooGroup *yooGroup = [GroupDAO find:code];
    if (yooGroup == nil) {
        DDLogInfo(@"Adding new group : %@", code);
        NSString *alias = [self.roomAliases objectForKey:code];
        if (alias == nil) {
            alias = [code substringFromIndex:[code rangeOfString:@"-"].location + 1];
        }
        yooGroup = [[YooGroup alloc] initWithName:code alias:alias];
        yooGroup.date = [NSDate date];
        [GroupDAO upsert:yooGroup];
        
        // send presence to the group
        XMPPPresence *presence = [[XMPPPresence alloc] initWithType:nil to:[XMPPJID jidWithUser:code domain:@"conference.yoo-app.com" resource:self.login]];
        [self mustSend:presence];
        
        // query member list
        for (NSString *affiliation in @[@"admin", @"owner"]) {
            XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get" to:[XMPPJID jidWithString:[yooGroup toJID]] elementID:@"groupmember"];
            DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/muc#admin"];
            DDXMLNode *affAttr = [DDXMLNode attributeWithName:@"affiliation" stringValue:affiliation];
            DDXMLNode *itemElt = [DDXMLNode elementWithName:@"item" children:nil attributes:@[affAttr]];
            DDXMLNode *queryElt = [DDXMLNode elementWithName:@"query" children:@[itemElt] attributes:@[attrNS]];;
            [iq addChild:queryElt];
            [self mustSend:iq];
        }

        // update UI
        [self broadcast:@selector(friendListChanged:) param:@[]];
    }

    return yooGroup;
}


- (YooUser *)checkFriend:(NSString *)name domain:(NSString *)domain {
    YooUser *yooUser = [UserDAO find:name domain:domain];
    
    if (yooUser == nil) {
        DDLogInfo(@"Adding new friend : %@", name);
        yooUser = [[YooUser alloc] initWithName:name domain:domain];
        [UserDAO upsert:yooUser];
        [self broadcast:@selector(friendListChanged:) param:@[yooUser]];
    }
    
    if (![self isPresent:yooUser]) {
        // register for presence for the new friend
        XMPPPresence *subscribe = [[XMPPPresence alloc] initWithType:@"subscribe" to:[XMPPJID jidWithUser:yooUser.name domain:yooUser.domain resource:nil]];
        [self mustSend:subscribe];
    }
    
    if (yooUser.picture == nil || yooUser.alias == nil) {
        [self requestVCard:yooUser.toJID];
    }
    
    // check if the contact exists in address book
    [self checkAddressBook:yooUser];
    
    return yooUser;
}

- (void)requestVCard:(NSString *)jid {
    // request user's avatar and alias
    XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get" to:[XMPPJID jidWithString:jid]];
    DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"vcard-temp"];
    DDXMLNode *vcard = [DDXMLNode elementWithName:@"vCard" children:nil attributes:@[attrNS]];
    [iq addChild:vcard];
    [self mustSend:iq];

}

/*
 * Request Call: send iq request to server to get conference number
 * @param: Members in conference room.
 * @param: Listener listen when success and do other functionality
 */
- (void)requestCall:(NSObject<YooRecipient> *)recipient {
    
    NSMutableArray *members = [NSMutableArray array];
    if ([recipient isKindOfClass:[YooGroup class]]) {
        YooGroup *group = (YooGroup *)recipient;
        for (NSString *userJid in [GroupDAO listMembers:group.toJID]) {
            YooUser *user = [UserDAO findByJid:userJid];
            if (user != nil) {
                [members addObject:user];
            }
        }
    } else {
        YooUser *user = (YooUser *)recipient;
        [members addObject:user];
    }
    
    if (members.count > 0) {
        NSString *confId = [ChatTools genRandStringLength:16];
        [self.confMembers setObject:recipient forKey:confId];
        XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get" elementID:confId];
        DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"yoo:iq:call"];
        NSXMLElement *queryElt = [NSXMLElement elementWithName:@"query" children:nil attributes:@[attrNS]];
        for (YooUser *user in members) {
            NSXMLElement *userElt = [NSXMLElement elementWithName:@"user" children:nil attributes:nil];
            [queryElt addChild:userElt];
            [userElt setStringValue:user.toJID];
        }
        [iq addChild:queryElt];
        [self mustSend:iq];
    }
}

- (void)checkAddressBook:(YooUser *)yooUser {
    if (![yooUser isMe] && [yooUser.domain isEqualToString:YOO_DOMAIN] && yooUser.name.length > 0 && yooUser.alias.length > 0) {
        Contact *contact = [[ContactManager sharedInstance] find:yooUser.contactId];
        if (contact == nil) {
            contact = [[ContactManager sharedInstance] findByName:yooUser.alias];
            if (contact == nil) {
                // we have to create the new contact
                Contact *contact = [[Contact alloc] init];
                NSArray *parts = [yooUser.alias componentsSeparatedByString:@" "];
                if (parts.count > 1) {
                    contact.firstName = [[[parts subarrayWithRange:NSMakeRange(0, parts.count - 1)] componentsJoinedByString:@" "] capitalizedString];
                    contact.lastName = [[parts objectAtIndex:parts.count - 1] capitalizedString];
                } else {
                    contact.firstName = [yooUser.alias capitalizedString];
                }
                NSInteger contactId = [[ContactManager sharedInstance] createFromYoo:contact jid:yooUser.toJID];
                if (contactId != -1) {
                    contact.contactId = contactId;
                    [ContactDAO upsert:contact];
                    yooUser.contactId = contactId;
                    [UserDAO upsert:yooUser];
                    [self broadcast:@selector(addressBookChanged) param:nil];
                }
            } else {
                yooUser.contactId = contact.contactId;
                [UserDAO upsert:yooUser];
                [self broadcast:@selector(friendListChanged:) param:@[yooUser]];
            }
        }
    }
}


- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
    NSArray *elements = [iq elementsForName:@"query"];
    if (elements.count > 0) {
        // got roster response
        NSXMLElement *queryElement = [elements objectAtIndex:0];
        DDXMLNode *ns = [queryElement namespaceForPrefix:@""];
        if ([ns.stringValue isEqualToString:@"jabber:iq:roster"]) {
            NSArray *itemElements = [queryElement elementsForName: @"item"];
            for (int i = 0; i<[itemElements count]; i++) {
                NSString *jid = [[[itemElements objectAtIndex:i] attributeForName:@"jid"] stringValue];
                NSString *subs = [[[itemElements objectAtIndex:i] attributeForName:@"subscription"] stringValue];
                NSString *iqType = [[iq attributeForName:@"type"] stringValue];
                if (![subs isEqualToString:@"remove"]) {
                    XMPPJID *xmppJid = [XMPPJID jidWithString:jid];
                    if ([xmppJid.domain isEqualToString:CONFERENCE_DOMAIN]) {
                        // received from group
                        //[self checkGroup:xmppJid.user];
                    } else if ([xmppJid.domain isEqualToString:YOO_DOMAIN] && ![xmppJid.user isEqualToString:REGISTRATION_USER]) {
                        // if iq type = set, we've just asked for registration on a contact and should re-add it even if
                        //    it has been deleted in contacts
                        // if iq type = result, we've received the full roster list
                        if ([[ContactManager sharedInstance].removed indexOfObject:jid] == NSNotFound || [iqType isEqualToString:@"set"]) {
                            [self checkFriend:xmppJid.user domain:xmppJid.domain];
                        }
                    }
                }
            }
        } else if ([ns.stringValue isEqualToString:@"yoo:iq:register"]) {
            if (queryElement.childCount > 0) {
                NSXMLElement *childElt = (NSXMLElement *)[queryElement childAtIndex:0];
                NSDictionary *regInfo = [NSDictionary dictionaryWithObjectsAndKeys:childElt.stringValue, childElt.name, nil];
                [self broadcast:@selector(didReceiveRegistrationInfo:) param:regInfo];
            } else {
                [self broadcast:@selector(didReceiveRegistrationInfo:) param:nil];
            }
        } else if ([ns.stringValue isEqualToString:@"yoo:iq:finduser"]) {
            NSArray *userElements = [queryElement elementsForName: @"user"];
            
            NSMutableArray *changed = [NSMutableArray array];
            for (int i = 0; i<[userElements count]; i++) {
                DDXMLElement *userElt = [userElements objectAtIndex:i];
                DDXMLElement *idElt = [[userElt elementsForName:@"id"] objectAtIndex:0];
                NSInteger contactId = [idElt.stringValue integerValue];
                DDXMLElement *nameElt = [[userElt elementsForName:@"name"] objectAtIndex:0];
                NSString *name = nameElt.stringValue;
                /*
                DDXMLElement *countryCodeElt = [[userElt elementsForName:@"country"] objectAtIndex:0];
                NSString *countryCode = countryCodeElt.stringValue;
                */
                DDXMLElement *callingCodeElt = [[userElt elementsForName:@"country"] objectAtIndex:0];
                NSString *callingCode = callingCodeElt.stringValue;

                YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
                if (yooUser == nil) {
                    yooUser = [self checkFriend:name domain:YOO_DOMAIN];
                }
                Contact *contact = [[ContactManager sharedInstance] find:contactId];
                if (contact != nil) {
                    yooUser.contactId = contact.contactId;
                    yooUser.callingCode = [callingCode intValue];
                    [UserDAO upsert:yooUser];
                    [changed addObject:yooUser];
                }
            }
            [self broadcast:@selector(friendListChanged:) param:changed];
        } else if ([ns.stringValue isEqualToString:@"http://jabber.org/protocol/disco#items"]) {
            // received info about groups
            NSArray *itemElements = [queryElement elementsForName:@"item"];
            for (int i = 0; i < itemElements.count; i++) {
                DDXMLElement *itemElt = [itemElements objectAtIndex:i];
                NSLog(@"%@", [itemElt attributeForName:@"jid"]);
            }
        } else if ([ns.stringValue isEqualToString:@"jabber:iq:last"]) {
            YooUser *yooUser = [UserDAO find:iq.from.user domain:iq.from.domain];
            NSInteger seconds = [[[queryElement attributeForName:@"seconds"] stringValue] integerValue];
            yooUser.lastonline = [NSDate dateWithTimeIntervalSinceNow:-seconds];
            [UserDAO upsert:yooUser];
            [self broadcast:@selector(lastOnlineChanged:) param:yooUser];
        } else if ([ns.stringValue isEqualToString:@"http://jabber.org/protocol/disco#info"]) {
            // need to answer discovery request
            DDXMLNode *attr1Cat = [DDXMLNode attributeWithName:@"category" stringValue:@"account"];
			//DDXMLNode *attr1Name = [DDXMLNode attributeWithName:@"name" stringValue:name];
			DDXMLNode *attr1Type = [DDXMLNode attributeWithName:@"type" stringValue:@"registered"];
			DDXMLElement *identity1Elt = [DDXMLNode elementWithName:@"identity" children:nil attributes:@[attr1Cat, attr1Type]];

            DDXMLNode *attr2Cat = [DDXMLNode attributeWithName:@"category" stringValue:@"pubsub"];
			//DDXMLNode *attr2Name = [DDXMLNode attributeWithName:@"name" stringValue:name];
			DDXMLNode *attr2Type = [DDXMLNode attributeWithName:@"type" stringValue:@"pep"];
			DDXMLElement *identity2Elt = [DDXMLNode elementWithName:@"identity" children:nil attributes:@[attr2Cat, attr2Type]];

            
			DDXMLNode *attr1Var = [DDXMLNode attributeWithName:@"var" stringValue:@"http://jabber.org/protocol/disco#info"];
			DDXMLElement *feature1Elt = [DDXMLNode elementWithName:@"feature" children:nil attributes:@[attr1Var]];
            
            DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#info"];
            DDXMLElement *queryElt = [DDXMLNode elementWithName:@"query" children:@[identity1Elt, identity2Elt, feature1Elt] attributes:@[attrNS]];
            
            XMPPIQ *discoInfo = [[XMPPIQ alloc] initWithType:@"result" to:iq.from elementID:iq.elementID child:queryElt];

            [self mustSend:discoInfo];
            
            return YES;
        } else if ([ns.stringValue isEqualToString:@"http://jabber.org/protocol/muc#admin"] && [iq.elementID isEqualToString:@"groupmember"]) {
            // received group information
            YooGroup *group = [[YooGroup alloc] initWithName:iq.from.user alias:nil];
            NSArray *itemElements = [queryElement elementsForName:@"item"];
            for (int i = 0; i < itemElements.count; i++) {
                DDXMLElement *itemElt = [itemElements objectAtIndex:i];
                NSString *userJid = [itemElt attributeForName:@"jid"].stringValue;
                if (userJid.length > 0) {
                    [GroupDAO addMember:userJid toGroup:group.toJID];
                }
            }
        } else if ([ns.stringValue isEqualToString:@"yoo:iq:call"]) {
            /* 
             * Handle request call and do call listener
             */
            NSArray *userElts = [queryElement elementsForName:@"user"];
            NSMutableDictionary *confs = [NSMutableDictionary dictionary];
            for (int i = 0; i < userElts.count; i++) {
                DDXMLElement *userElt = [userElts objectAtIndex:i];
                DDXMLElement *idElt = [[userElt elementsForName:@"id"] objectAtIndex:0];
                NSString *userJid = [idElt stringValue];
                DDXMLElement *confElt = [[userElt elementsForName:@"conf"] objectAtIndex:0];
                NSString *confNumber = [confElt stringValue];
                if (userJid.length > 0 && confNumber.length > 0) {
                    [confs setObject:confNumber forKey:userJid];
                }
            }
            NSString *myJid = [self getMyJid];
            self.myConfNumber = [confs objectForKey:myJid];
            if (self.myConfNumber == nil || confs.count == 0) {
                // Issue #8733
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"ERROR_NO_CONFERENCE_NUMBER", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            } else {
                YooMessage *yooMsg = [[YooMessage alloc] init];
                yooMsg.type = ymtCallRequest;
                yooMsg.to = [self.confMembers objectForKey:iq.elementID];
                yooMsg.ident = iq.elementID;
                NSError *error;
                NSData *confData = [NSJSONSerialization dataWithJSONObject:confs options:0 error:&error];
                NSString *confStr = [[NSString alloc] initWithData:confData encoding:NSUTF8StringEncoding];
                yooMsg.conferenceNumber = confStr;
               
                if ([yooMsg.to isKindOfClass:[YooGroup class]]) {
                    yooMsg.callStatus = csAccepted;
                    [self connectPhoneCall];
                }
                [self sendMessage:yooMsg];
                [self broadcast:@selector(handlePhoneCall:) param:yooMsg];
            }
        }
    }
    elements = [iq elementsForName:@"vCard"];
    if (elements.count > 0) {
        // got user vCard
        NSXMLElement *vcardElt = [elements objectAtIndex:0];
        NSData *picture = nil;
        NSString *fullName = nil;
        // get full name
        NSArray *fnElts = [vcardElt elementsForName:@"FN"];
        if (fnElts.count > 0) {
            NSXMLElement *fnElt = [fnElts objectAtIndex:0];
            fullName = [[fnElt childAtIndex:0] stringValue];
        }
        // get photo
        NSArray *photoElts = [vcardElt elementsForName:@"PHOTO"];
        if (photoElts.count > 0) {
            NSXMLElement *photoElt = [photoElts objectAtIndex:0];
            NSArray *binVals = [photoElt elementsForName:@"BINVAL"];
            if (binVals.count > 0) {
                NSXMLElement *binValElt = [binVals objectAtIndex:0];
                NSString *dataBase64 = [[binValElt childAtIndex:0] stringValue];
                picture = [[NSData alloc] initWithBase64EncodedString:dataBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
                //picture = [[NSData alloc] initWithBase64Encoding:dataBase64];
            }
        }
        
        if (fullName != nil || picture != nil) {
            YooUser *yooUser = [UserDAO find:iq.from.user domain:iq.from.domain];
            if (yooUser != nil) {
                if (picture != nil) {
                    yooUser.picture = picture;
                }
                if (fullName != nil && ![yooUser isMe]) { // don't change the alias if it is the current user
                    yooUser.alias = fullName;
                }
                [UserDAO upsert:yooUser];
                [self checkAddressBook:yooUser];
                [self broadcast:@selector(friendListChanged:) param:@[yooUser]];
            }
        }
        return YES;
    }

    if ([iq.from.domain isEqualToString:CONFERENCE_DOMAIN] && [iq.elementID isEqualToString:@"creategroup"] && ![iq.type isEqualToString:@"error"]) {
        [self checkGroup:iq.from.user];
        
        // invite users to new chat room/group
        NSArray *users = [self.roomUsers objectForKey:iq.from.user];
        for (NSString *user in users) {
            [self addUser:user toGroup:iq.from.full];
        }
    }
    
    return NO;
}

- (void)removeUser:(NSString *)userJid fromGroup:(NSString *)groupJid {
    // remove the user from the group
    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[self getMyJid]]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"revoke1"]];
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#admin"];
    NSXMLElement *itemElt = [NSXMLElement elementWithName:@"item"];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"affiliation" stringValue:@"none"]];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"jid" stringValue:userJid]];
    [queryElt addChild:itemElt];
    [iqStanza addChild:queryElt];
    [self mustSend: iqStanza];

    
    NSString *login = [ChatTools sharedInstance].login;
    if ([userJid hasPrefix:[NSString stringWithFormat:@"%@@", login]]) {
        // we leave the group
        XMPPPresence *presence = [[XMPPPresence alloc] initWithType:@"unavailable" to:[XMPPJID jidWithString:groupJid]];
        [self mustSend:presence];
    } else {
        // kick other user
        NSXMLElement *iq2Stanza = [NSXMLElement elementWithName: @"iq"];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[self getMyJid]]];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"kick1"]];
        NSXMLElement *query2Elt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#admin"];
        NSXMLElement *item2Elt = [NSXMLElement elementWithName:@"item"];
        [item2Elt addAttribute:[DDXMLNode attributeWithName:@"role" stringValue:@"none"]];
        NSArray *parts = [userJid componentsSeparatedByString:@"@"];
        [item2Elt addAttribute:[DDXMLNode attributeWithName:@"nick" stringValue:[parts objectAtIndex:0]]];
        [query2Elt addChild:item2Elt];
        [iq2Stanza addChild:query2Elt];
        [self mustSend: iq2Stanza];
    }

    
    
    // revoke the user
    YooUser *yooUser = [[YooUser alloc] initWithJID:userJid];
    NSString *groupName = [[groupJid componentsSeparatedByString:@"@"] objectAtIndex:0];
    YooGroup *yooGroup = [[YooGroup alloc] initWithName:groupName alias:nil];
    YooMessage *yooMsg = [[YooMessage alloc] init];
    yooMsg.type = ymtRevoke;
    yooMsg.to = yooUser;
    NSString *groupAlias = [self.roomAliases objectForKey:groupName];
    yooMsg.group = [[YooGroup alloc] initWithName:groupName alias:groupAlias];
    [self sendMessage:yooMsg];
    
    [GroupDAO removeMember:yooUser.toJID fromGroup:yooGroup.toJID];
}

- (void)addUser:(NSString *)userJid toGroup:(NSString *)groupJid {
    // add the user as group member
    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[self getMyJid]]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"invite1"]];
    
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#admin"];
    NSXMLElement *itemElt = [NSXMLElement elementWithName:@"item"];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"affiliation" stringValue:@"admin"]];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"jid" stringValue:userJid]];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"nick" stringValue:userJid]];
    [queryElt addChild:itemElt];
    [iqStanza addChild:queryElt];
    [self mustSend: iqStanza];
    
    // invite the user to join
    YooUser *yooUser = [[YooUser alloc] initWithJID:userJid];
    YooMessage *yooMsg = [[YooMessage alloc] init];
    yooMsg.type = ymtInvite;
    yooMsg.to = yooUser;
    NSString *groupName = [[groupJid componentsSeparatedByString:@"@"] objectAtIndex:0];
    NSString *groupAlias = [self.roomAliases objectForKey:groupName];
    if (groupAlias == nil) {
        groupAlias = [GroupDAO find:groupName].alias;
    }
    yooMsg.group = [[YooGroup alloc] initWithName:groupName alias:groupAlias];
    [self sendMessage:yooMsg];
    
    [GroupDAO addMember:yooUser.toJID toGroup:yooMsg.group.toJID];

}

- (void)setNickname:(NSString *)nickame picture:(NSData *)picture {
//    <vCard xmlns=\"vcard-temp\"><FN>Ségolène Royal</FN><PHOTO><TYPE>image/png</TYPE><BINVAL>" + picture + "</BINVAL></PHOTO></vCard>
    XMPPIQ *setVCard = [[XMPPIQ alloc] initWithType:@"set"];
    DDXMLNode *fnElt = [DDXMLNode elementWithName:@"FN" stringValue:nickame];
    DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"vcard-temp"];
    DDXMLNode *photoElt = nil;
    if (picture != nil) {
        DDXMLNode *typeElt = [DDXMLNode elementWithName:@"TYPE" stringValue:@"image/png"];
        DDXMLNode *binValElt = [DDXMLNode elementWithName:@"BINVAL" stringValue:[picture base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
        photoElt = [DDXMLNode elementWithName:@"PHOTO" children:@[typeElt, binValElt] attributes:nil];
    }
    DDXMLNode *vCardElt = [DDXMLNode elementWithName:@"vCard" children:photoElt != nil ? @[fnElt, photoElt] : @[fnElt] attributes:@[attrNS]];
    [setVCard addChild:vCardElt];
    [self mustSend:setVCard];
    
    // send presence indicating the picture has changed
    if (picture != nil) {
        // compute sha1 digest on the picture data
        unsigned char digest[CC_SHA1_DIGEST_LENGTH];
        if (CC_SHA1([picture bytes], (unsigned int)[picture length], digest)) {
            NSMutableString *digestString = [[NSMutableString alloc] init];
            for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
                [digestString appendString:[NSString stringWithFormat:@"%02X", digest[i]]];
            }
            XMPPPresence *presence = [[XMPPPresence alloc] init];
            DDXMLNode *attr2NS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"vcard-temp:x:update"];
            DDXMLNode *photo2Elt = [DDXMLNode elementWithName:@"photo" stringValue:digestString];
            DDXMLNode *xElt = [DDXMLNode elementWithName:@"x" children:@[photo2Elt] attributes:@[attr2NS]];
            [presence addChild:xElt];
            [self mustSend:presence];

        }
    }

}

- (UInt64)stats:(BOOL)sent {
    return sent ? self.xmppStream.numberOfBytesSent : self.xmppStream.numberOfBytesReceived;
}

- (void)sendMessage:(YooMessage *)yooMsg {

    yooMsg.from = [[YooUser alloc] initWithName:self.login domain:YOO_DOMAIN];
    yooMsg.read = YES;
    if (yooMsg.ident == nil) {
        yooMsg.ident = [ChatTools genRandStringLength:16];
    }
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    NSString *msgContent = yooMsg.message == nil ? @" " : [XMLTools escapeEmoji:yooMsg.message];
    NSXMLNode *textNode = [NSXMLNode textWithStringValue:msgContent];
    [body addChild:textNode];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:yooMsg.ident]];
    if ([yooMsg.to.toJID hasSuffix:CONFERENCE_DOMAIN]) {
        [message addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"groupchat"]];
    } else {
        [message addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"chat"]];
    }
    [message addAttribute:[NSXMLNode attributeWithName:@"thread" stringValue:yooMsg.thread]];
    XMPPJID *jidUser = [XMPPJID jidWithString:yooMsg.to.toJID];
    [message addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:[jidUser full]]];
    [message addChild:body];
    
//    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"Logo-small" ofType:@"png"];
//    NSData *myData = [NSData dataWithContentsOfFile:path];
//    yooMsg.picture = myData;
    
    NSXMLElement *propsElt = [[NSXMLElement alloc] initWithName:@"properties" URI:@"http://www.jivesoftware.com/xmlns/xmpp/properties"];
    [message addChild:propsElt];
    [self addProperty:@"type" value:[NSString stringWithFormat:@"%ld", (long)yooMsg.type] element:propsElt];
    if (yooMsg.type == ymtSound) {
        [self addProperty:@"sound" value:[yooMsg.sound base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength] element:propsElt];
    }
    if (yooMsg.type == ymtPicture) {
        NSInteger i = 1;
        for (NSData *picData in yooMsg.pictures) {
            [self addProperty:[NSString stringWithFormat:@"picture%ld", (long)i] value:[picData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength] element:propsElt];
            i++;
        }
    }
    if (yooMsg.type == ymtLocation) {
        [self addProperty:@"location" value:[NSString stringWithFormat:@"%f/%f", yooMsg.location.latitude, yooMsg.location.longitude] element:propsElt];
    }
    if (yooMsg.type == ymtInvite || yooMsg.type == ymtRevoke) {
        [self addProperty:@"group-alias" value:yooMsg.group.alias element:propsElt];
        [self addProperty:@"group-name" value:yooMsg.group.name element:propsElt];
    }
    if (yooMsg.type == ymtContact) {
        // send contact attributes
        Contact *contact = [[ContactManager sharedInstance] find:yooMsg.shared.integerValue];
        for (NSString *key in [self getContactFields]) {
            NSString *value = [contact valueForKey:key];
            if (value.length > 0) {
                [self addProperty:[NSString stringWithFormat:@"contact-%@", key] value:value element:propsElt];
            }
        }
        // send contact phones, emails, messaging
        for (NSString *code in @[@"phone", @"email", @"messaging"]) {
            NSArray *list = nil;
            if ([code isEqualToString:@"phone"]) list = contact.phones;
            if ([code isEqualToString:@"email"]) list = contact.emails;
            if ([code isEqualToString:@"messaging"]) list = contact.messaging;
            for (int i = 0; i < list.count; i++) {
                LabelledValue *labVal = [list objectAtIndex:i];
                [self addProperty:[NSString stringWithFormat:@"contact-%@-label-%d", code, i] value:labVal.label element:propsElt];
                [self addProperty:[NSString stringWithFormat:@"contact-%@-value-%d", code, i] value:labVal.value element:propsElt];
            }
        }
    }
    
    yooMsg.date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
    [df setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [self addProperty:@"sendDate" value:[df stringFromDate:yooMsg.date] element:propsElt];
    
    if (yooMsg.type == ymtCallRequest) {
        [self addProperty:@"conferenceNumber" value:yooMsg.conferenceNumber element:propsElt];
    }
    if (yooMsg.type == ymtCallStatus) {
        [self addProperty:@"callStatus" value:[NSString stringWithFormat:@"%ld", (long)yooMsg.callStatus] element:propsElt];
        [self addProperty:@"callReqId" value:yooMsg.callReqId element:propsElt];
    }
    
    if (yooMsg.type != ymtInvite && yooMsg.type != ymtRevoke && ![yooMsg.to.toJID hasSuffix:CONFERENCE_DOMAIN] && yooMsg.type !=ymtMessageRead) {
        // ask for a receipt
        NSXMLElement *receiptElt = [[NSXMLElement alloc] initWithName:@"request" URI:@"urn:xmpp:receipts"];
        [message addChild:receiptElt];
    }

    if (yooMsg.type != ymtInvite && yooMsg.type != ymtRevoke && yooMsg.type != ymtCallStatus) {
        if (yooMsg.yooId == nil) {
            [self addInHistory:yooMsg];
        }
    }

    // Check network status
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        // clear the present table
        [self.present removeAllObjects];
        [self.invisible removeAllObjects];
        self.xmppStream = nil;
    }
    
    // check xmpp status
    if (self.xmppStream == nil || !self.xmppStream.isConnected || !self.xmppStream.isAuthenticated) {
        [self.present removeAllObjects];
        [self.invisible removeAllObjects];
        [self broadcast:@selector(didLogin:) param:@"DISCONNECT"];
        [self login:self.login password:self.password];
        return;
    }
    
    if (![yooMsg.to isMemberOfClass:[YooBroadcast class]]) {
        [self mustSend:message];
    }
    
}

- (void)addProperty:(NSString *)name value:(NSString *)value element:(NSXMLElement *)element {
    NSXMLElement *propElt = [[NSXMLElement alloc] initWithName:@"property"];
    [element addChild:propElt];
    NSXMLElement *propNameElt = [[NSXMLElement alloc] initWithName:@"name"];
    [propElt addChild:propNameElt];
    [propNameElt setStringValue:name];
    NSXMLElement *propValueElt = [[NSXMLElement alloc] initWithName:@"value"];
    [propValueElt addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"string"]];
    [propElt addChild:propValueElt];
    [propValueElt setStringValue:value];
}


- (void)setDevice:(NSString *)deviceToken {
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"yoo:iq:device"];

    NSXMLElement *deviceElt = [NSXMLElement elementWithName:@"device"];
    [deviceElt setStringValue:deviceToken];
    [queryElt addChild:deviceElt];

    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addChild: queryElt];
    
    [self mustSend: iqStanza];
}



- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    if ([presence.from.domain isEqualToString:CONFERENCE_DOMAIN]) {
        NSArray *xElts = [presence elementsForLocalName:@"x" URI:@"http://jabber.org/protocol/muc#user"];
        if (xElts.count == 1) {
            NSXMLElement *xElt = [xElts objectAtIndex:0];
            NSArray *statusElts = [xElt elementsForName:@"status"];
            if (statusElts.count > 0 && ![presence.type isEqualToString:@"unavailable"]) {
                [self confirmGroup:[presence.from full]];
            }
            // if some users have been revoked, update the member list
            NSArray *itemElts = [xElt elementsForName:@"item"];
            for (NSXMLElement *itemElt in itemElts) {
                NSString *jid = [itemElt attributeForName:@"jid"].stringValue;
                if ([jid rangeOfString:@"/"].location != NSNotFound) {
                    jid = [jid substringToIndex:[jid rangeOfString:@"/"].location];
                }
                NSString *affiliation = [itemElt attributeForName:@"affiliation"].stringValue;
                if ([affiliation isEqualToString:@"none"]) {
                    [GroupDAO removeMember:jid fromGroup:presence.from.bare];
                }
            }
        }
    } else if (![presence.from.user isEqualToString:REGISTRATION_USER] &&
               ![presence.to.user isEqualToString:REGISTRATION_USER] && [presence.from.domain isEqualToString:YOO_DOMAIN]) {
        YooUser *yooUser = [UserDAO find:presence.from.user domain:presence.from.domain];
        if ([[ContactManager sharedInstance].removed containsObject:[[YooUser alloc] initWithName:presence.from.user domain:presence.from.domain].toJID]) {
            // this user has been deleted ; deregister from him
            [self removeFriend:yooUser.toJID];
        } else {
            if (yooUser == nil) {
                yooUser = [self checkFriend:presence.from.user domain:presence.from.domain];
            }
            [UserDAO setLastOnline:[yooUser toJID]];
            if ([presence.type isEqualToString:@"unavailable"]) {
                [self.present removeObject:[yooUser toJID]];
                [self.invisible removeObject:[yooUser toJID]];
            } else if ([presence.type isEqualToString:@"subscribe"]){
                XMPPPresence *rPresence = [[XMPPPresence alloc] initWithType:@"subscribed" to:[XMPPJID jidWithUser:yooUser.name domain:yooUser.domain resource:nil]];
                [self mustSend:rPresence];
            } else {
             //check user visibilty
              NSArray *visibility = [presence elementsForName:@"status"];
                if ([visibility count]>0) {
                    [self.invisible addObject:yooUser.toJID];
                }else{
                    if ([self.invisible containsObject:yooUser.toJID]) {
                        [self.invisible removeObject:yooUser.toJID];
                    }
                }
                if (![self.present containsObject:yooUser.toJID]) {
                    [self.present addObject:yooUser.toJID];
                }
                
                NSArray *xElts = [presence elementsForName:@"x"];
                if (xElts.count > 0) {
                    DDXMLElement *xElt = [xElts objectAtIndex:0];
                    NSString *nsReq = [[xElt namespaceForPrefix:@""] stringValue];
                    if ([nsReq isEqualToString:@"vcard-temp:x:update"]) {
                        // a contact has updated his photo !
                        // check if we have different SHA1, and
                        // obtain his new VCard, if it's not ourselves
                        NSArray *photoElts = [xElt elementsForName:@"photo"];
                        if (photoElts.count > 0) {
                            DDXMLElement *photoElt = (DDXMLElement *)[photoElts objectAtIndex:0];
                            NSString *newSha1 = [photoElt stringValue];
                            unsigned char digest[CC_SHA1_DIGEST_LENGTH];
                            NSMutableString *digestString = [[NSMutableString alloc] init];
                            if (CC_SHA1([yooUser.picture bytes], (unsigned int)[yooUser.picture length], digest)) {
                                for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
                                    [digestString appendString:[NSString stringWithFormat:@"%02X", digest[i]]];
                                }
                            }
                            if (![newSha1 isEqualToString:digestString]) {
                                if (![presence.from.user isEqualToString:self.login]
                                        || ![presence.from.domain isEqualToString:YOO_DOMAIN]) {
                                    [self requestVCard:presence.from.bare];
                                }
                            }
                        }
                    }
                }
            }
            [self broadcast:@selector(friendListChanged:) param:@[yooUser]];
        }
    }
}


- (BOOL)isPresent:(YooUser *)user {
    return [self.present containsObject:[user toJID]] && ![self.invisible containsObject:[user toJID]];
}

- (BOOL)isInvisible:(YooUser *)user{
    return [self.invisible containsObject:[user toJID]];
}

- (NSArray *)listUsers {
    // sort online users first, offline after
    NSArray *tmp = [UserDAO list];
//    NSMutableArray *users = [NSMutableArray array];
//    for (int i = 0; i < 2; i++) {
//        for (YooUser *user in tmp) {
//            if ((i == 0 && [self isPresent:user]) || (i == 1 && ![self isPresent:user])) {
//                [users addObject:user];
//            }
//        }
//    }
    return tmp;
}


- (void)obtainContact:(NSArray *)batchList {
    for (NSArray *batch in batchList) {
        NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"yoo:iq:finduser"];
        BOOL found = NO;
        for (NSNumber *contactId in batch) {
            // the contact in DB does not stores the phone, need to call the AddressBook API
            Contact *fullContact = [[ContactManager sharedInstance] find:contactId.integerValue];
            if (fullContact.phones.count > 0) {
                BOOL foundPhone = NO;
                [self.tested addObject:contactId];
                NSXMLElement *userElt = [NSXMLElement elementWithName:@"user"];
                NSXMLElement *idElt = [NSXMLElement elementWithName:@"id"];
                [idElt setStringValue:[NSString stringWithFormat:@"%ld", (long)contactId.integerValue]];
                [userElt addChild:idElt];
                NSXMLElement *phonesElt = [NSXMLElement elementWithName:@"phones"];
                [userElt addChild:phonesElt];
                for (LabelledValue *phone in fullContact.phones) {
                    NSArray *formattedPhones = [[LocationTools sharedInstance] fullPhones:phone.value];
                    for (NSString *formattedPhone in formattedPhones) {
                        foundPhone = YES;
                        NSXMLElement *phoneElt = [NSXMLElement elementWithName:@"phone"];
                        [phoneElt setStringValue:formattedPhone];
                        [phonesElt addChild:phoneElt];
                    }
                }
                if (foundPhone) {
                    found = YES;
                    [queryElt addChild:userElt];
                }
            }
        }
        
        
        if (found) {
            NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
            [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"get"]];
            [iqStanza addChild: queryElt];
            
            [self mustSend: iqStanza];
        }
    }
}

- (void)getUsersFromContacts {
    if (!self.countryReady || !self.contactsReady) return;

    NSArray *contacts = [ContactDAO list];
    NSMutableArray *batchList = [NSMutableArray array];
    NSMutableArray *batch = [NSMutableArray array];
    for (Contact *contact in contacts) {
        NSNumber *contactId = [NSNumber numberWithInteger:contact.contactId];
        if (contact.hasPhone) {
            if ([self.tested containsObject:contactId]) continue;
            [batch addObject:contactId];
            if (batch.count == 10) {
                [batchList addObject:[NSArray arrayWithArray:batch]];
                [batch removeAllObjects];
            }
        }
    }
    if (batch.count > 0) {
        [batchList addObject:[NSArray arrayWithArray:batch]];
        
    }
    if (batchList.count > 0) {
        [self performSelectorInBackground:@selector(obtainContact:) withObject:batchList];
    }

}

- (void)markAsRead:(NSObject<YooRecipient> *)recipient {
    NSArray *unread = [ChatDAO unreadList:recipient];
    for (YooMessage *yooMsg in unread) {
        //send message ymtmessageread
        yooMsg.type = ymtMessageRead;
        // switch reciptient
        NSObject<YooRecipient> *tmp = yooMsg.to;
        yooMsg.to = yooMsg.from;
        yooMsg.from = tmp;
        
        [self sendMessage:yooMsg];
    }
    if ([unread count]>0) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [ChatDAO markAsRead:recipient.toJID];
//        });
    }
}
    
+ (NSString *)genRandStringLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    return randomString;
}

+ (NSString *)getCodeFromString:(NSString *)s {
    s = [s lowercaseString];
    NSMutableString *ms = [[NSMutableString alloc] init];
    for (int i = 0; i < s.length; i++) {
        unichar c = [s characterAtIndex:i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) {
            [ms appendFormat:@"%c", c];
        }
    }
    return ms;
}


- (NSString *)getStatus {
    if (self.xmppStream != nil && self.xmppStream.isAuthenticated && self.xmppStream.isConnected) {
        return @"Online";
    } else {
        return @"Disconnected";
    }
}

- (void)confirmGroup:(NSString *)groupJid {
    //    <iq from='crone1@shakespeare.lit/desktop'
    //    id='create1'
    //    to='coven@chat.shakespeare.lit'
    //    type='set'>
    //    <query xmlns='http://jabber.org/protocol/muc#owner'>
    //    <x xmlns='jabber:x:data' type='submit'>
    //    <field var='muc#roomconfig_roomname'>
    //    <value>A Dark Cave</value>
    //    </field>
    //    <field var='muc#roomconfig_persistentroom'>
    //    <value>0</value>
    //    </field>
    //    </x>
    //    </query>
    //    </iq>
    
    NSString *groupCode = [[groupJid componentsSeparatedByString:@"@"] objectAtIndex:0];
    NSString *alias = [self.roomAliases objectForKey:groupCode];
    if (alias == nil) return;
    
    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[self getMyJid]]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"creategroup"]];

    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#owner"];
    NSXMLElement *xElt = [NSXMLElement elementWithName:@"x" URI:@"jabber:x:data"];
    [xElt addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"submit"]];
    
    for (NSString *field in @[@"muc#roomconfig_roomname", @"muc#roomconfig_persistentroom",
                              /*@"muc#roomconfig_membersonly", */@"muc#roomconfig_allowinvites"]) {
        NSArray *values = nil;
        if ([field hasSuffix:@"roomname"]) {
            values = @[alias];
        } else if ([field hasSuffix:@"persistentroom"] || [field hasSuffix:@"membersonly"] || [field hasSuffix:@"allowinvites"]) {
            values = @[@"1"];
        }
        NSXMLElement *fieldElt = [NSXMLElement elementWithName:@"field"];
        [fieldElt addAttribute:[DDXMLNode attributeWithName:@"var" stringValue:field]];
        for (NSString *value in values) {
            NSXMLElement *valueElt = [NSXMLElement elementWithName:@"value"];
            NSXMLElement *valueTxt = [NSXMLElement textWithStringValue:value];
            [valueElt addChild:valueTxt];
            [fieldElt addChild:valueElt];
        }
        [xElt addChild:fieldElt];
    }

    [queryElt addChild:xElt];
    [iqStanza addChild: queryElt];

    [self mustSend: iqStanza];
}

- (void)createGroup:(NSString *)groupName users:(NSArray *)users {

    NSString *groupCode = [NSString stringWithFormat:@"%@-%@", self.login, [ChatTools getCodeFromString:groupName]];
    if (groupCode.length == 0) return;
    
    [self.roomUsers setObject:users forKey:groupCode];
    [self.roomAliases setObject:groupName forKey:groupCode];
    
    [self checkGroup:groupCode];
    
//    <presence
//    from='crone1@shakespeare.lit/desktop'
//    to='coven@chat.shakespeare.lit/firstwitch'>
//    <x xmlns='http://jabber.org/protocol/muc'/>
//    </presence>
    
    XMPPPresence *presence = [[XMPPPresence alloc] initWithType:nil to:[XMPPJID jidWithUser:groupCode domain:@"conference.yoo-app.com" resource:self.login]];
    DDXMLNode *xElt = [DDXMLNode elementWithName:@"x" URI:@"http://jabber.org/protocol/muc"];
    [presence addChild:xElt];
    [self mustSend:presence];
}


- (NSString *)getMyJid {
    return [NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN];
}

- (void)destroyGroup:(NSString *)groupJid {
//    <iq from='crone1@shakespeare.lit/desktop'
//    id='begone'
//    to='heath@chat.shakespeare.lit'
//    type='set'>
//    <query xmlns='http://jabber.org/protocol/muc#owner'>
//    <destroy jid='coven@chat.shakespeare.lit'>
//    <reason>Macbeth doth come.</reason>
//    </destroy>
//    </query>
//    </iq>
    
    NSString *meJid = [self getMyJid];
    for (NSString *userJid in [GroupDAO listMembers:groupJid]) {
        if (![userJid hasPrefix:meJid]) {
            [self removeUser:userJid fromGroup:groupJid];
        }
    }
    
    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[self getMyJid]]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"destroyroom"]];
    
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#owner"];
    NSXMLElement *destroyElt = [NSXMLElement elementWithName:@"destroy"];
    [destroyElt addAttribute:[DDXMLNode attributeWithName:@"jid" stringValue:groupJid]];
    [queryElt addChild:destroyElt];
    [iqStanza addChild:queryElt];
    [self mustSend:iqStanza];
}


- (void)lastPresence:(NSString *)jid {
    // request another user's last presence time
    XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get" to:[XMPPJID jidWithString:jid]];
    DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:last"];
    DDXMLNode *query = [DDXMLNode elementWithName:@"query" children:nil attributes:@[attrNS]];
    [iq addChild:query];
    [self mustSend:iq];
    
}

- (void)cancelCall:(YooMessage *)call {
    NSString *userJid = [ChatTools sharedInstance].getMyJid;
    [ChatDAO updateCall:userJid ident:call.ident status:csCancelled];
    
    // send message to inform correspondants of cancellation
    YooMessage *yooMsg = [[YooMessage alloc] init];
    yooMsg.type = ymtCallStatus;
    yooMsg.to = [self.confMembers objectForKey:call.ident];
    yooMsg.callReqId = call.ident;
    yooMsg.callStatus = csCancelled;
    [self sendMessage:yooMsg];
}

- (void)answerCall:(YooMessage *)call accept:(BOOL)accept {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOutCall:) object:[self lastCall]];
    [ChatDAO updateCall:call.from.toJID ident:call.ident status:accept ? csAccepted : csRejected];
    [self broadcast:@selector(handlePhoneCall:) param:call];
    
    YooMessage *response = [[YooMessage alloc] init];
    response.to = [UserDAO findByJid:call.from.toJID];
    response.type = ymtCallStatus;
    response.callReqId = call.ident;
    if (accept) {
        // Accept
        response.callStatus = csAccepted;
        NSError *jsonError;
        NSData *confData = [call.conferenceNumber dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *confJson = [NSJSONSerialization JSONObjectWithData:confData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        NSString *telNumber = [confJson objectForKey:[self getMyJid]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", telNumber]]];
    } else {
        // Reject
        response.callStatus = csRejected;
    }
    [self sendMessage:response];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [ChatTools stopSound];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOutCall:) object:[self lastCall]];
    if ([alertView isKindOfClass:[UICustomAlertViewVC class]]) {
        UICustomAlertViewVC *alert = (UICustomAlertViewVC *) alertView;
        [[ChatTools sharedInstance] answerCall:alert.call accept:buttonIndex == 1];
    }
}

@end
