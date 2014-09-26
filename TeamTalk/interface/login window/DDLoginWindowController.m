//
//  DDLoginWindowController.m
//  Duoduo
//
//  Created by maye on 13-10-30.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "DDLoginWindowController.h"
#import "DDDictionaryAdditions.h"
#import "DDUserListModule.h"
#import "DDLoginModule+UserManager.h"
#import "UserEntity.h"
#import "DDAlertWindowController.h"
#import "DDLoginWindow.h"

#import "DDLoginWindowControllerModule.h"
#import "DDAppDelegate.h"
#import "NSWindow+Addition.h"

//Preference Keys
#define NEW_USER_NAME		@"New User"		//Default name of a new user
#define LOGIN_WINDOW_NIB	@"LoginSelect"		//Filename of the login window nib


@interface DDLoginWindowController ()
@end

@implementation DDLoginWindowController


- (DDLoginWindowControllerModule*)module
{
    if (!_module)
    {
        _module = [[DDLoginWindowControllerModule alloc] init];
    }
    return _module;
}

// Internal --------------------------------------------------------------------------------
// init the login controller
- (id)init
{
	if ((self = [super initWithWindowNibName:LOGIN_WINDOW_NIB]))
    {
        DDLoginWindow *loginWindow = (DDLoginWindow *)[self window];
        [loginWindow setLoginWindowController:self];
	}
	return self;
}

- (void)awakeFromNib
{
    [self.avatarIcon setWantsLayer:YES];
    [self.avatarIcon.layer setMasksToBounds:YES];
    [self.avatarIcon.layer setCornerRadius:self.avatarIcon.bounds.size.width / 2.0];
    [self.window addCloseButtonAtTopLeft];
    [self.window center];
}

#pragma mark login:
- (IBAction)login:(id)sender
{
    //TODO:用户输入合法性检测
    [self.loginButton setHidden:YES];
    [self.loginLoading setHidden:NO];
    [self.loginLoading startAnimation:nil];
    NSString* userName = [self.txtUserName stringValue];
    NSString* pass = [self.txtPassword stringValue];
    [self.module loginWithUserName:userName password:pass success:^{
        [self.loginLoading setHidden:YES];
        [self.loginButton setHidden:NO];
        [self close];
        [[DDMainWindowController instance].window makeKeyAndOrderFront:nil];
    } failure:^(NSString *info){
        if (!info)
        {
            info = @"用户登录失败(125绑定)";
        }
        [[DDAlertWindowController  defaultControler] showAlertWindow:[self window] title:@"提示" info:info leftBtnName:@"" midBtnName:@"" rightBtnName:@"确定"];
        [self.loginLoading setHidden:YES];
        [self.loginButton setHidden:NO];
    }];
    return;
}

// set up the window before it is displayed
- (void)windowDidLoad
{
    [self.loginLoading setHidden:YES];
    
    //Center the window
    [[self window] center];
    
    if(self.module.lastuserName)
       [_txtUserName setStringValue:self.module.lastuserName];
    
    if(self.module.lastpassword)
       [_txtPassword setStringValue:self.module.lastpassword];
    
    NSURL* url = [NSURL URLWithString:self.module.lastavatar];
    [_avatarIcon loadImageWithURL:url setplaceholderImage:@"duoduo"];
    
    [self.txtUserName setFocusRingType:NSFocusRingTypeNone];
    [self.txtPassword setFocusRingType:NSFocusRingTypeNone];
}


// called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
}

#pragma mark NSTextField Delegate

- (void)controlTextDidChange:(NSNotification *)obj
{
    NSTextField* object = [obj object];
    if ([object isEqual:_txtUserName])
    {
        //用户名在变，更改用户头像
        NSString* name = [_txtUserName stringValue];
        NSString* avatar = [self.module getAvatarForUserName:name];
        NSURL* avatarURL = [NSURL URLWithString:avatar];
        [_avatarIcon loadImageWithURL:avatarURL setplaceholderImage:@"duoduo"];
    }
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
    return YES;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if ([NSStringFromSelector(commandSelector) isEqualToString:@"insertNewline:"])
    {
        [self login:nil];
        return NO;
    }
    else if ([NSStringFromSelector(commandSelector) isEqualToString:@"insertTab:"])
    {
        [self.txtPassword becomeFirstResponder];
        return NO;
    }
    else
    {
        [textView performSelector:commandSelector withObject:textView];
    }
    return YES;
}
@end
