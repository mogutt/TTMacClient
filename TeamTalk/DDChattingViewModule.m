//
//  DDChattingViewModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-3-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDChattingViewModule.h"
#import "SessionEntity.h"
#import "DDEmotionAttachment.h"
#import "AIImageAdditions.h"
#import "EGOCache.h"
#import "NSAttributedString+Message.h"
#import "MessageEntity.h"
#import "EmotionManager.h"
#import "EGOImageLoader.h"
#import "NSImage+Addition.h"

@interface DDChattingViewModule(privateAPI)

- (void)fetchGroupUsers;
- (NSAttributedString*)getTextAndEmotionAttributeFromText:(NSString*)text;

@end

@implementation DDChattingViewModule
{

}
- (id)initWithSession:(SessionEntity*)session
{
    self = [super init];
    if (self)
    {
        _session = [session copy];
        //获取组内成员
        
    }
    return self;
}


- (NSAttributedString*)getAttributedStringFromInputContent:(NSAttributedString*)inputContent compress:(BOOL)compress
{
    NSMutableAttributedString* resultAttributedString = [[NSMutableAttributedString alloc] init];
    
    if (inputContent.length) {
        NSUInteger lastTextIndex = 0;
        NSUInteger i = 0;
        for (i=0; i<inputContent.length; i++) {
            NSTextAttachment *attachment = [inputContent attribute:NSAttachmentAttributeName atIndex:i effectiveRange:NULL];
            
            if (attachment)
            {
                
                if (lastTextIndex != i)
                {
                    NSString *msgData = [[inputContent attributedSubstringFromRange:NSMakeRange(lastTextIndex, i - lastTextIndex)] string];
                    NSAttributedString* tempAttribute = [NSAttributedString textAttributedString:msgData];
                    [resultAttributedString appendAttributedString:tempAttribute];
                }
                lastTextIndex = i + 1;
                
                if ([attachment isKindOfClass:[DDEmotionAttachment class]])
                {
                    NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
                    [resultAttributedString appendAttributedString:attributedString];
                }else
                {
                    NSImage *image = nil;
                    if ([attachment respondsToSelector:@selector(image)])
                        image = [attachment performSelector:@selector(image)];
                    else if ([[attachment attachmentCell] respondsToSelector:@selector(image)])
                        image = [[attachment attachmentCell] performSelector:@selector(image)];
                    
                    NSString *imageKey =[NSString stringWithFormat:@"tem-%lu", [[image description] hash]];
                    NSString *fileName=[[[EGOCache currentCache] pathForKey:imageKey]  stringByAppendingPathExtension:@"png"];
                    
                    [image saveImageToFile:fileName compressionFactor:1.0];
                    
                    NSAttributedString* imageAttribute = [NSAttributedString imageAttributedString:fileName realImageURL:nil compressImage:compress];
                    [resultAttributedString appendAttributedString:imageAttribute];
                }
            }
        }
        
        if (lastTextIndex != i)
        {
            NSString *msgData = [[inputContent attributedSubstringFromRange:
                                  NSMakeRange(lastTextIndex, i - lastTextIndex)] string];
            NSAttributedString* textAttributedString = [NSAttributedString textAttributedString:msgData];
            [resultAttributedString appendAttributedString:textAttributedString];
        }
    }
    return resultAttributedString;
}

