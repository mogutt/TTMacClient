//
//  CONSTANT.h
//  Duoduo
//
//  Created by 独嘉 on 14-2-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#ifndef Duoduo_CONSTANT_h
#define Duoduo_CONSTANT_h

/**
 *  常用宏定义
 */

#define RGB_COLOR(r,g,b,a)              [NSColor colorWithCalibratedRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a]

/**
 *  Debug模式和Release模式不同的宏定义
 */

//-------------------打印--------------------
#ifdef DEBUG
#define NEED_OUTPUT_LOG             1
#define Is_CanSwitchServer          1
#else
#define NEED_OUTPUT_LOG             0
#define Is_CanSwitchServer          0
#endif

#if NEED_OUTPUT_LOG
#define DDLog(xx, ...)                      NSLog(@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DDLog(xx, ...)
#endif

//-------------------本地化--------------------
//在所有显示在界面上的字符串进行本地化处理
#define _(x)                                NSLocalizedString(x,@"")
#endif

/**
 *  字符串 键
 */
#define TOP_SESSION_KEY                     @"TopSession"
#define SHIELD_SESSION_KEY                  @"ShieldSessionKey"
#define FIRST_TIME_SET_BUSINESS_SHIELD      @"FirstTimeSetBusinessShield"
/**
 *  通知宏定义
 */
#define RELOAD_RECENT_ESSION_ROW                  @"ReloadTheRecentSession"


#warning 可配置
#define SERVER_IP                           @"122.225.68.125"//
#define SERVER_PORT                         18008//登录服务器端口

#define IMAGE_MARK_START                    @"&$#@~^@[{:"
#define IMAGE_MARK_END                      @":}]&$~@#@"

#define APP_DELEGATE                        (DDAppDelegate*)[NSApplication sharedApplication].delegate

#define CLIENT_TYPE                         0x02
#define CLIENT_VERSION                      [NSString stringWithFormat:@"MAC/%@-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]