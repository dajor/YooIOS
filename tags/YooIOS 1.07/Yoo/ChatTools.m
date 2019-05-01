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

@implementation ChatTools

static ChatTools *instance = nil;

+ (ChatTools *)sharedInstance {
    if (instance == nil) {
        instance = [[ChatTools alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    self.listeners = [NSMutableArray array];
    self.present = [NSMutableArray array];
    self.tested = [NSMutableArray array];
    self.roomUsers = [NSMutableDictionary dictionary];
    self.roomAliases = [NSMutableDictionary dictionary];
    self.countryCode = nil;
    self.countryReady = NO;
    self.contactsReady = NO;
    [[ContactManager sharedInstance] addListener:self];
    return self;
}

- (void)addListener:(NSObject <ChatListener> *)listener {
    [self.listeners addObject:listener];
}

- (void)removeListener:(NSObject<ChatListener> *)listener {
    [self.listeners removeObject:listener];
}

- (void)broadcast:(SEL)selector param:(id)param {
    for (NSObject <ChatListener> *listener in self.listeners) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [listener performSelector:selector withObject:param];
#pragma clang diagnostic pop
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
    self.xmppStream.myJID = [XMPPJID jidWithUser:self.login domain:YOO_DOMAIN resource:@"mobile"];
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
    XMPPPresence *presence = [[XMPPPresence alloc] init];
    [self.xmppStream sendElement:presence];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    
    // After establishing a session, a client SHOULD send initial presence to the server in order to signal its availability for communications.
    [self sendPresence];
    
    
    [self broadcast:@selector(didLogin:) param:nil];
    
    if (![self.login isEqualToString:REGISTRATION_USER]) {
        // get friend list
        NSXMLElement *queryElement = [NSXMLElement elementWithName: @"query" URI: @"jabber:iq:roster"];
        NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
        [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"get"]];
        [iqStanza addChild: queryElement];
        
        [self.xmppStream sendElement: iqStanza];
        
        // check presence of phone contacts : we need the country code
        [[LocationTools sharedInstance] getCountryCode:self];
        
        // set device token
        [self setDevice:((AppDelegate *)[UIApplication sharedApplication].delegate).deviceToken];
        
        // send presence to all groups
        for (YooGroup *group in [GroupDAO list]) {
            // send presence to the group
            XMPPPresence *presence = [[XMPPPresence alloc] initWithType:nil to:[XMPPJID jidWithUser:group.name domain:@"conference.yoo-app.com" resource:self.login]];
            [self.xmppStream sendElement:presence];
        }
        
    }
    
    
    
    // if our profile has no picture, ask for the VCard to get one
    YooUser *me = [UserDAO find:self.login domain:YOO_DOMAIN];
    if (me.picture == nil) {
        [self requestVCard:[NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN]];
    }
    
}



- (void)setCountry:(NSString *)pCountry {
    if (self.countryCode == nil || ![self.countryCode isEqualToString:pCountry]) {
        self.countryCode = pCountry;
    }
    self.countryReady = YES;
    [self getUsersFromContacts];
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
    
    [self.xmppStream sendElement: iqStanza];
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
    
    [self.xmppStream sendElement: iqStanza];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)errorXML {
    DDLogWarn(@"Authentication failed: %@", errorXML.description);
    if (errorXML.childCount == 1 && [[errorXML childAtIndex:0].name isEqualToString:@"not-authorized"]) {
        [self broadcast:@selector(didLogin:) param:@"Wrong Login or Password"];
    } else {
        [self broadcast:@selector(didLogin:) param:errorXML.description];
    }
}

- (NSArray *)messagesForRecipient:(NSObject<YooRecipient> *)recipient withPicture:(BOOL)pict {
    return [ChatDAO list:recipient withPictures:pict];
}

- (void)addInHistory:(YooMessage *)yooMsg {
    [ChatDAO insert:yooMsg];
}

- (NSArray *)getContactFields {
    return @[@"firstName", @"lastName", @"company", @"jobTitle"];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {

    DDLogInfo(@"Received message %@", message.body);
    if ([message.type isEqualToString:@"error"]) {
        return;
    }
    
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
    yooMsg.message = message.body;
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
                    yooMsg.sound = [[NSData alloc] initWithBase64Encoding:propValue];
                }
                // attached picture
                if ([propName hasPrefix:@"picture"]) {
                    NSData *imageData = [[NSData alloc] initWithBase64Encoding:propValue];
                    //NSData *imageData = [[NSData alloc] initWithBase64EncodedString:propValue options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    if (yooMsg.pictures == nil) yooMsg.pictures = [NSMutableArray array];
                    [(NSMutableArray *)yooMsg.pictures addObject:imageData];
                }
                // location
                if ([propName isEqualToString:@"location"]) {
                    NSArray *parts = [propValue componentsSeparatedByString:@"/"];
                    yooMsg.location = CLLocationCoordinate2DMake([[parts objectAtIndex:0] doubleValue], [[parts objectAtIndex:1] doubleValue]);
                }
                // call conference
                if([propName isEqualToString:@"conferenceNumber"]){
                    yooMsg.conferenceNumber = propValue;
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
            }
        }
    }
    
    // Handle call status from recipient
    if (yooMsg.type == ymtCallStatus){
        if([yooMsg.message isEqualToString:@"approval"]){
            NSString *key = _login;
            NSString *conferenceNumber = [_mappingConferenceNumbers objectForKey:key];
            NSLog(@"key %@", key);
            NSLog(@"conferenceNumber %@", conferenceNumber);
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", conferenceNumber]]];
        }
        return;
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
                    [UserDAO upsert:newUser];
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
            yooMsg.receipt = YES;
        }
    }
    
    if (yooMsg.type != ymtAck && yooMsg.type != ymtInvite && yooMsg.type != ymtRevoke) {
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
    }
    
    // Add in roster the sender
    if ([yooMsg.from isKindOfClass:[YooUser class]] && [UserDAO find:((YooUser *)yooMsg.from).name domain:((YooUser *)yooMsg.from).domain] == nil) {
        XMPPIQ *add = [[XMPPIQ alloc] initWithType:@"set"];
        DDXMLNode *attrJid = [DDXMLNode attributeWithName:@"jid" stringValue:[message.from full]];
        DDXMLNode *item = [DDXMLNode elementWithName:@"item" children:nil attributes:@[attrJid]];
        DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"];
        DDXMLNode *query = [DDXMLNode elementWithName:@"query" children:@[item] attributes:@[attrNS]];
        [add addChild:query];
        [self.xmppStream sendElement:add];
    }

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
        [self.xmppStream sendElement:presence];
        
        // query member list
        for (NSString *affiliation in @[@"admin", @"owner"]) {
            XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get" to:[XMPPJID jidWithString:[yooGroup toJID]] elementID:@"groupmember"];
            DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/muc#admin"];
            DDXMLNode *affAttr = [DDXMLNode attributeWithName:@"affiliation" stringValue:affiliation];
            DDXMLNode *itemElt = [DDXMLNode elementWithName:@"item" children:nil attributes:@[affAttr]];
            DDXMLNode *queryElt = [DDXMLNode elementWithName:@"query" children:@[itemElt] attributes:@[attrNS]];;
            [iq addChild:queryElt];
            [self.xmppStream sendElement:iq];
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
        [self.xmppStream sendElement:subscribe];
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
    [self.xmppStream sendElement:iq];

}

