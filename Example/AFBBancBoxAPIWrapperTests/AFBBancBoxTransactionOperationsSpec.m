//
//  AFBBancBoxTransactionOperationsSpec.m
//  AFBBancBoxAPIWrapper
//
//  Created by Adam Block on 8/6/13.
//  Copyright (c) 2013 Adam Block. All rights reserved.
//

#import <Kiwi.h>
#import "AFBBancBoxSpecValidEnumerationMatcher.h"
#import "AFBAsyncSpecPoller.h"
#import "AFBBancBoxPrivateExternalAccountData.h"
#import "AFBBancBoxConnection.h"
#import "AFBBancBoxClient.h"
#import "AFBBancBoxResponse.h"
#import "AFBBancBoxInternalAccount.h"
#import "AFBBancBoxExternalAccountBank.h"
#import "AFBBancBoxLinkedExternalAccount.h"
#import "AFBBancBoxPerson.h"
#import "AFBBancBoxPaymentItem.h"
#import "AFBBancBoxPaymentItemStatus.h"
#import "AFBBancBoxSchedule.h"
#import "NSDate+Utilities.h"

// Note that in order for these tests to run you need to create a header file called "AFBBancBoxPrivateExternalAccountData.h"
// containing account details for linked external accounts.

SPEC_BEGIN(TransactionOperationsSpec)

