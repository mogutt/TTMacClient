//
//  DDChattingContentView.m
//  Duoduo
//
//  Created by jianqing.du on 14-1-13.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDChattingContentView.h"
#import "NSImage+Stretchable.h"
#import "DDUserlistModule.h"
#import "UserEntity.h"
#import "DDMessageModule.h"
#import <Quartz/Quartz.h>

#define MAX_IMAGE_SIZE      300
#define SHOW_TIME_INTERVAL  120     // 2 minutes


@implementation DDChattingContentView {
    BOOL isGroup;                   // group chat need to display sender name
    NSBezierPath *selectImagePath;  // to draw a blue box around clicked image
    NSRect selectImageRect;
    NSDictionary *leftMsgAttrDict;     // message display attribute
    NSDictionary *rightMsgAttrDict;
    NSDictionary *nameAttrDict;
    NSDictionary *timeAttrDict;
    
    NSString *lineSeparatorStr;
    NSString *paragraphSeperatorStr;
    NSDataDetector *dataDetector;   // for http link highlight
    
    NSDate *lastMsgDate;
    NSString *lastUserId;
    DDUserlistModule *userList;
    
    NSUInteger historyMsgInsertPosition;
    NSDate *historyLastMsgDate;
    NSString *historyLastUserId;
    
    uint32_t totalMsgCnt;
    DDMessageModule *msgModule;
    SessionEntity *sessonEntity;
    BOOL canSendHistoryRequest;
    NSString *myUserId;
    
    NSMutableAttributedString *msgContentString;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
    [[NSColor blueColor] set];
    [selectImagePath removeAllPoints];
    [selectImagePath appendBezierPathWithRect:selectImageRect];
    [selectImagePath stroke];
}

// put initialization code here
- (void)awakeFromNib
{
    isGroup = NO;
    [self setTextContainerInset:NSMakeSize(20, 20)];
    [self setDelegate:self];
    
    selectImagePath = [NSBezierPath bezierPath];
    [selectImagePath setLineWidth:1.5];
    
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:13];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setParagraphSpacing:25];
    [paragraphStyle setParagraphSpacingBefore:10];
    leftMsgAttrDict = @{NSFontAttributeName:font,
                        NSParagraphStyleAttributeName:paragraphStyle};
    
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSRightTextAlignment];
    [paragraphStyle setParagraphSpacing:25];
    [paragraphStyle setParagraphSpacingBefore:10];
    rightMsgAttrDict = @{NSFontAttributeName:font,
                         NSParagraphStyleAttributeName:paragraphStyle};
    
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setParagraphSpacing:10];
    [paragraphStyle setParagraphSpacingBefore:10];
    nameAttrDict = @{NSParagraphStyleAttributeName:paragraphStyle};
    
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    [paragraphStyle setParagraphSpacing:10];
    [paragraphStyle setParagraphSpacingBefore:10];
    timeAttrDict = @{NSParagraphStyleAttributeName:paragraphStyle};
    
    lineSeparatorStr = [NSString stringWithFormat:@"%C", (unichar)NSLineSeparatorCharacter];
    paragraphSeperatorStr = [NSString stringWithFormat:@"%C", (unichar)NSParagraphSeparatorCharacter];
    
    NSError *error = NULL;
    dataDetector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:&error];
    
    lastMsgDate = [NSDate dateWithTimeIntervalSince1970:0];
    userList = [DDUserlistModule shareInstance];
    
    totalMsgCnt = 0;
    
    [self resetHistoryMsgInsertInfo];
    
    msgModule = [DDMessageModule shareInstance];
    canSendHistoryRequest = YES;
    myUserId = userList.myUser.userId;
    
    msgContentString = [[NSMutableAttributedString alloc] init];
}

- (void)setGroupFlag:(BOOL)groupFlag
{
    isGroup = groupFlag;
}

- (void)setSessionEntity: (SessionEntity *)session
{
    sessonEntity = session;
}

