//
//  DDUserDataWindowController.m
//  Duoduo
//
//  Created by 独嘉 on 14-2-25.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDUserDataWindowController.h"
#import "DDUserDataModel.h"
#import "NSWindow+Addition.h"
#import "DDUserlistModule.h"
#import "DDImageUploader.h"
#import "DDModifyUserAvatarAPI.h"
@interface DDUserDataWindowController ()

/**
 *  load the user info in model
 */
- (void)loadUserInfo;


- (void)setAllViewHidden:(BOOL)sender;


- (void)hidePanel;

- (void)n_receiveWindowResignKeyNotification:(NSNotification*)notification;
@end

@implementation DDUserDataWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib
{
    [self.window addCloseButtonAtTopLeft];
    [self.window setBackgroundColor:[NSColor clearColor]];
    [self.window setOpaque:NO];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(n_receiveWindowResignKeyNotification:)
                                                 name:NSWindowDidResignMainNotification
                                               object:nil];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)setModel:(DDUserDataModel *)model
{
    if (_model)
    {
        _model = nil;
    }
    _model = model;
    [_model addObserver:self forKeyPath:@"showUser" options:0 context:nil];
}

- (IBAction)beginChat:(id)sender
{
    NSString* sessionID = [self.model.showUser userId];
    [[DDMainWindowController instance] openChatViewByUserId:sessionID];
    [self close];
}

- (IBAction)modifyUserAvater:(id)sender
{
    IKPictureTaker *pictureTaker = [IKPictureTaker pictureTaker];
    
    /* set default image */
    [self p_setImageInputForPictureTaker:pictureTaker];
    
	/* configure the PictureTaker to show effects */
	[pictureTaker setValue:[NSNumber numberWithBool:YES] forKey:IKPictureTakerShowEffectsKey];
    
	/* other possible configurations (uncomments to try) */
	//[pictureTaker setValue:[NSNumber numberWithBool:NO] forKey:IKPictureTakerAllowsVideoCaptureKey];
	//[pictureTaker setValue:[NSNumber numberWithBool:NO] forKey:IKPictureTakerAllowsFileChoosingKey];
	//[pictureTaker setValue:[NSNumber numberWithBool:NO] forKey:IKPictureTakerShowRecentPictureKey];
	//[pictureTaker setValue:[NSNumber numberWithBool:NO] forKey:IKPictureTakerUpdateRecentPictureKey];
	//[pictureTaker setValue:[NSNumber numberWithBool:NO] forKey:IKPictureTakerAllowsEditingKey];
	//[pictureTaker setValue:[NSString stringWithString:@"Drop an Image Here"] forKey:IKPictureTakerInformationalTextKey];
	//[pictureTaker setValue:[NSValue valueWithSize:NSMakeSize(256,256)] forKey:IKPictureTakerOutputImageMaxSizeKey];
	//[pictureTaker setValue:[NSValue valueWithSize:NSMakeSize(100, 100)] forKey:IKPictureTakerCropAreaSizeKey];
    
	
	/* launch the PictureTaker as a panel */
	[pictureTaker beginPictureTakerWithDelegate:self didEndSelector:@selector(pictureTakerValidated:code:contextInfo:) contextInfo:nil];
}

- (void)dealloc
{
    [_model removeObserver:self forKeyPath:@"showUser"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"showUser"])
    {
        [self loadUserInfo];
    }
}

