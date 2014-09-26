//
//  NSAttributedString+Message.m
//  Duoduo
//
//  Created by 独嘉 on 14-3-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "NSAttributedString+Message.h"
#import "NSImage+Scale.h"
#import "DDChangableAttactment.h"
NSString* const realURLKey = @"RealURLKey";
@implementation NSAttributedString (Message)
+ (NSAttributedString *)imageAttributedString:(NSString *)imagePath realImageURL:(NSString*)realURL compressImage:(BOOL)compress
{
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
    NSImage *scaleImage;
    if (image.size.width > 400 && compress)
    {
        scaleImage = [image scaleImageToWidth:400];
    }
    else
    {
        scaleImage = image;
    }
    // 用NSFileWrapper是为了显示动态的表情
    // 但setIcon对大于聊天窗口的图片显示有问题
    // 所以对于有缩放的图片，先用NSTextAttachmentCell代替
    // 以后看看是不是有其他解决方案
    DDChangableAttactment *attachment = [[DDChangableAttactment alloc] initWithRealURL:realURL];
    
    NSURL *fileUrl = [NSURL fileURLWithPath:imagePath];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initSymbolicLinkWithDestinationURL:fileUrl];
    [fileWrapper setIcon:scaleImage];
    [fileWrapper setPreferredFilename:imagePath];
    
    [attachment setFileWrapper:fileWrapper];
    
    if (scaleImage != image) {
        NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:scaleImage];
        [attachment setAttachmentCell:attachmentCell];
    }
    
    NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
    
    return attributedString;
}

+ (NSAttributedString *)textAttributedString:(NSString *)text
{
    NSMutableAttributedString *textContent = [[NSMutableAttributedString alloc]
                                              initWithString:text
                                              attributes:nil];
    
    // add http link highlight
    NSDataDetector* dataDetector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:nil];
    NSArray *matches = [dataDetector matchesInString:text
                                             options:0
                                               range:NSMakeRange(0, [text length])];
    
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        if ([match resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [match URL];
            [textContent addAttributes:@{NSLinkAttributeName:url.absoluteString}
                                 range:matchRange];
        }
    }
    return textContent;
}

- (NSAttributedString *)replactTheAttactementAtIndex:(NSUInteger)index withAttachementImagePath:(NSString*)attachementPath
{
    NSMutableAttributedString* resultAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self];
    NSUInteger currentIndex = -1;
    for (NSUInteger i=0; i<self.length; i++)
    {
        DDChangableAttactment *currentAttachment = [self attribute:NSAttachmentAttributeName atIndex:i effectiveRange:NULL];
        if ([currentAttachment isKindOfClass:NSClassFromString(@"DDChangableAttactment")])
        {
            currentIndex ++;
            if (currentIndex == index)
            {
                NSAttributedString* newAttribute = [NSAttributedString imageAttributedString:attachementPath realImageURL:nil compressImage:YES];
                [resultAttributedString replaceCharactersInRange:NSMakeRange(i, 1) withAttributedString:newAttribute];
                break;
            }
        }
    }
    return resultAttributedString;
}

+ (NSAttributedString*)imageAttributeString:(NSString*)imagePath compressImage:(BOOL)compress
{
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
    NSImage *scaleImage;
    if (image.size.width > 400 && compress)
    {
        scaleImage = [image scaleImageToWidth:400];
    }
    else
    {
        scaleImage = image;
    }
    // 用NSFileWrapper是为了显示动态的表情
    // 但setIcon对大于聊天窗口的图片显示有问题
    // 所以对于有缩放的图片，先用NSTextAttachmentCell代替
    // 以后看看是不是有其他解决方案
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    
    NSURL *fileUrl = [NSURL fileURLWithPath:imagePath];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initSymbolicLinkWithDestinationURL:fileUrl];
    [fileWrapper setIcon:scaleImage];
    [fileWrapper setPreferredFilename:imagePath];
    
    [attachment setFileWrapper:fileWrapper];
    
    if (scaleImage != image) {
        NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:scaleImage];
        [attachment setAttachmentCell:attachmentCell];
    }
    
    NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
    
    return attributedString;
}
@end
