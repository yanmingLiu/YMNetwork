//
//  YMNetwork.m
//  RACDemo
//
//  Created by lym on 2017/7/17.
//
//

#import "YMNetwork.h"


#define NSStringFormat(format,...) [NSString stringWithFormat:format,##__VA_ARGS__]

@implementation YMNetwork


static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_manager;
static BOOL _isOpenLog = YES;   // 是否已开启日志打印

#pragma mark - 开始监听网络

+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

+ (void)openLog {
    _isOpenLog = YES;
}

+ (void)closeLog {
    _isOpenLog = NO;
}

+ (void)cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) { return; }
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

/**
 *  json转字符串
 */
+ (NSString *)jsonToString:(id)data {
    if(data == nil) { return nil; }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 存储着所有的请求task数组
 */
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

#pragma mark - 网络请求

/**
 无缓存
 */
+ (NSURLSessionTask *)requestMethod:(YMNetworkMethod)method url:(NSString *)urlStr params:(id)params success:(YMRequestSuccess)success failure:(YMRequestFailed)failure 
{
    return [self requestMethod:method url:urlStr params:params responseCache:nil success:success failure:failure];
}

/**
 *  请求,自动缓存
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)requestMethod:(YMNetworkMethod)method url:(NSString *)urlStr params:(id)params responseCache:(YMRequestCache)responseCache success:(YMRequestSuccess)success failure:(YMRequestFailed)failure 
{
    //读取缓存
    if (responseCache) {
        id cacheResponse = [YMNetworkCache httpCacheForURL:urlStr parameters:params];
        if (cacheResponse) {
            responseCache(cacheResponse);
        } 
        if (_isOpenLog) {NSLog(@"\n缓存--- %@ \n",[self jsonToString:cacheResponse]);}
    }
    if (_isOpenLog) {
        NSLog(@"\n请求地址: %@ \n请求头:%@ \n请求参数:%@ \n", urlStr,_manager.requestSerializer.HTTPRequestHeaders, params);
    }
    
    urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    // 请求成功回调
    void(^responseSuccess)(NSURLSessionDataTask * task, id responseObject) = ^(NSURLSessionDataTask * task, id responseObject) {
        
        if (_isOpenLog) {NSLog(@"\n responseObject = %@ \n",[self jsonToString:responseObject]);}
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        //对数据进行异步缓存
        responseCache!=nil ? [YMNetworkCache setHttpCache:responseObject URL:urlStr parameters:params] : nil;
        
    };
    // 请求失败回调
    void(^responseFailure)(NSURLSessionDataTask * task, id responseObject) = ^(NSURLSessionDataTask * task, NSError * error) {
        
        if (_isOpenLog)  NSLog(@"%@", error); 
        
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    };
    
    switch (method) {
        case YMNetworkMethodGET:
        {
            NSURLSessionTask *sessionTask = [_manager GET:urlStr parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                responseSuccess(task, responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                responseFailure(task, error);
            }];
            // 添加sessionTask到数组
            sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
            return sessionTask;
        }
        case YMNetworkMethodPOST:
        {
            NSURLSessionTask *sessionTask = [_manager POST:urlStr parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                responseSuccess(task, responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                responseFailure(task, error);
            }];
            sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
            return sessionTask;
        }
        case YMNetworkMethodHEAD:
        {
            NSURLSessionTask *sessionTask = [_manager HEAD:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task) {
                responseSuccess(task, nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                responseFailure(task, error);
            }];
            sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
            return sessionTask;
        }
        case YMNetworkMethodPUT:
        {
            NSURLSessionTask *sessionTask = [_manager PUT:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                responseSuccess(task, responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                responseFailure(task, error);
            }];
            sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
            return sessionTask;
        }
        case YMNetworkMethodDELETE:
        {
            NSURLSessionTask *sessionTask = [_manager DELETE:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                responseSuccess(task, responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                responseFailure(task, error);
            }];
            sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
            return sessionTask;
        }
        case YMNetworkMethodPATCH:
        {
            NSURLSessionTask *sessionTask = [_manager PATCH:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                responseSuccess(task, responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                responseFailure(task, error);
            }];
            sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
            return sessionTask;
        }
    }
    return [[NSURLSessionTask alloc] init];
}


#pragma mark - 上传多张图片
+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                               parameters:(id)parameters
                                     name:(NSString *)name
                                   images:(NSArray<UIImage *> *)images
                                fileNames:(NSArray<NSString *> *)fileNames
                               imageScale:(CGFloat)imageScale
                                imageType:(NSString *)imageType
                                 progress:(YMRequestProgress)progress
                                  success:(YMRequestSuccess)success
                                  failure:(YMRequestFailed)failure {
    NSURLSessionTask *sessionTask = [_manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 默认图片的文件名, 若fileNames为nil就使用
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = NSStringFormat(@"%@%ld.%@",str,i,imageType?:@"jpg");
            
            [formData appendPartWithFileData:imageData
                                        name:name
                                    fileName:fileNames ? NSStringFormat(@"%@.%@",fileNames[i],imageType?:@"jpg") : imageFileName
                                    mimeType:NSStringFormat(@"image/%@",imageType ?: @"jpg")];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) {NSLog(@"responseObject = %@",[self jsonToString:responseObject]);}
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog)  NSLog(@"%@", error); 
        
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];
    
    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    
    return sessionTask;
}

#pragma mark - 下载文件
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(YMRequestProgress)progress
                              success:(void(^)(NSString *))success
                              failure:(YMRequestFailed)failure {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    __block NSURLSessionDownloadTask *downloadTask = [_manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //下载进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self allSessionTask] removeObject:downloadTask];
        if(failure && error) {failure(error) ; return ;};
        success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
        
    }];
    //开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil ;
    
    return downloadTask;
}


#pragma mark - 初始化AFHTTPSessionManager相关属性

/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager
 *  原理参考地址:http://www.jianshu.com/p/5969bbb4af9f
 */
+ (void)initialize {
    
    _manager = [AFHTTPSessionManager manager];
    _manager.requestSerializer.timeoutInterval = 30.f;
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    
//    [_manager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
//    [_manager.requestSerializer setValue:@"text/html;charset=UTF-8,application/json" forHTTPHeaderField:@"Accept"];
//    [_manager.requestSerializer setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    
    // 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
}

+ (void)setRequestSerializer:(YMRequestSerializer)requestSerializer {
    _manager.requestSerializer = requestSerializer==YMRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(YMResponseSerializer)responseSerializer {
    _manager.responseSerializer = responseSerializer==YMResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_manager.requestSerializer setValue:value forHTTPHeaderField:field];
}

+ (void)openNetworkActivityIndicator:(BOOL)open {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    
    [_manager setSecurityPolicy:securityPolicy];
}


@end

#pragma mark - NSDictionary,NSArray的分类
/*
 ************************************************************************************
 *新建NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (YMArray)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];
    
    return strM;
}

@end

@implementation NSDictionary (YMDictionary)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [strM appendString:@"}\n"];
    
    return strM;
}
@end
#endif