- (void)requestCallStatusFromRecipient:(NSString *) status{
    XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get"];
    DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"yoo:iq:callstatus"];
    DDXMLNode *query = [DDXMLNode elementWithName:@"query" children:nil attributes:@[attrNS]];
    query.stringValue = status;
    [iq addChild:query];
    [self.xmppStream sendElement:iq];
}

    /*
     * Request Call: send iq request to server to get conference number
     * @param: Members in conference room.
     * @param: Listener listen when success and do other functionality
    */
- (void)requestCall:(NSArray *)pMembers listener:(NSObject<CallingListener> *)listener {
    XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get"];
    DDXMLNode *attrNS = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"yoo:iq:call"];
    DDXMLNode *query = [DDXMLNode elementWithName:@"query" children:nil attributes:@[attrNS]];
    self.callingDelegate = listener;
    NSString *names = @"";
    for(YooUser *user in pMembers){
        if([names length] > 0){
            names = [names stringByAppendingString:@", "];
        }
        names = [self toJSonStringWithKeysAndValues:@"Name", user.toJID, @"Country", user.countryCode == nil ? @" ": user.countryCode, nil];
    }
    NSUserDefaults *userdefault = [NSUserDefaults standardUserDefaults];
    NSString *pCountryCode = [userdefault stringForKey:@"countryCode"];
    NSString *pName = [userdefault stringForKey:@"nickname"];
    NSString *jsonData = [self toJSonStringWithKeyAndValueObject:@"Invitees" valueObject:[NSString stringWithFormat:@"[%@]", names] keysAndValues:@"Name", pName, @"Country", pCountryCode, @"Type", @"Call", nil];
    query.stringValue = jsonData;
    [iq addChild:query];
    [self.xmppStream sendElement:iq];
}

