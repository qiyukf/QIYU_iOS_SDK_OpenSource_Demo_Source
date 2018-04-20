//
//  CrashReport.h
//  YSFDemo
//
//  Created by JackyYu on 16/8/4.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrashReport : NSObject

+ (void)startCrashReport;

+ (void)registerReportWithUserId:(NSString*)userId;

+ (void)testCrash;

@end
