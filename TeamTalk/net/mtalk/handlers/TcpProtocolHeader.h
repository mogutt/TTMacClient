/************************************************************
 * @file         TcpProtocolHeader.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       tcp服务器协议头，包括每个service下的command Id定义
 *
     packet data unit header format:
     length     -- 4 byte
     version    -- 2 byte
     flag       -- 2 byte
     service_id -- 2 byte
     command_id -- 2 byte
     error      -- 2 byte
     reserved   -- 2 byte
 ************************************************************/

#import <Foundation/Foundation.h>

//MODULE_ID_LOGIN = 2   登陆相关
#define IM_PDU_HEADER_LEN   12
#define IM_PDU_VERSION      5

enum
{
    CMD_LOGIN_REQ_MSGSERVER                     = 1,                //获取消息服务器信息接口请求
    CMD_LOGIN_RES_MSGSERVER                     = 2,                //返回一个消息服务器的IP和端口
    CMD_LOGIN_REQ_USERLOGIN                     = 3,                //用户登录请求
    CMD_LOGIN_RES_USERLOGIN                     = 4,                //登陆消息服务器验证结果
    CMD_LOGIN_RES_USERLOGOUT                    = 6,                //这个目前不用实现
    CMD_LOGIN_KICK_USER                         = 7,                //踢出用户提示.
};

//MODULE_ID_FRIENDLIST = 3 成员列表相关
enum
{
    CMD_FRI_REQ_RECENT_LIST         = 1,                //获取最近联系人请求
    CMD_FRI_SERVICE_LIST            = 2,                //店铺客服列表
    CMD_FRI_RECENT_CONTACTS         = 3,                //最近联系人列表
    CMD_FRI_USERLIST_ONLINE_STATE   = 4,                //在线好友状态列表
    CMD_FRI_USER_STATE_CHANGE       = 5,                //好友状态更新通知
    CMD_FRI_ADD_NEW_BUSINESS_USER   = 7,                //分配客服的回复
    CMD_FRI_GET_USER_ONLINE_STATE   = 9,                //返回某个用户的在线状态
    CMD_FRI_USER_INFO_LIST          = 10,               //返回用户信息列表
    CMD_FRI_USER_INFO_LIST_REQ      = 11,               //用户信息列表请求
    CMD_FRI_REMOVE_SESSION_REQ      = 12,               //移除会话请求
    CMD_FRI_REMOVE_SESSION_RES      = 13,               //移除会话返回
    CMD_FRI_ALL_USER_REQ            = 14,               // 获取公司全部员工信息
    CMD_FRI_ALL_USER_RES            = 15,
    CMD_FRI_LIST_STATE_REQ          = 16,               //批量获取用户在线状态
    CMD_FRI_LIST_STATE_RES          = 17,               //批量返回用户在线状态
    CMD_ORGANIZATION_INFO_REQ       = 18,               //获取公司组织架构
    CMD_ORGANIZATION_INFO_RES       = 19,               //返回公司组织架构
    CMD_FRI_MODIFY_USER_AVATAR_REQ  = 20,               //修改用户头像
    CMD_FRI_MODIFY_USER_AVATAR_RES  = 21                //修改用户头像返回
};

//MODULE_ID_SESSION = 80 消息会话相关
enum
{
    CMD_MSG_DATA                        = 1,            //收到聊天消息
    CMD_MSG_DATA_ACK                    = 2,            //消息收到确认.  这是收
    CMD_MSG_READ_ACK                    = 3,            //消息已读确认
    CMD_MSG_UNREAD_CNT_REQ              = 7,            //请求未读消息计数
    CMD_MSG_UNREAD_CNT_RES              = 8,            //返回自己的未读消息计数
    CMD_MSG_UNREAD_MSG_REQ              = 9,            //请求两人之间的未读消息
    CMD_MSG_HISTORY_MSG_REQ             = 10,           //请求两人之间的历史消息
    CMD_MSG_GET_2_UNREAD_MSG            = 14,           //返回两人之间的未读消息
    CMD_MSG_GET_2_HISTORY_MSG           = 15,           //查询两人之间的历史消息
};