- (NSString *) toJSonStringWithKeyAndValueObject:(NSString *) key valueObject:(NSString *)valueObject keysAndValues:(NSString *) first, ... NS_REQUIRES_NIL_TERMINATION{
    NSString *str = [NSString stringWithFormat:@"\"%@\"", first];
    va_list args;
    va_start(args, first);
    id arg = nil;
    int index = 1;
    while((arg = va_arg(args, id))){
        if(![arg isEqual:nil] && ![arg isEqual:[NSNull null]]){
            int moduloe = index % 2;
            if(index >=2 && moduloe == 0){
                str = [str stringByAppendingString:@", "];
            }
            if([str length] > 0 && moduloe != 0){
                str = [str stringByAppendingString:@":"];
            }
            str = [str stringByAppendingFormat:@"\"%@\"", arg];
            index ++;
        }
    }
    va_end(args);
    if([str length] > 0){
        str = [str stringByAppendingString:@", "];
    }
    str = [str stringByAppendingFormat:@"\"%@\":%@", key, valueObject];
    if([str length] > 0){
        str = [NSString stringWithFormat:@"{%@}", str];
    }
    return str;
}

- (NSString *) toJSonStringWithKeysAndValues:(NSString *) first, ... NS_REQUIRES_NIL_TERMINATION{
    NSString *str = [NSString stringWithFormat:@"\"%@\"", first];
    va_list args;
    va_start(args, first);
    id arg = nil;
    int index = 1;
    while((arg = va_arg(args, id))){
        if(![arg isEqual:nil] && ![arg isEqual:[NSNull null]]){
            int moduloe = index % 2;
            if(index >=2 && moduloe == 0){
                str = [str stringByAppendingString:@", "];
            }
            if([str length] > 0 && moduloe != 0){
                str = [str stringByAppendingString:@":"];
            }
            str = [str stringByAppendingFormat:@"\"%@\"", arg];
            index ++;
        }
    }
    va_end(args);
    if([str length]>0){
        str = [NSString stringWithFormat:@"{%@}", str];
    }
    return str;
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
                XMPPJID *xmppJid = [XMPPJID jidWithString:jid];
                if ([xmppJid.domain isEqualToString:CONFERENCE_DOMAIN]) {
                    // received from group
                    //[self checkGroup:xmppJid.user];
                } else {
                    [self checkFriend:xmppJid.user domain:xmppJid.domain];
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
                
                DDXMLElement *countryCodeElt = [[userElt elementsForName:@"countryCode"] objectAtIndex:0];
                NSString *countryCode = countryCodeElt.stringValue;
                
                YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
                Contact *contact = [[ContactManager sharedInstance] find:contactId];
                if (yooUser == nil) {
                    yooUser = [self checkFriend:name domain:YOO_DOMAIN];
                }
                if (contact != nil) {
                    yooUser.contactId = contact.contactId;
                    yooUser.callingCode = [callingCode intValue];
                    yooUser.countryCode = countryCode;
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

            [self.xmppStream sendElement:discoInfo];
            
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
        } else if ([ns.stringValue isEqualToString:@"yoo:iq:call"]){
            /* 
             * Handle request call and do call listener
             */
            if(self.callingDelegate != nil){
                self.mappingConferenceNumbers = [[NSMutableDictionary alloc] init];
                NSString *jsonString = queryElement.stringValue;
                NSError *error;
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                options: NSJSONReadingMutableContainers
                                                  error: &error];
                
                @try {
                if(result != nil){
                    NSUserDefaults *userdefault = [NSUserDefaults standardUserDefaults];
                    NSString *login = [userdefault stringForKey:@"login"];
                    NSObject *senderConferenceNumber = [result objectForKey:@"ConfCallNumber"];
                    if (senderConferenceNumber != [NSNull null]) {
                        [self.mappingConferenceNumbers setObject:(NSString *)senderConferenceNumber forKey:login];
                        NSArray *invitees = [result objectForKey:@"Invitees"];
                        for (NSDictionary *invitee in invitees){
                            NSString *key = [invitee objectForKey:@"Name"];
                            NSString *object = [invitee objectForKey:@"ConfCallNumber"];
                            [self.mappingConferenceNumbers setObject:object forKey:key];
                        }
                        [self.callingDelegate didCallSendOutMessage];
                    }else{
                        // Issued #8733
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"ERROR_NO_CONFERENCE_NUMBER", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                }
                }
                @catch(NSException *exception){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Server" message:NSLocalizedString(@"ERROR_NO_CONFERENCE_NUMBER", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                }
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
                //picture = [[NSData alloc] initWithBase64EncodedString:dataBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
                picture = [[NSData alloc] initWithBase64Encoding:dataBase64];
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
                [self broadcast:@selector(friendListChanged:) param:@[yooUser]];
                [self checkAddressBook:yooUser];
            }
        }
        
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
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN]]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"revoke1"]];
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#admin"];
    NSXMLElement *itemElt = [NSXMLElement elementWithName:@"item"];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"affiliation" stringValue:@"none"]];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"jid" stringValue:userJid]];
    [queryElt addChild:itemElt];
    [iqStanza addChild:queryElt];
    [self.xmppStream sendElement: iqStanza];

    
    NSString *login = [ChatTools sharedInstance].login;
    if ([userJid hasPrefix:[NSString stringWithFormat:@"%@@", login]]) {
        // we leave the group
        XMPPPresence *presence = [[XMPPPresence alloc] initWithType:@"unavailable" to:[XMPPJID jidWithString:groupJid]];
        [self.xmppStream sendElement:presence];
    } else {
        // kick other user
        NSXMLElement *iq2Stanza = [NSXMLElement elementWithName: @"iq"];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN]]];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
        [iq2Stanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"kick1"]];
        NSXMLElement *query2Elt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#admin"];
        NSXMLElement *item2Elt = [NSXMLElement elementWithName:@"item"];
        [item2Elt addAttribute:[DDXMLNode attributeWithName:@"role" stringValue:@"none"]];
        NSArray *parts = [userJid componentsSeparatedByString:@"@"];
        [item2Elt addAttribute:[DDXMLNode attributeWithName:@"nick" stringValue:[parts objectAtIndex:0]]];
        [query2Elt addChild:item2Elt];
        [iq2Stanza addChild:query2Elt];
        [self.xmppStream sendElement: iq2Stanza];
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
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN]]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"invite1"]];
    
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#admin"];
    NSXMLElement *itemElt = [NSXMLElement elementWithName:@"item"];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"affiliation" stringValue:@"admin"]];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"jid" stringValue:userJid]];
    [itemElt addAttribute:[DDXMLNode attributeWithName:@"nick" stringValue:userJid]];
    [queryElt addChild:itemElt];
    [iqStanza addChild:queryElt];
    [self.xmppStream sendElement: iqStanza];
    
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
        DDXMLNode *binValElt = [DDXMLNode elementWithName:@"BINVAL" stringValue:[picture base64Encoding]];
        photoElt = [DDXMLNode elementWithName:@"PHOTO" children:@[typeElt, binValElt] attributes:nil];
    }
    DDXMLNode *vCardElt = [DDXMLNode elementWithName:@"vCard" children:photoElt != nil ? @[fnElt, photoElt] : @[fnElt] attributes:@[attrNS]];
    [setVCard addChild:vCardElt];
    [self.xmppStream sendElement:setVCard];
    
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
            [self.xmppStream sendElement:presence];

        }
    }

}

