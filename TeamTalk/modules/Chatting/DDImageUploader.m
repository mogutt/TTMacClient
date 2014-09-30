//
//  DDImageUploader.m
//  Duoduo
//
//  Created by 独嘉 on 14-3-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDImageUploader.h"
#import "AFHTTPClient.h"
#import "AIImageAdditions.h"
#import "AFHTTPRequestOperation.h"
#import "NSImage+Addition.h"

static int max_try_upload_times = 5;

@implementation DDImageUploader
{
}
+ (instancetype)instance
{
    static DDImageUploader* g_imageUploader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_imageUploader = [[DDImageUploader alloc] init];
    });
    max_try_upload_times = 5;
    return g_imageUploader;
}

- (void)uploadImage:(NSImage*)image success:(void(^)(NSString* imageURL))success failure:(void(^)(id error))failure
{
    NSURL *url = [NSURL URLWithString:@"http://122.225.68.125:8600/"];
    int width = image.size.width;
    int height = image.size.height;
    NSString* imageName = [NSString stringWithFormat:@"image.png_%dx%d.png",width,height];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
//    NSData *imageData = [image bestRepresentationByType];
    NSData *imageData = [image imageDataCompressionFactor:1.0];
    NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:@"im_image",@"type", nil];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"" parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:imageData name:@"image" fileName:imageName mimeType:@"image/jpeg"];
    }];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        int code = [response[@"error_code"] intValue];
        if (code == 0)
        {
            NSString* imageURL = response[@"path"];
            if (imageURL)
            {
                NSString* realImageURL = [NSString stringWithFormat:@"%@%@%@",IMAGE_MARK_START,imageURL,IMAGE_MARK_END];
                success(realImageURL);
            }
            else
            {
                max_try_upload_times --;
                if (max_try_upload_times > 0)
                {
                    [self uploadImage:image success:^(NSString *imageURL) {
                        success(imageURL);
                    } failure:^(id error) {
                        failure(error);
                    }];
                }
                else
                {
                    failure(nil);
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        max_try_upload_times --;
        if (max_try_upload_times > 0)
        {
            [self uploadImage:image success:^(NSString *imageURL) {
                success(imageURL);
            } failure:^(id error) {
                failure(error);
            }];
        }
        else
        {
            failure(nil);
        }

    }];
    [operation start];
}

+ (NSString *)imageUrl:(NSString *)content{
    //NSRange *range = [*content rangeOfString:@"path="];
    NSRange range = [content rangeOfString:@"path="];
    NSString* url = nil;
    //    url = [content substringFromIndex:range.location+range.length];
    
    if ([content length] > range.location + range.length)
    {
        url = [content substringFromIndex:range.location+range.length];
    }
    url = [(NSString *)url stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    url = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return url;
}

@end