- (void)addMsg:(NSString *)msgData
        ofType:(MsgType)msgType
      fromUser:(NSString *)fromUserId   // set fromUserId to nil for self
          date:(NSDate *)date
       atIndex:(NSUInteger *)indexPointer   // used to replace asyn image
         atEnd:(BOOL)atEnd
    isComplete:(BOOL)isComplete
{
    // filter wrong msg type
    if (msgType != MSG_TYPE_TEXT && msgType != MSG_TYPE_IMAGE) {
        DDLog(@"wrong msg type");
        return;
    }
    
    // filter empty text msg
    if ( (msgType == MSG_TYPE_TEXT)  && ([msgData length] == 0) ){
        DDLog(@"no msg content");
        return;
    }
    
    NSUInteger prevContentLen = [[self string] length];
    
    // add msg time
    BOOL needDisplayDate = NO;
    if (atEnd) {
        if ([date timeIntervalSinceDate:lastMsgDate] >= SHOW_TIME_INTERVAL) {
            lastMsgDate = date;
            needDisplayDate = YES;
        }
    } else {
        // add history message
        if ([date timeIntervalSinceDate:historyLastMsgDate] >= SHOW_TIME_INTERVAL) {
            historyLastMsgDate = date;
            needDisplayDate = YES;
        }
    }
    
    if (needDisplayDate) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"MM月dd日 HH:mm\n"];
        NSString *timestamp = [df stringFromDate:date];
        [self appendAttributeText:timestamp
                    withAttribute:timeAttrDict
                            isMsg:NO
                       isOutgoing:NO
                            atEnd:atEnd];
        DDLog(@"***add timestamp, %@", timestamp);
    }
    
    if ((fromUserId != nil) && ([fromUserId isEqualToString:myUserId])) {
        fromUserId = nil;
    }
    
    // add msg send name in group
    if (isGroup) {
        // self send message
        if (fromUserId == nil) {
            lastUserId = nil;
        } else {
            BOOL needDisplayName = NO;
            if (atEnd) {
                if (![fromUserId isEqualToString:lastUserId]) {
                    lastUserId = fromUserId;
                    needDisplayName = YES;
                }
            } else {
                if (![fromUserId isEqualToString:historyLastUserId]) {
                    historyLastUserId = fromUserId;
                    needDisplayName = YES;
                }
            }
            
            if (needDisplayName) {
                UserEntity *user = [userList getUserById:fromUserId];
                NSMutableString *name = [[NSMutableString alloc]
                                         initWithString:user.name];
                [name appendString:paragraphSeperatorStr];
                
                [self appendAttributeText:name
                            withAttribute:nameAttrDict
                                    isMsg:NO
                               isOutgoing:NO
                                    atEnd:atEnd];
                DDLog(@"***add name: %@", name);
            }
        }
    }
    
    BOOL isOutgoing = (fromUserId == nil) ? YES : NO;
    if (msgType == MSG_TYPE_TEXT) {
        // 处理Window过来的换行符
        NSMutableString *newMsgTmp = [[NSMutableString alloc] initWithString:
                            [msgData stringByReplacingOccurrencesOfString:@"\r\n"
                                                    withString: lineSeparatorStr]];
        
        NSMutableString *newMsg = [[NSMutableString alloc] initWithString:
                                [newMsgTmp stringByReplacingOccurrencesOfString:@"\n"
                                                        withString: lineSeparatorStr]];
        
        [self appendAttributeText:newMsg
                    withAttribute:(isOutgoing ? rightMsgAttrDict : leftMsgAttrDict)
                            isMsg:YES
                       isOutgoing:isOutgoing
                            atEnd:atEnd];
        
    } else {
        if (indexPointer) {
            if (atEnd) {
                DDLog(@"image index=%lu", [[self string] length]);
                *indexPointer = [[self string] length];
            } else {
                *indexPointer = historyMsgInsertPosition;
            }
        }
        [self appendAttributeImage:msgData isOutgoing:isOutgoing atEnd:atEnd];
    }
    
    if (isComplete) {
        ++totalMsgCnt;
        [self appendAttributeText:paragraphSeperatorStr
                withAttribute:(isOutgoing ? rightMsgAttrDict : leftMsgAttrDict)
                        isMsg:YES
                   isOutgoing:isOutgoing
                        atEnd:atEnd];
    }
    
    // only automatic scroll to bottom when the scroller is at bottom
    // or the user send a message
    dispatch_async(dispatch_get_main_queue(), ^{
        if (atEnd) {
            NSRange range = [self selectedRange];
            if ((prevContentLen <= range.location) || isOutgoing) {
                // scroll to the end of NSTextView
                NSUInteger totalLen = [[self string] length];
                [self scrollRangeToVisible:NSMakeRange(totalLen, 0)];
                DDLog(@"scroll to end");
            }
        } else {
            // history message, scroll to current position
            DDLog(@"scroll to %lu", historyMsgInsertPosition);
            [self scrollRangeToVisible:NSMakeRange(historyMsgInsertPosition, 0)];
        }
    });
}