- (UInt64)stats:(BOOL)sent {
    return sent ? self.xmppStream.numberOfBytesSent : self.xmppStream.numberOfBytesReceived;
}

- (void)sendMessage:(YooMessage *)yooMsg {

    yooMsg.from = [[YooUser alloc] initWithName:self.login domain:YOO_DOMAIN];
    yooMsg.read = YES;
    yooMsg.ident = [ChatTools genRandStringLength:16];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:yooMsg.message == nil ? @" " : yooMsg.message];
    
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
        [self addProperty:@"sound" value:[yooMsg.sound base64Encoding] element:propsElt];
    }
    if (yooMsg.type == ymtPicture) {
        NSInteger i = 1;
        for (NSData *picData in yooMsg.pictures) {
            [self addProperty:[NSString stringWithFormat:@"picture%ld", (long)i] value:[picData base64Encoding] element:propsElt];
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
    
    if(yooMsg.type == ymtCallRequest){
//        [body setStringValue:[NSString stringWithFormat:@"Call %@", yooM]];
        yooMsg.conferenceNumber = [self.mappingConferenceNumbers objectForKey:self.login];
        NSString *receiverConferenceNumber = [self.mappingConferenceNumbers objectForKey:yooMsg.to.toJID];
        [self addProperty:@"conferenceNumber" value:receiverConferenceNumber element:propsElt];
    }
    
    if (yooMsg.type != ymtInvite && yooMsg.type != ymtRevoke && ![yooMsg.to.toJID hasSuffix:CONFERENCE_DOMAIN]) {
        // ask for a receipt
        NSXMLElement *receiptElt = [[NSXMLElement alloc] initWithName:@"request" URI:@"urn:xmpp:receipts"];
        [message addChild:receiptElt];
    }

    if (yooMsg.type != ymtInvite && yooMsg.type != ymtRevoke && yooMsg.type != ymtCallStatus) {
        [self addInHistory:yooMsg];
    }

    // Check network status
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        return;
    }
    
    // check xmpp status
    if (self.xmppStream == nil || !self.xmppStream.isConnected || !self.xmppStream.isAuthenticated) {
        [self broadcast:@selector(didLogin:) param:@"DISCONNECT"];
        [self login:self.login password:self.password];
        return;
    }
    
    if (![yooMsg.to isMemberOfClass:[YooBroadcast class]]) {
        [self.xmppStream sendElement:message];
        [ChatDAO markAsSent:yooMsg.from.toJID ident:yooMsg.ident];
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
    
    [self.xmppStream sendElement: iqStanza];
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
    } else {
        YooUser *yooUser = [UserDAO find:presence.from.user domain:presence.from.domain];
        if (yooUser == nil) {
            yooUser = [self checkFriend:presence.from.user domain:presence.from.domain];
        }
        [UserDAO setLastOnline:[yooUser toJID]];
        if ([presence.type isEqualToString:@"unavailable"]) {
            [self.present removeObject:[yooUser toJID]];
        } else if ([presence.type isEqualToString:@"subscribe"]){
            XMPPPresence *rPresence = [[XMPPPresence alloc] initWithType:@"subscribed" to:[XMPPJID jidWithUser:yooUser.name domain:yooUser.domain resource:nil]];
            [self.xmppStream sendElement:rPresence];
        } else {
            if (![self.present containsObject:yooUser.toJID]) {
                [self.present addObject:yooUser.toJID];
            }
            NSArray *xElts = [presence elementsForName:@"x"];
            if (xElts.count > 0) {
                DDXMLElement *xElt = [xElts objectAtIndex:0];
                NSString *nsReq = [[xElt namespaceForPrefix:@""] stringValue];
                if ([nsReq isEqualToString:@"vcard-temp:x:update"]) {
                    // a contact has updated his photo !
                    // obtain his new VCard, if it's not ourselves
                    if (![presence.from.user isEqualToString:self.login]
                            || ![presence.from.domain isEqualToString:YOO_DOMAIN]) {
                        [self requestVCard:presence.from.bare];
                    }
                }
            }
        }

        [self broadcast:@selector(friendListChanged:) param:@[yooUser]];
    }
}


