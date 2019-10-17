/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "UIManualPlugin.h"

@interface UIManualPlugin()

@property (nonatomic,strong) CTContext *myContext;
//generator group
@property (strong, nonatomic) NSString *instanceID;
@property (assign, nonatomic) int numberOfUnits;
@property (assign, nonatomic) int numberOfGroups;
@property (strong, nonatomic) NSMutableSet *ownedIdentifiers;
@property (atomic,strong) NSMutableString *message;
@property (nonatomic,strong) NSDictionary *snDic;
@property (nonatomic,assign) BOOL showStartDialgFlag;
@property (nonatomic,assign) BOOL isFirstTest;
@property (nonatomic,strong) NSString *testMode;

@end

@implementation UIManualPlugin

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        // enter initialization code here
        _instanceID = [[[NSUUID new] UUIDString] substringToIndex:6];
        _ownedIdentifiers = [NSMutableSet new];
        [_message setString:@""];
        _isFirstTest=YES;
        _testMode=@"debug"; //@"debug"
    }

    return self;
}

// For plugins that implement this method, Atlas will log the returned CTVersion
// on plugin launch, otherwise Atlas will log the version info of the bundle
// containing the plugin.
 - (CTVersion *)version
 {
     return [[CTVersion alloc] initWithVersion:@"1"
                           projectBuildVersion:@"1"
                              shortDescription:@"Popup scan SNs form For manual test"];
 }

- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    // Do plugin setup work here
    // This context is safe to store a reference of

    // Can also register for event at any time. Requires a selector that takes in one argument of CTEvent type.
    // [context registerForEvent:CTEventTypeUnitAppeared selector:@selector(handleUnitAppeared:)];
    // [context registerForEvent:@"Random event" selector:@selector(handleSomeEvent:)];
    /*
     params={
     "numberOfGroups":"1",
     "numberOfUnit":"1",
     "afterTestDelay":"2",
     "showStartDialog":"0"
     }
     */
    _myContext=context;
    self.numberOfUnits=1;
    if (context.parameters[@"numberOfUnit"] != nil) {
        self.numberOfUnits = [context.parameters[@"numberOfUnit"] intValue];
    }
    self.numberOfGroups=1;
    if (context.parameters[@"numberOfGroups"] != nil) {
        self.numberOfGroups = [context.parameters[@"numberOfGroups"] intValue];
    }
    double delay=2.0;
    if(context.parameters[@"afterTestDelay"] != nil){
        delay=[context.parameters[@"afterTestDelay"] doubleValue];
    }
    self.showStartDialgFlag=NO;
    if (context.parameters[@"showStartDialog"] != nil) {
        self.showStartDialgFlag=[context.parameters[@"showStartDialog"] boolValue];
    }
    [context registerForEvent:CTEventTypeGroupFinished callback:^(CTEvent *event){
        @autoreleasepool
        {
            CTLog(CTLOG_LEVEL_INFO, @"====[UIManual]===Group finished call back...");
            if ([_testMode isEqualToString:@"normal"]) {
                [NSThread sleepForTimeInterval:delay];
                
                [self generatAndStart:context];
            }
            
            
        }
    }];
    
//    [context registerForEvent:CTEventTypeGroupStart callback:^(CTEvent *event) {
//        @autoreleasepool {
//
//            NSString *identifier = event.userInfo[CTEventGroupIdentifierKey];
//
//            if ([self containIdentifier:identifier]) {
//                [self removeIdentifier:identifier];
//                [context groupDisappeared:identifier];
//
//            }
//
//        }
//    }];
    
//    [context registerForEvent:CTEventTypeUnitFinished callback:^(CTEvent *event){
//        if (_isFirstTest) {
//            CTUnit *unit=event.getUnit;
//            [context unitDisappeared:unit];
//            _isFirstTest=NO;
//        }
//    }];
    
    /*
    //first start will call this function
    int64_t delayIntervalNano = 3.0 * (double)NSEC_PER_SEC;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayIntervalNano), dispatch_get_main_queue(), ^{
        [self generatAndStart:context];
    });
    */

    return YES;
}

-(void)generatAndStart:(CTContext *)context{
    if (_showStartDialgFlag) {
        [self showStartDialogForm:context];
    }
    [self popupScanForm:context];
    [NSThread sleepForTimeInterval:0.05];
    
    
    [self setupGeneratorFunc];
}

- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    return YES;
}