- (void)replaceImage:(NSString *)imagePath atIndex:(NSUInteger)index fromUser:(NSString *)fromUserId
{
    BOOL isOutgoing = NO;
    if ((fromUserId == nil) || ([fromUserId isEqualToString:myUserId])) {
        isOutgoing = YES;
    }

    [self replaceAttributeImage:imagePath atIndex:index isOutgoing:isOutgoing];
}

- (void)resetHistoryMsgInsertInfo
{
    DDLog(@"resetHistoryMsgInsertInfo");
    
    NSUInteger len = [msgContentString length];
    if (len > 0) {
        [[self textStorage] appendAttributedString:msgContentString];
        [msgContentString deleteCharactersInRange:NSMakeRange(0, len)];
    }
    
    [self scrollRangeToVisible:NSMakeRange(historyMsgInsertPosition, 0)];
    historyMsgInsertPosition = 0;
    historyLastUserId = nil;
    historyLastMsgDate = [NSDate dateWithTimeIntervalSince1970:0];
    canSendHistoryRequest = YES;
}

- (void)drawBubbleAroundTextInRect:(NSRect)rect isOutgoing:(BOOL)isOutgoing
{
    //DDLog(@"draw in (%f, %f, %f, %f)", rect.origin.x, rect.origin.y,
    //      rect.size.width, rect.size.height);
    
    rect.size.height += 20;
    rect.size.width += 20;
    rect.origin.x=0;
    if (rect.origin.x > 10)
        rect.origin.x -= 10;
    if (rect.origin.y > 10)
        rect.origin.y -= 10;
    
    NSImage *image;
    if (isOutgoing) {
        image = [NSImage imageNamed:@"bubble_right"];
    } else {
        image = [NSImage imageNamed:@"bubble_left"];
    }
    
    NSImage *imageStrech = [image stretchableImageWithSize:rect.size
                                                edgeInsets:NSEdgeInsetsMake(10, 10, 10, 10)];

    [imageStrech drawInRect:rect
                   fromRect:NSZeroRect
                  operation:NSCompositeSourceOver
                   fraction:1.0
             respectFlipped:YES
                      hints:nil];
}