- (NSAttributedString*)getAttributedStringFromShowMessage:(MessageEntity*)message
{
    NSMutableAttributedString* messageShowAttributed = [[NSMutableAttributedString alloc] init];
    
    NSMutableString *msgContent = [NSMutableString stringWithString:message.msgContent];
    NSRange startRange;
    while ((startRange= [msgContent rangeOfString:IMAGE_MARK_START]).location!=NSNotFound) {
        if (startRange.location>0) {
            NSString *str = [msgContent substringWithRange:NSMakeRange(0, startRange.location)];
            [msgContent deleteCharactersInRange:NSMakeRange(0, startRange.location)];
            startRange.location=0;
            NSAttributedString* textAndEmotionAttribute = [self getTextAndEmotionAttributeFromText:str];
            [messageShowAttributed appendAttributedString:textAndEmotionAttribute];
        }
        
        NSRange endRange = [msgContent rangeOfString:IMAGE_MARK_END];
        if (endRange.location !=NSNotFound) {
            NSRange range;
            range.location = startRange.location+startRange.length;
            range.length = endRange.location-startRange.length-startRange.location;
            NSString *url = [msgContent substringWithRange:range];
            if ([url rangeOfString:@"http://"].length == 0)
            {
                url = [NSString stringWithFormat:@"http://122.225.68.125:8600/%@",url];
            }
//            NSImage* image = [[EGOImageLoader sharedImageLoader] imageForURL:[NSURL URLWithString:url]
//                                                      shouldLoadWithObserver:nil];
            DDLog(@"图片url:%@",url);
            [msgContent deleteCharactersInRange:NSMakeRange(startRange.location,(startRange.length+range.length+endRange.length) )];
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"tab_bg" ofType:@"png"];
            NSAttributedString* imageAttribute = [NSAttributedString imageAttributedString:path realImageURL:url compressImage:YES];

            [messageShowAttributed appendAttributedString:imageAttribute];
            
        } else {
            DDLog(@"没有匹配后缀:%@",msgContent);
            break;
        }
    }
    
    // add remain text content
    if([msgContent length] > 0){
        DDLog(@"文本.");
        NSAttributedString* emotionTextAttribute = [self getTextAndEmotionAttributeFromText:msgContent];
        [messageShowAttributed appendAttributedString:emotionTextAttribute];
    }
    return messageShowAttributed;
}

#pragma mark - PrivateAPI
- (NSAttributedString*)getTextAndEmotionAttributeFromText:(NSString*)text
{
    NSMutableAttributedString* resultAttribute = [[NSMutableAttributedString alloc] init];
    NSMutableString *msgContent = [NSMutableString stringWithString:text];
    NSRange startRange;
    while ((startRange = [msgContent rangeOfString:@"["]).location != NSNotFound) {
        if (startRange.location > 0)
        {
            NSString *str = [msgContent substringWithRange:NSMakeRange(0, startRange.location)];
            DDLog(@"[前文本内容:%@",str);
            [msgContent deleteCharactersInRange:NSMakeRange(0, startRange.location)];
            startRange.location=0;
            NSAttributedString* textAttribute = [NSAttributedString textAttributedString:str];
            [resultAttribute appendAttributedString:textAttribute];
        }
        
        NSRange endRange = [msgContent rangeOfString:@"]"];
        if (endRange.location != NSNotFound) {
            NSRange range;
            range.location = 0;
            range.length = endRange.location + endRange.length;
            NSString *emotionText = [msgContent substringWithRange:range];
            [msgContent deleteCharactersInRange:
             NSMakeRange(0, endRange.location + endRange.length)];
            
            DDLog(@"类似表情字串:%@",emotionText);
            NSString *emotionFile = [[EmotionManager instance] getFileFrom:emotionText];
            if (emotionFile) {
                // 表情
                NSString *path = [[NSBundle mainBundle] pathForResource:emotionFile ofType:nil];
                DDEmotionAttachment* emotionAttribute = [[DDEmotionAttachment alloc] init];
                NSURL *fileUrl = [NSURL fileURLWithPath:path];
                NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initSymbolicLinkWithDestinationURL:fileUrl];
                NSImage* emotionImage = [[NSImage alloc] initWithContentsOfURL:fileUrl];
                [fileWrapper setIcon:emotionImage];
                [fileWrapper setPreferredFilename:path];
                [emotionAttribute setFileWrapper:fileWrapper];
                [emotionAttribute setEmotionFileName:emotionFile];
                [emotionAttribute setEmotionPath:path];
                [emotionAttribute setEmotionText:emotionText];
                NSMutableAttributedString *attachmentString = (NSMutableAttributedString*)[NSMutableAttributedString attributedStringWithAttachment:emotionAttribute];

                [resultAttribute appendAttributedString:attachmentString];
            } else
            {
                NSAttributedString* textAttribute = [NSAttributedString textAttributedString:emotionText];
                [resultAttribute appendAttributedString:textAttribute];
            }
        } else {
            DDLog(@"没有[匹配的后缀");
            break;
        }
    }
    
    if ([msgContent length] > 0)
    {
        NSAttributedString* textAttribute = [NSAttributedString textAttributedString:msgContent];
        [resultAttribute appendAttributedString:textAttribute];
    }
    return resultAttribute;
}

- (void)fetchGroupUsers
{
    switch (_session.type)
    {
        case SESSIONTYPE_SINGLE:
            break;
        case SESSIONTYPE_GROUP:
        {
            [_session.groupUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString* userID = (NSString*)obj;
            }];
        }
            break;
    }
}

@end
