//
//  DDPathHelp.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-16.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDPathHelp.h"


static NSString* const loginArchivedName = @"LoginArchived";

#define PORTABLE_ADIUM_KEY					@"Preference Folder Location"


@implementation DDPathHelp
+ (NSString*)applicationSupportDirectory
{
    static NSString *preferencesFolderPath = nil;
	
    //Determine the preferences path if neccessary
	if (!preferencesFolderPath) {
		preferencesFolderPath = [[[[NSBundle mainBundle] infoDictionary] objectForKey:PORTABLE_ADIUM_KEY] stringByExpandingTildeInPath];
		if (!preferencesFolderPath)
			preferencesFolderPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Duoduo 1.0"];
	}
	
	return preferencesFolderPath;
}

+ (NSString*)loginArchivedDataPath
{
    NSString* applicationSupportDirectory = [DDPathHelp applicationSupportDirectory];
    NSString* loginArchivedPath = [applicationSupportDirectory stringByAppendingPathComponent:loginArchivedName];
    return loginArchivedPath;
}

+ (NSString*)downLoadPath
{
    NSString* downLoadPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
    return downLoadPath;
}
@end