- (void)drawViewBackgroundInRect:(NSRect)rect
{
    NSLayoutManager *layoutManager = [self layoutManager];
    NSPoint containerOrigin = [self textContainerOrigin];
    NSRange glyphRange, charRange, paragraphCharRange,
    paragraphGlyphRange, lineGlyphRange;
    NSRect paragraphRect, lineUsedRect;
    
    // Draw the background first, before the bubbles.
    [super drawViewBackgroundInRect:rect];
    
    // Convert from view to container coordinates, then to the
    //corresponding glyph and character ranges.
    rect.origin.x -= containerOrigin.x;
    rect.origin.y -= containerOrigin.y;
    glyphRange = [layoutManager glyphRangeForBoundingRect:rect
                                          inTextContainer:[self textContainer]];
    charRange = [layoutManager characterRangeForGlyphRange:glyphRange
                                          actualGlyphRange:NULL];
    
    // Iterate through the character range, paragraph by paragraph.
    for (paragraphCharRange = NSMakeRange(charRange.location, 0);
         NSMaxRange(paragraphCharRange) < NSMaxRange(charRange);
         paragraphCharRange = NSMakeRange(NSMaxRange(paragraphCharRange), 0)) {
        // For each paragraph, find the corresponding character and glyph ranges.
        paragraphCharRange = [[[self textStorage] string]
                              paragraphRangeForRange:paragraphCharRange];
        paragraphGlyphRange = [layoutManager
                               glyphRangeForCharacterRange:paragraphCharRange
                               actualCharacterRange:NULL];
        paragraphRect = NSZeroRect;
        
        NSNumber *isMsg = [[self textStorage] attribute:@"isMsg"
                                                atIndex:paragraphCharRange.location
                                         effectiveRange:NULL];
        NSNumber *isOutgoing = [[self textStorage] attribute:@"isOutgoing"
													 atIndex:paragraphCharRange.location
											  effectiveRange:NULL];
        
        // Iterate through the paragraph glyph range, line by line.
        for (lineGlyphRange = NSMakeRange(paragraphGlyphRange.location,0);
             NSMaxRange(lineGlyphRange) < NSMaxRange(paragraphGlyphRange);
             lineGlyphRange = NSMakeRange(NSMaxRange(lineGlyphRange), 0)) {
            // For each line, find the used rect and glyph range, and
            // add the used rect to the paragraph rect.
            lineUsedRect = [layoutManager
                            lineFragmentUsedRectForGlyphAtIndex:lineGlyphRange.location
                            effectiveRange:&lineGlyphRange];
            paragraphRect = NSUnionRect(paragraphRect, lineUsedRect);
        }
        
        // Convert back from container to view coordinates, then draw the bubble.
        paragraphRect.origin.x += containerOrigin.x;
        paragraphRect.origin.y += containerOrigin.y;
        
        if ([isMsg boolValue]) {
            [self drawBubbleAroundTextInRect:paragraphRect
                                  isOutgoing:[isOutgoing boolValue]];
        }
    }
}

- (void)appendAttributeText:(NSString *)textStr
              withAttribute:(NSDictionary *)attribute
                      isMsg:(BOOL)isMsg
                 isOutgoing:(BOOL)isOutgoing
                      atEnd:(BOOL)atEnd;
{
    NSMutableAttributedString *textContent = [[NSMutableAttributedString alloc]
                                              initWithString:textStr
                                              attributes:attribute];
    
    // add user define attribute
    NSDictionary *dict = @{@"isMsg":[NSNumber numberWithBool:isMsg],
                           @"isOutgoing": [NSNumber numberWithBool:isOutgoing]};
    [textContent addAttributes:dict range:NSMakeRange(0, [textStr length])];
    
    // add http link highlight
    NSArray *matches = [dataDetector matchesInString:textStr
                                             options:0
                                            range:NSMakeRange(0, [textStr length])];
    
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        if ([match resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [match URL];
            [textContent addAttributes:@{NSLinkAttributeName:url.absoluteString}
                                 range:matchRange];
        }
    }
    
    // append to NSTextStorage
    [[self textStorage] beginEditing];
    if (atEnd) {
        [[self textStorage] appendAttributedString:textContent];
    } else {
        [[self textStorage] insertAttributedString:textContent
                                           atIndex:historyMsgInsertPosition];
         
        historyMsgInsertPosition += [textContent length];
        DDLog(@"historty msg insert pos=%lu", historyMsgInsertPosition);
    }
    [[self textStorage] endEditing];
}

- (NSImage *)scaleImage:(NSImage *)image
{
    NSRect viewRect = [self frame];
    NSSize imageSize = [image size];
    NSSize drawSize = imageSize;
    
    if (imageSize.width > viewRect.size.width - 60) {
        drawSize.width = viewRect.size.width - 60;
        // 高度按宽度的比例缩小，这样不会应压缩而失真
        drawSize.height *= (drawSize.width / imageSize.width);
    
        NSRect scaleRect = NSMakeRect(0, 0, drawSize.width, drawSize.height);
        NSImage *scaleImage = [[NSImage alloc] initWithSize:drawSize];
        [scaleImage lockFocus];
        [image drawInRect:scaleRect
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1.0];
        [scaleImage unlockFocus];
        
        return scaleImage;
    }
    
    return image;
}