- (BOOL)isPresent:(YooUser *)user {
    return [self.present containsObject:[user toJID]];
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


- (void)getUsersFromContacts {
    if (!self.countryReady || !self.contactsReady) return;
    BOOL found = NO;
    NSArray *contacts = [ContactDAO list];
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"yoo:iq:finduser"];
    for (Contact *contact in contacts) {
        NSNumber *contactId = [NSNumber numberWithInteger:contact.contactId];
        if (contact.hasPhone) {
            if ([self.tested containsObject:contactId]) continue;
            // the contact in DB does not stores the phone, need to call the AddressBook API
            Contact *fullContact = [[ContactManager sharedInstance] find:contactId.integerValue];
            [self.tested addObject:contactId];
            found = YES;
            NSXMLElement *userElt = [NSXMLElement elementWithName:@"user"];
            [queryElt addChild:userElt];
            NSXMLElement *idElt = [NSXMLElement elementWithName:@"id"];
            [idElt setStringValue:[NSString stringWithFormat:@"%ld", (long)contact.contactId]];
            [userElt addChild:idElt];
            NSXMLElement *phonesElt = [NSXMLElement elementWithName:@"phones"];
            [userElt addChild:phonesElt];
            for (LabelledValue *phone in fullContact.phones) {
                NSXMLElement *phoneElt = [NSXMLElement elementWithName:@"phone"];
                NSString *formattedPhone = [[LocationTools sharedInstance] fullPhone:phone.value];
                [phoneElt setStringValue:formattedPhone];
                [phonesElt addChild:phoneElt];
            }
        }
    }
    
    if (found) {
        NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
        [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"get"]];
        [iqStanza addChild: queryElt];
        
        [self.xmppStream sendElement: iqStanza];
    }
}

