#import "OCSlimProjectFitnesseTestsMain.h"
#import "OCSPTestReportReader.h"
#import "OCSPTestSuite.h"
#import "OCSPJUnitXMLParser.h"
#import "OCSPLocalizedMessageTable.h"

@interface OCSlimProjectFitnesseTestsMain ()

@property (nonatomic, strong) NSString *bundleTestSuiteName;

@end

@implementation OCSlimProjectFitnesseTestsMain

- (id)init {
    
    if (self == [super init]) {
        
        [[XCTestObservationCenter sharedTestObservationCenter] addTestObserver:self];
       
    }
    
    return self;
}

#pragma mark - XCTestObservation

- (void)testBundleWillStart:(NSBundle *)testBundle {
    
    [self registerHostTestBundle:testBundle];
    
}

- (void)testSuiteWillStart:(XCTestSuite *)testSuite {
    
    if ( [self isHostTestSuite:testSuite] ) {
    
        XCTestSuite *acceptanceTestSuite = [OCSlimProjectFitnesseTestsMain testSuite];
        
        [self applyDisappearingTestCaseFix:acceptanceTestSuite];
    
        [testSuite addTest:acceptanceTestSuite];
        
    }
    
}

- (void)applyDisappearingTestCaseFix:(XCTestSuite*)suite {
    
    
    if (!self.disableFixForXcodeDisappearingTestCaseByAppendingDummyTest) {
        
        NSString *testCaseName = [suite.name stringByAppendingString:@".TearDown"];
        
        OCSPTestSuite *test = [[OCSPTestSuite alloc] initWithTestCaseName:testCaseName result:YES];
        
        [suite addTest:test];
        
    }
    
    
}
- (void)testBundleDidFinish:(NSBundle *)testBundle {
    
    [[XCTestObservationCenter sharedTestObservationCenter] removeTestObserver:self];
    
}

#pragma mark - Don't Peek!

- (void)registerHostTestBundle:(NSBundle *)bundle {
    
    self.bundleTestSuiteName = [[bundle bundleURL] lastPathComponent];

}

- (BOOL)isHostTestSuite:(XCTestSuite *)suite {
    
    return [[suite name] isEqualToString:self.bundleTestSuiteName];
}

+ (XCTestSuite *)testSuite {
    
    
    OCSPJUnitXMLParser *parser = [self testReportParser];
    
    NSString *testSuiteName = [parser testSuiteName];
    
    XCTestSuite *acceptanceTestSuite = [XCTestSuite testSuiteWithName:testSuiteName];
    
    
    for (int i = 0; i < [parser testCaseCount]; i++ ) {
    
        NSString *testCaseName = [parser testNameForTestCaseAtIndex:i];
        
        BOOL result = [parser testResultForTestCaseAtIndex:i];
        
        OCSPTestSuite *testCase = [[OCSPTestSuite alloc] initWithTestCaseName:testCaseName result:result];
        
        NSString *testPageErrorMessage = [parser testErrorMessageForTestCaseAtIndex:i];
        
        NSString *message = [OCSPLocalizedMessageTable localizedTestPageMessageWithUnderlyingMessage:testPageErrorMessage];
        
        [testCase setErrorMessage:message];
        
        [acceptanceTestSuite addTest:testCase];
        
    }
    
    
    [self addExceptionParseReportTestCases:parser testSuite:acceptanceTestSuite];
    
    return acceptanceTestSuite;

}

+ (void)addExceptionParseReportTestCases:(OCSPJUnitXMLParser *)parser testSuite:(XCTestSuite *) suite {
    
    OCSPTestSuite *reportingTestCase = nil;
    
    NSString *message = nil;
    
    if ( parser.parseErrorOccured == YES ) {
        
        reportingTestCase = [[OCSPTestSuite alloc] initWithTestCaseName:@"TestSuiteReportXMLParsingSucceeded" result:NO];
        
        message = [OCSPLocalizedMessageTable localizedTestSuiteParsingErrorMessage];
        
    } else if ( parser.parsingSucceeded == NO) {
      
        reportingTestCase = [[OCSPTestSuite alloc] initWithTestCaseName:@"TestSuiteReportDataExists" result:NO];
        
        message = [OCSPLocalizedMessageTable localizedTestSuiteReportDataNotFound];
        
    } else if ( parser.parsingSucceeded == YES && [parser testCaseCount] == 0 && [parser testSuiteErrorCount] == 0) {
        
        NSString *testCaseName = [NSString stringWithFormat:@"%@TestCaseCountGreaterThanZero", [parser testSuiteName]];
        
        reportingTestCase = [[OCSPTestSuite alloc] initWithTestCaseName:testCaseName result:NO];
        
        message = [OCSPLocalizedMessageTable localizedEmptyTestSuiteMessageWithSuiteName:[parser testSuiteName]];
        
    } else if ( parser.parsingSucceeded == YES && [parser testSuiteErrorCount] ) {
        
        NSString *testCaseName = [NSString stringWithFormat:@"%@ErrorCountEqualsZero", [parser testSuiteName]];
        
        reportingTestCase = [[OCSPTestSuite alloc] initWithTestCaseName:testCaseName result:NO];
        
        message = [OCSPLocalizedMessageTable localizedTestSuiteErrorsOccurredMessageWithCount:parser.testSuiteErrorCount];
        
    }
    
    [reportingTestCase setErrorMessage:message];
    
    [suite addTest:reportingTestCase];
    
}

+ (OCSPJUnitXMLParser *)testReportParser {
    
    NSData *data = [[OCSPTestReportCenter defaultReader] read];
    
    OCSPJUnitXMLParser *parser = [[OCSPJUnitXMLParser alloc] initWithXMLData:data];
    
    [parser parse];
    
    return parser;
}

@end