- (NSMutableAttributedString *)imageAttributedString:(NSString *)imagePath
                                          isOutgoing:(BOOL)isOutgoing
{
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
    NSImage *scaleImage = [self scaleImage:image];
    
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
    
    NSMutableAttributedString *attributedString = (NSMutableAttributedString*)[NSAttributedString  attributedStringWithAttachment: attachment];
    
    [attributedString addAttributes:(isOutgoing ? rightMsgAttrDict : leftMsgAttrDict)
                              range:NSMakeRange(0, [attributedString length])];
    
    NSDictionary *dict = @{@"isMsg":[NSNumber numberWithBool:YES],
                           @"isOutgoing": [NSNumber numberWithBool:isOutgoing]};
    [attributedString addAttributes:dict
                              range:NSMakeRange(0, [attributedString length])];
    
    return attributedString;
}

- (void)appendAttributeImage:(NSString *)imagePath
                  isOutgoing:(BOOL)isOutgoing
                       atEnd:(BOOL)atEnd;
{
    NSMutableAttributedString *attributedString = [self imageAttributedString:imagePath isOutgoing:isOutgoing];
    
    if (atEnd) {
        [[self textStorage] appendAttributedString:attributedString];
    } else {
        [[self textStorage] insertAttributedString:attributedString
                                           atIndex:historyMsgInsertPosition];
        historyMsgInsertPosition += [attributedString length];
    }
}

- (void)replaceAttributeImage:(NSString *)imagePath atIndex:(NSUInteger)index isOutgoing:(BOOL)isOutgoing
{
    NSMutableAttributedString *attributedString = [self imageAttributedString:imagePath isOutgoing:isOutgoing];
    DDLog(@"replace image in index=%lu", index);
    
    NSRange range = NSMakeRange(index, 1);
    [[self textStorage] replaceCharactersInRange:range
                            withAttributedString:attributedString];
}

- (void)textView:(NSTextView *)textView
   clickedOnCell:(id<NSTextAttachmentCell>)cell
          inRect:(NSRect)cellFrame
         atIndex:(NSUInteger)charIndex
{
    DDLog(@"click atIndex=%lu", charIndex);
    
    selectImageRect = cellFrame;
    [self setNeedsDisplay:YES];
}

- (NSURL *)textView:(NSTextView *)textView URLForContentsOfTextAttachment:(NSTextAttachment *)textAttachment atIndex:(NSUInteger)charIndex
{
    return [[textAttachment fileWrapper] symbolicLinkDestinationURL];
}


- (void)displaySystemTips:(NSString *)tips
{
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:11];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    [paragraphStyle setParagraphSpacing:10];
    [paragraphStyle setParagraphSpacingBefore:10];
    NSDictionary *attrDict = @{NSFontAttributeName:font,
                        NSParagraphStyleAttributeName:paragraphStyle};
    
    [self appendAttributeText:tips
                withAttribute:attrDict
                        isMsg:NO
                   isOutgoing:NO
                        atEnd:YES];
    // scroll to the end
    NSUInteger totalLen = [[self string] length];
    [self scrollRangeToVisible:NSMakeRange(totalLen, 0)];
}


-(void)keyDown:(NSEvent *)theEvent{
    unichar characters =  [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(characters != 0x20){
        [super keyDown:theEvent];
        
    }else{
        QLPreviewPanel *prePanel = [QLPreviewPanel sharedPreviewPanel];
        if (prePanel) {
            [prePanel makeKeyAndOrderFront:nil];
        }
    }
    
}

// 用于测试图片按比例收缩时，保存到文件
-(void)saveImage:(NSImage *)image
{
    NSSize size = [image size];
    [image lockFocus];
    //先设置 下面一个实例
    NSBitmapImageRep *bits = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, size.width, size.height)];
    [image unlockFocus];

    //再设置后面要用到得 props属性
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];

    //之后 转化为NSData 以便存到文件中
    NSData *imageData = [bits representationUsingType:NSJPEGFileType properties:imageProps];

    //设定好文件路径后进行存储就ok了
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    NSString *downloadsDir = [dirList objectAtIndex:0];
    NSString *filePath = [downloadsDir stringByAppendingString:@"/test.jpg"];
    [imageData writeToFile:filePath atomically:YES];
    NSLog(@"----writetofile: %@", filePath);
}

@end