#pragma mark Delegate
// -------------------------------------------------------------------------
//	pictureTakerValidated:code:contextInfo:
//
//  Invoked when the PictureTaker terminates.
//	Retrieves the output image and sets it on the view
// -------------------------------------------------------------------------
- (void) pictureTakerValidated:(IKPictureTaker*) pictureTaker code:(int) returnCode contextInfo:(void*) ctxInf
{
    if(returnCode == NSOKButton){
		/* retrieve the output image */
        NSImage *outputImage = [pictureTaker outputImage];
        
        [[DDImageUploader instance] uploadImage:outputImage success:^(NSString *imageURL) {
            NSString* url = [imageURL copy];
            if ([url rangeOfString:IMAGE_MARK_START].length > 0)
            {
                url = [url stringByReplacingOccurrencesOfString:IMAGE_MARK_START withString:@""];
                url = [url stringByReplacingOccurrencesOfString:IMAGE_MARK_END withString:@""];
            }
            DDModifyUserAvatarAPI* modifyUserAvatarAPI = [[DDModifyUserAvatarAPI alloc] init];
            DDUserlistModule* userModify = [DDUserlistModule shareInstance];
            NSString* myUserID = userModify.myUserId;
            [modifyUserAvatarAPI requestWithObject:@[myUserID,url] Completion:^(id response, NSError *error) {
                if (!error)
                {
                    if ([response boolValue])
                    {
                        
                        DDLog(@"上传成功");
                        [[DDMainWindowController instance]leftChangeUseravatar:outputImage];
                    }
                    else
                    {
                        DDLog(@"上传失败");
                    }
                }
            }];
        } failure:^(id error) {
            DDLog(@"上传图片失败");
        }];
        [self hidePanel];
    }
	else{
		/* the user canceled => nothing to do here */
	}
}

#pragma mark privateAPI
- (void)loadUserInfo
{
    [self setAllViewHidden:YES];
    [_loadIndicator startAnimation:nil];
    [self.model loadUserInfoSuccess:^(NSDictionary *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setAllViewHidden:NO];
            DDUserlistModule* userModule = [DDUserlistModule shareInstance];
            NSString* myUserID = userModule.myUserId;
            [_modifyAvatarButton setHidden:![self.model.showUser.userId isEqualToString:myUserID]];
            [_loadIndicator stopAnimation:nil];
            [_loadIndicator setHidden:YES];
            NSString* avatar = result[@"avatar"];
            if ([avatar length] > 0)
            {
                avatar = [NSString stringWithFormat:@"%@_200x200.jpg",avatar];
                if (avatar){
                    NSURL* url = [NSURL URLWithString:avatar];
                    [_userAvatar loadImageWithURL:url setplaceholderImage:@"avatar_default.jpg_48x48"];
                }
            }
            else
            {
                [_userAvatar setImage:[NSImage imageNamed:@"avatar_default.jpg_48x48"]];
            }
    
            
            NSString* department = result[@"departName"];
            if (department)[_departmentTextField setStringValue:department];
            
            NSNumber* gender = result[@"gender"];
            if (gender) {
                switch ([gender intValue])
                {
                    case 1:
                        [_userGenderTextField setStringValue:@"男"];
                        break;
                    case 2:
                        [_userGenderTextField setStringValue:@"女"];
                        break;
                    default:
                        break;
                }
                
            }
            
            NSString* realName = result[@"realName"];
            if (realName) [_userNameTextField setStringValue:realName];
            
            NSString* name = result[@"uname"];
            if (name) [_userNickTextField setStringValue:name];
            
            NSString* tel = result[@"tel"];
            if(tel)
            {
                [_phoneTextField setStringValue:tel];
            }
        });
        
    } failure:^(StatusEntity *error) {
        [_loadIndicator stopAnimation:nil];
        [_loadIndicator setHidden:YES];
        log4Error(@"load user info error code:%ld,msg:%@ userInfo:%@",error.code,error.msg,error.userInfo);
        DDLog(@"load user info error code:%ld,msg:%@ userInfo:%@",error.code,error.msg,error.userInfo);
    }];
}


- (void)setAllViewHidden:(BOOL)sender
{
    for (NSView * subView in [[self.window contentView] subviews])
    {
        if (subView.tag < 10)
        {
            [subView setHidden:sender];
        }
    }
}

- (void)hidePanel
{
    [self.window orderOut:nil];
}

- (void)n_receiveWindowResignKeyNotification:(NSNotification*)notification
{
    NSWindow* window = [notification object];
    if ([window isEqual:self.window])
    {
        [self hidePanel];
    }
}

-(void)p_setImageInputForPictureTaker:(IKPictureTaker *)pictureTaker
{
    //retrieve example image
	NSURL *picURL = nil;
	NSBundle *bundle = [NSBundle mainBundle];
	if (bundle)
	{
		NSString *picPath = [bundle pathForResource:@"picture" ofType:@"jpg"];
		if (picPath)
		{
            /* set a default image to start with */
			picURL = [NSURL fileURLWithPath:picPath];
            [pictureTaker setInputImage:[[NSImage alloc] initByReferencingURL:picURL]];
		}
	}
}

@end