//MODULE_ID_P2P
enum {
    CMD_P2P_CMD_DATA        = 1,                        //抖屏
//    CMD_P2P_CMD_INPUTING    = 2,                        //正在输入
//    CMD_P2P_CMD_STOPINPUTING= 3                         //停止输入
};

//MODULE_ID_FILETRANSFER = 90 文件传输相关
enum
{
    // to/from FileServer
    CMD_FILE_LOGIN_REQ              = 1,    // 登录FileServer请求
    CMD_FILE_LOGIN_RES              = 2,    // 登录FileServer回复
    CMD_FILE_NOTIFY_STATE           = 3,    // 收到服务器端的状态通知
    CMD_FILE_PULLDATA_REQ           = 4,	// 完成离线文件上传
    CMD_FILE_DATA                   = 5,	// 文件传输数据包
    CMD_FILE_HAS_OFFLINE_REQ		= 16,   // 用户登录时查询是否有离线文件
	CMD_FILE_HAS_OFFLINE_RES		= 17,   // 返回是否有离线文件
    
    // to/from MsgServer
    CMD_FILE_REQUEST                = 10,   // 文件传输请求
    CMD_FILE_RESPONSE               = 11,   // 对方接受或拒绝文件传输
    CMD_FILE_RECEIVE_FILE_SEND_REQ  = 12,   // 收到对方的文件传输请求
    
    CMD_FILE_ABORT                  = 13,   // 放弃文件传输
    CMD_FILE_UPLOAD_OFFLINE_NOTIFY  = 14,   // 发送方通知对方上传离线文件
    CMD_FILE_DOWNLOAD_OFFLINE_NOTIFY= 15,  // 发送发通知对方离线文件上传完成，可以下载
    CMD_FILE_ADD_OFFLINE_REQ        = 18,
    CMD_FILE_DEL_OFFLINE_REQ        = 19,
};

// MODULE_ID_GROUP, command id for group chat
enum {
    CMD_ID_GROUP_LIST_REQ           = 1,    // 固定群
    CMD_ID_GROUP_LIST_RES           = 2,
    CMD_ID_GROUP_USER_LIST_REQ      = 3,
    CMD_ID_GROUP_USER_LIST_RES      = 4,
    CMD_ID_GROUP_UNREAD_CNT_REQ     = 5,
    CMD_ID_GROUP_UNREAD_CNT_RES     = 6,
    CMD_ID_GROUP_UNREAD_MSG_REQ     = 7,
    CMD_ID_GROUP_UNREAD_MSG_RES     = 8,
    CMD_ID_GROUP_HISTORY_MSG_REQ    = 9,
    CMD_ID_GROUP_HISTORY_MSG_RES    = 10,
    CMD_ID_GROUP_MSG_READ_ACK       = 11,
    CMD_ID_GROUP_CREATE_TMP_GROUP_REQ   = 12,
    CMD_ID_GROUP_CREATE_TMP_GROUP_RES   = 13,
    CMD_ID_GROUP_JOIN_GROUP_REQ     = 14,
    CMD_ID_GROUP_JOIN_GROUP_RES     = 15,
    CMD_ID_GROUP_DIALOG_LIST_REQ    = 16,   // 最近联系群
    CMD_ID_GROUP_DIALOG_LIST_RES    = 17,
    CMD_ID_GROUP_QUIT_GROUP_REQ     = 18,
    CMD_ID_GROUP_QUIT_GROUP_RES     = 19,
};

@interface TcpProtocolHeader : NSObject

@property (nonatomic,assign) uint16 version;
@property (nonatomic,assign) uint16 flag;
@property (nonatomic,assign) uint16 serviceId;
@property (nonatomic,assign) uint16 commandId;
@property (nonatomic,assign) uint16 reserved;
@property (nonatomic,assign) uint16 error;

@end
