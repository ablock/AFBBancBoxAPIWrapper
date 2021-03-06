//
//  AFBBancBoxLinkedExternalAccount.m
//  Breeze
//
//  Created by Adam Block on 4/30/13.
//  Copyright (c) 2013 Adam Block. All rights reserved.
//

#import "AFBBancBoxLinkedExternalAccount.h"

@implementation AFBBancBoxLinkedExternalAccount

- (id)initWithAccountFromDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.dictionary = dict;
        self.bancBoxId = [dict[@"bancBoxId"] longLongValue];
        self.subscriberReferenceId = dict[@"subscriberReferenceId"];
    }
    return self;
}

+ (AFBBancBoxLinkedExternalAccount *)accountFromDictionary:(NSDictionary *)dict
{
    return [[AFBBancBoxLinkedExternalAccount alloc] initWithAccountFromDictionary:dict];
}

@end