- (void)markAsRead:(NSObject<YooRecipient> *)recipient {
    NSArray *unread = [ChatDAO unreadList:recipient];
    for (YooMessage *yooMsg in unread) {
        if (yooMsg.receipt) {
            XMPPMessage *receipt = [[XMPPMessage alloc] initWithType:nil to:[XMPPJID jidWithString:yooMsg.from.toJID]];
            DDXMLNode *attrId = [DDXMLNode attributeWithName:@"id" stringValue:yooMsg.ident];
            DDXMLNode *attrNs = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"urn:xmpp:receipts"];
            DDXMLNode *received = [DDXMLNode elementWithName:@"received" children:nil attributes:@[attrId, attrNs]];
            [receipt addChild:received];
            [self.xmppStream sendElement:receipt];
        }
    }
    [ChatDAO markAsRead:recipient.toJID];

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
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN]]];
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

    [self.xmppStream sendElement: iqStanza];
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
    [self.xmppStream sendElement:presence];
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
    
    NSString *meJid = [NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN];
    for (NSString *userJid in [GroupDAO listMembers:groupJid]) {
        if (![userJid hasPrefix:meJid]) {
            [self removeUser:userJid fromGroup:groupJid];
        }
    }
    
    
    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"set"]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@", self.login, YOO_DOMAIN]]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"to" stringValue:groupJid]];
    [iqStanza addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"destroyroom"]];
    
    NSXMLElement *queryElt = [NSXMLElement elementWithName: @"query" URI: @"http://jabber.org/protocol/muc#owner"];
    NSXMLElement *destroyElt = [NSXMLElement elementWithName:@"destroy"];
    [destroyElt addAttribute:[DDXMLNode attributeWithName:@"jid" stringValue:groupJid]];
    [queryElt addChild:destroyElt];
    [iqStanza addChild:queryElt];
    [self.xmppStream sendElement:iqStanza];
}


@end
