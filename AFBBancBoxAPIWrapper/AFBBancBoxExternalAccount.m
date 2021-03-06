//
//  AFBBancBoxExternalAccount.m
//  Breeze
//
//  Created by Adam Block on 4/26/13.
//  Copyright (c) 2013 Adam Block. All rights reserved.
//

#import "AFBBancBoxExternalAccount.h"
#import "AFBBancBoxExternalAccountBank.h"
#import "AFBBancBoxExternalAccountCard.h"
#import "AFBBancBoxExternalAccountPaypal.h"

@implementation AFBBancBoxExternalAccount

- (id)initWithExternalAccountFromDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self extractCommonElementsFromDictionary:dict idKey:@"id"];
    }
    return self;
}

+ (id)externalAccountFromDictionary:(NSDictionary *)dict
{
    id instance;
    
    if (dict[@"account"][@"bankAccount"])   instance = [AFBBancBoxExternalAccountBank externalAccountFromDictionary:dict];
    if (dict[@"account"][@"cardAccount"])   instance = [AFBBancBoxExternalAccountCard externalAccountFromDictionary:dict];
    if (dict[@"account"][@"paypalAccount"]) instance = [AFBBancBoxExternalAccountPaypal externalAccountFromDictionary:dict];
    
    return instance;
}


- (void)extractCommonElementsFromDictionary:(NSDictionary *)dict idKey:(NSString *)idKey
{
    self.dictionary = dict;
    self.bancBoxId = [dict[idKey][@"bancBoxId"] longLongValue];
    self.subscriberReferenceId = dict[idKey][@"subscriberReferenceId"];
    self.externalAccountStatus = dict[@"externalAccountStatus"];
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (self.bancBoxId > 0 || self.subscriberReferenceId) {
        NSMutableDictionary *idDict = [NSMutableDictionary dictionary];
        if (self.bancBoxId > 0) idDict[@"bancBoxId"] = [NSNumber numberWithLongLong:self.bancBoxId];
        if (self.subscriberReferenceId) idDict[@"subscriberReferenceId"] = self.subscriberReferenceId;
        dict[@"id"] = idDict;
    }
    
    if (self.externalAccountStatus) dict[@"externalAccountStatus"] = self.externalAccountStatus;
    
    return dict;
}

- (NSDictionary *)accountDetailsDictionary
{
    return [NSDictionary dictionary];
}

- (NSString *)description
{
    return self.dictionary.description;
}

@end
