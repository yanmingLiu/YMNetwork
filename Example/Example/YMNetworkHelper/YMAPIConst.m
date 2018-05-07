//
//  YMAPIConst.m
//  youkexueC
//
//  Created by lym on 2017/7/19.
//  Copyright © 2017年 liuyanming. All rights reserved.
//

#import "YMAPIConst.h"

@implementation YMAPIConst

#if ProductSever

NSString *const kApiPrefix = @"";

#elif DevelopSever

NSString *const kApiPrefix = @"";


#elif TestSever

NSString * const kApiPrefix = @"http://10.10.10.10:9999/";

#endif




#pragma mark - 公共接口地址

/** 注册 */ 
NSString * const url_register = @"agency/reg";

/** 登录 */ 
NSString * const url_login= @"auth/agency/oauth/token?";


#pragma mark - 业务接口地址

//关键词
NSString * const url_home_keywords = @"custom/keywords";

@end