describe(@"The BancBox API wrapper", ^{
    registerMatchers(@"AFB");
    
    AFBBancBoxConnection *conn = [AFBBancBoxConnection new];
    NSString *subscriberReferenceId = [NSString stringWithFormat:@"BancBoxTestClient-%i", (int)[[NSDate date] timeIntervalSince1970]];
    
    AFBBancBoxClient *client = [AFBBancBoxClient new];
    client.clientIdSubscriberReferenceId = subscriberReferenceId;
    client.firstName = BANCBOX_CLIENT_DATA_FIRSTNAME;
    client.lastName = BANCBOX_CLIENT_DATA_LASTNAME;
    client.dob = [[AFBBancBoxPerson birthdateDateFormatter] dateFromString:BANCBOX_CLIENT_DATA_DOB];
    client.ssn = BANCBOX_CLIENT_DATA_SSN;
    
    // first create a new client we can work with
    __block BOOL addClientDone = NO;
    __block AFBBancBoxClient *createdClient;
    
    [conn createClientWithObject:client success:^(AFBBancBoxResponse *response, id obj) {
        createdClient = obj;
        addClientDone = YES;
    } failure:^(AFBBancBoxResponse *response, id obj) {
        addClientDone = YES;
    }];
    
    POLL(addClientDone);
    
    // verify client -- in Sandbox this will only work when the specific customer data is passed in createClient
    __block BOOL verifyClientDone;
    [conn verifyClient:createdClient generateQuestions:NO success:^(AFBBancBoxResponse *response, id obj) {
        verifyClientDone = YES;
    } failure:^(AFBBancBoxResponse *response, id obj) {
        verifyClientDone = YES;
    }];
    
    POLL(verifyClientDone);
    
    
    // Open account
    __block BOOL openAccountDone = NO;
    
    __block AFBBancBoxInternalAccount *internalAccount;
    [conn openRoutableAccountForClient:createdClient title:@"Joe's Bank Account" success:^(AFBBancBoxResponse *response, id obj) {
        openAccountDone = YES;
        internalAccount = obj;
    } failure:^(AFBBancBoxResponse *response, id obj) {
        openAccountDone = YES;
    }];
    
    POLL(openAccountDone);
    
    // Link external bank account
    
    __block BOOL linkExternalAccountDone = NO;
    __block AFBBancBoxLinkedExternalAccount *linkedAccount;
    AFBBancBoxExternalAccountBank *bankAccount = [[AFBBancBoxExternalAccountBank alloc] initWithRoutingNumber:BANCBOX_LINK_EXTERNAL_ACCOUNT_BANK_ROUTING_NUMBER accountNumber:BANCBOX_LINK_EXTERNAL_ACCOUNT_BANK_ACCOUNT_NUMBER holderName:BANCBOX_LINK_EXTERNAL_ACCOUNT_BANK_HOLDER_NAME bankAccountType:BancBoxExternalAccountBankTypeChecking];
    NSString *bankExternalAccountId = [NSString stringWithFormat:@"ExAcctBk-%i", (int)[[NSDate date] timeIntervalSince1970]];
    
    [conn linkExternalAccount:bankAccount accountReferenceId:bankExternalAccountId forClient:createdClient success:^(AFBBancBoxResponse *response, id obj) {
        linkedAccount = obj;
        linkExternalAccountDone = YES;
    } failure:^(AFBBancBoxResponse *response, id obj) {
        linkExternalAccountDone = YES;
    }];
    POLL(linkExternalAccountDone);
    
    // Collect a credit card payment
    context(@"when collecting an ACH payment", ^{
    
        __block BOOL collectPaymentDone = NO;
        AFBBancBoxExternalAccountBank *sourceAccount = [[AFBBancBoxExternalAccountBank alloc] initWithRoutingNumber:BANCBOX_LINK_EXTERNAL_ACCOUNT_BANK_ROUTING_NUMBER_2 accountNumber:BANCBOX_LINK_EXTERNAL_ACCOUNT_BANK_ACCOUNT_NUMBER_2 holderName:BANCBOX_LINK_EXTERNAL_ACCOUNT_BANK_HOLDER_NAME_2 bankAccountType:BancBoxExternalAccountBankTypeChecking];
        
        NSString *referenceId = [NSString stringWithFormat:@"collect-%0.0f", [[NSDate date] timeIntervalSince1970]];
        AFBBancBoxPaymentItem *item = [[AFBBancBoxPaymentItem alloc] initWithPaymentAmount:100.0 scheduleDate:nil referenceId:referenceId memo:@"Untitled job"];
        [conn collectFundsFromSource:sourceAccount destination:internalAccount method:BancBoxCollectPaymentMethodAch items:@[ item ] success:^(AFBBancBoxResponse *response, id obj) {
            __block NSArray *paymentItemStatuses = (NSArray *)obj;
            
            it(@"should be successful", ^{
                [[response.statusDescription should] equal:BancBoxResponseStatusDescriptionPass];
            });
            
            it(@"should return an array of PaymentItemStatuses", ^{
                [[paymentItemStatuses should] haveCountOf:1];
            });
            
            collectPaymentDone = YES;
        } failure:^(AFBBancBoxResponse *response, id obj) {
            collectPaymentDone = YES;
        }];
                                       
        POLL(collectPaymentDone);
    });
    
    context(@"after collecting an ACH payment", ^{
        
        __block BOOL getSchedulesDone = NO;
        [conn getSchedules:@{@"accountId": [internalAccount idDictionary]} success:^(AFBBancBoxResponse *response, id obj) {
            __block NSArray *schedules = (NSArray *)obj;
            it(@"the payment should show up in a schedule", ^{
                [[schedules should] haveCountOf:1];
            });
            
            __block AFBBancBoxSchedule *schedule = schedules.lastObject;
            it(@"the schedule should have data that matches the transaction", ^{
                [[schedule.status should] equal:@"IN_PROCESS"];
                [[schedule.type should] equal:@"COLLECT"];
                [[theValue(schedule.amount) should] equal:100.0 withDelta:0.0];
            });
            
            getSchedulesDone = YES;
        } failure:^(AFBBancBoxResponse *response, id obj) {
            getSchedulesDone = YES;
        }];
        POLL(getSchedulesDone);
    });
    
    context(@"when disbursing a payment", ^{
        __block BOOL sendFundsDone = NO;
        
        NSString *referenceId = [NSString stringWithFormat:@"send-%0.0f", [[NSDate date] timeIntervalSince1970]];
        AFBBancBoxPaymentItem *item = [[AFBBancBoxPaymentItem alloc] initWithPaymentAmount:100.0 scheduleDate:nil referenceId:referenceId memo:@"Untitled job"];
        [conn sendFundsViaAchFromAccount:internalAccount toLinkedExternalAccount:linkedAccount items:@[ item ] success:^(AFBBancBoxResponse *response, id obj) {
            __block NSArray *paymentItemStatuses = (NSArray *)obj;
            
            it(@"should be successful", ^{
                [[response.statusDescription should] equal:BancBoxResponseStatusDescriptionPass];
            });
            
            it(@"should return an array of PaymentItemStatuses", ^{
                [[paymentItemStatuses should] haveCountOf:1];
            });
            
            sendFundsDone = YES;
        } failure:^(AFBBancBoxResponse *response, id obj) {
            sendFundsDone = YES;
        }];
        
        POLL(sendFundsDone);
    });
});

SPEC_END
