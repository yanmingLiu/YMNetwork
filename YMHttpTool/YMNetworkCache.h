//
//  YMNetworkCache.h
//  RACDemo
//
//  Created by lym on 2017/7/18.
//
//

#import <Foundation/Foundation.h>

@interface YMNetworkCache : NSObject


// 过期提醒
#define CacheDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)


#pragma mark - 网络数据缓存类

/**
 *  异步缓存网络数据,根据请求的 URL与parameters
 *  做KEY存储数据, 这样就能缓存多级页面的数据
 *
 *  @param httpData   服务器返回的数据
 *  @param URL        请求的URL地址
 *  @param parameters 请求的参数
 */
+ (void)setHttpCache:(id)httpData URL:(NSString *)URL parameters:(NSDictionary *)parameters;

/**
 *  根据请求的 URL与parameters 同步取出缓存数据
 *
 *  @param URL        请求的URL
 *  @param parameters 请求的参数
 *
 *  @return 缓存的服务器数据
 */
+ (id)httpCacheForURL:(NSString *)URL parameters:(NSDictionary *)parameters;

/// 获取网络缓存的总大小 bytes(字节)
+ (NSInteger)getAllHttpCacheSize;


/// 删除所有网络缓存
+ (void)removeAllHttpCache;

@end