- (CTCommandCollection *)commmandDescriptors
{
    // Collection contains descriptions of all the commands exposed by a plugin
    CTCommandCollection *collection = [CTCommandCollection new];
    // A command exposes its name, the selector to call, and a short description
    // Selector should take in one object of CTTestContext type
    CTCommandDescriptor *command = [[CTCommandDescriptor alloc] initWithName:@"getSNs" selector:@selector(getSNs:) description:@"Get SNs message from scan sn form"];

    [collection addCommand:command];
    
    return collection;
}
-(void)popupScanForm:(CTContext *)context{
    NSString *cmd=@"show-form";
    NSMutableArray *layout=[NSMutableArray new];
    for (int i=1; i<_numberOfUnits+1; i++) {
        NSString *text=[NSString stringWithFormat:@"Unit-%d",i];
        NSDictionary *label=@{@"type":@"label",@"text":text};
        NSDictionary *type=@{@"type":@"field",@"id":text};
        [layout addObject:label];
        [layout addObject:type];
        
    }
    NSDictionary *params=@{@"type" : @"custom", @"layout" : layout};
    NSError *failureInfo;
    _snDic=[context callAppWithCommand:cmd parameters:params error:&failureInfo];
    CTLog(CTLOG_LEVEL_INFO, @"===[UIManual]===scan sn snDic:%@",_snDic);
}
-(void)showStartDialogForm:(CTContext *)context{
    NSString *cmd=@"show-form";
    NSDictionary *params=@{@"type" : @"message", @"message" : @"Start"};
    NSError *failureInfo;
    [context callAppWithCommand:cmd parameters:params error:&failureInfo];
    CTLog(CTLOG_LEVEL_INFO, @"====[UIManual]===show start form dialog");
}
-(void)getSNs:(CTTestContext *)context
{
    if(context.parameters[@"mode"] != nil){
        _testMode=context.parameters[@"mode"];
        CTLog(CTLOG_LEVEL_INFO, @"====[UIManual]===receive test mode:%@",_testMode);
    }
    if (_isFirstTest) {
        [self popupScanForm:context];
        _isFirstTest=NO;
    }
    CTRecordStatus status=CTRecordStatusPass;
    if (_snDic == nil) {
        status=CTRecordStatusFail;
    }
    context.output=_snDic;
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSError *err = nil;
        NSError *failureInfoError = [NSError errorWithDomain:@"getSNsError" code:1 userInfo:@{NSLocalizedDescriptionKey : @"fail to get SN message from scan form"}];
        CTRecord *record = [[CTRecord alloc]initPassFailRecordWithNames:@[@"getSNs"]
                                                                 status:status
                                                            failureInfo:failureInfoError
                                                               priority:CTRecordPriorityRequired
                                                              startTime:[NSDate date]
                                                                endTime:[NSDate date]
                                                                  error:&err];
        
        
        [context.records addRecord:record error:&err];
        
        return CTRecordStatusPass;
    }];
    
}

# pragma gerenator group
- (NSArray *) createUnits:(int)numUnits withSuffix:(NSString *)suffix
{
    NSMutableArray *units = [NSMutableArray new];
    
    // Creates Requested Number of Units.
    for (int unitItr = 1; unitItr < numUnits+1; unitItr += 1) {
        NSUUID *uuid = [NSUUID new];
        NSString *unitName = [NSString stringWithFormat:@"Unit-%d", unitItr];
        
//        if (suffix)
//        {
//            unitName = [NSString stringWithFormat:@"%@ %@", unitName, suffix];
//        }
        
        

        CTUnit *unit = [[CTUnit alloc] initWithIdentifier:unitName
                                                     uuid:uuid
                                              environment:CTUnitEnvironment_custom
                                           unitTransports:nil
                                      componentTransports:nil
                                                 userInfo:nil];
        unit.userInfo[@"slot"] = @(unitItr);
        NSString *ipStr=[NSString stringWithFormat:@"169.254.1.%d",31+unitItr];
        unit.userInfo[@"ip"]=ipStr;
        
        [units addObject:unit];
    }
    
    return units;
}
-(void)setupGeneratorFunc{
    @autoreleasepool
    {
        //NSMutableArray *groups = [NSMutableArray new];
        for (int groupItr = 1; groupItr < self.numberOfGroups+1; groupItr++)
        {
            NSString *unitSuffix = [NSString stringWithFormat:@"(%@)", self.instanceID];
            NSString *groupID = [NSString stringWithFormat:@"Group-%d", groupItr];
            NSArray *units = [self createUnits:self.numberOfUnits withSuffix:unitSuffix];
            [_myContext groupAppeared:groupID units:units];
            //[groups addObject:groupID];
        }
        //[self addIdentifiers:groups];
        CTLog(CTLOG_LEVEL_INFO, @"====[UIManual]======finish setupGeneratorFunc");
    }
    
}
-(void)setupDisappearFunc{
    @autoreleasepool {
        for (NSString *identifier in self.ownedIdentifiers) {
            [self removeIdentifier:identifier];
            
            [_myContext groupDisappeared:identifier];
        }
    }
    
}
- (void) addIdentifiers:(NSArray *)identifierList
{
    @synchronized (self.ownedIdentifiers) {
        [self.ownedIdentifiers addObjectsFromArray:identifierList];
    }
}
- (void) removeIdentifier:(NSString *)identifier
{
    @synchronized (self.ownedIdentifiers) {
        [self.ownedIdentifiers removeObject:identifier];
    }
}

- (BOOL) containIdentifier:(NSString *)identifier
{
    @synchronized (self.ownedIdentifiers) {
        return [self.ownedIdentifiers containsObject:identifier];
    }
}
@end
