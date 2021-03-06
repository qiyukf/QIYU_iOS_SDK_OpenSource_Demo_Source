#import "QYSettingViewController.h"
#import "QYUserTableViewController.h"
#import "QYBindAppkeyViewController.h"
#import "QYDemoConfig.h"
#import "QYPOPSDK.h"
#import "YSFCommonTableData.h"
#import "YSFCommonTableDelegate.h"
#import "YSFCommonTableViewCell.h"
#import "UIView+YSFToast.h"
#import "QYDemoBadgeView.h"
#import "UIView+YSF.h"
#import "QYLogViewController.h"
#import "QYCommodityInfoViewController.h"
#import "QYTestModeViewController.h"
#import "QYHomePageViewController.h"
#import "QYSessionListViewController.h"
#import "UIAlertView+YSF.h"


BOOL g_isDefault;
int64_t    g_groupId;
int64_t    g_staffId;
int64_t    g_robotId;
NSInteger    g_vipLevel;
int64_t    g_questionId;
BOOL    g_openRobotInShuntMode;
NSString    * g_authToken;
NSMutableArray*    g_buttonArray;



@interface YSFUnReadCount : UITableViewCell<YSFCommonTableViewCell, QYConversationManagerDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) YSFDemoBadgeView *badgeView;
@end

@implementation YSFUnReadCount

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _badgeView = [[YSFDemoBadgeView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [self addSubview:_badgeView];
    }
    return self;
}

- (void)refreshData:(YSFCommonTableRow *)rowData tableView:(UITableView *)tableView{
    self.textLabel.text    = rowData.title;
    self.detailTextLabel.text = rowData.detailTitle;
    [self configBadgeView];
    [[[QYSDK sharedSDK] conversationManager] setDelegate:self];
}

- (void)onUnreadCountChanged:(NSInteger)count
{
    [self configBadgeView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _badgeView.ysf_frameRight = self.ysf_frameRight - 50;
    _badgeView.ysf_frameCenterY = self.ysf_frameHeight / 2;
}

- (void)configBadgeView
{
    NSInteger count = [[[QYSDK sharedSDK] conversationManager] allUnreadCount];
    [_badgeView setHidden:count == 0];
    NSString *value = count > 99 ? @"99+" : [NSString stringWithFormat:@"%zd",count];
    [_badgeView setBadgeValue:value];
}

@end



@interface QYSettingViewController () <QYSessionViewDelegate>

@property (nonatomic,strong) NSArray *data;
@property (nonatomic,strong) YSFCommonTableDelegate *delegator;
@property (nonatomic, copy) NSString *key;

@end

@implementation QYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.key = [[NSUUID UUID] UUIDString];
    g_buttonArray = [NSMutableArray new];
    g_isDefault = true;
    self.navigationItem.title = @"设置";
    self.tableView.backgroundColor = YSFColorFromRGB(0xeeeeee);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    __weak typeof(self) wself = self;
    self.delegator = [[YSFCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    
    [self buildData];
    
    [[QYSDK sharedSDK] registerPushMessageNotification:^(QYPushMessage *message) {
        NSString *time = [QYSettingViewController showTime:message.time showDetail:YES];
        NSString *content = [NSString stringWithFormat:@"时间%@ 内容：%@", time, message.text] ;
        UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"推送消息"
                                                         message:content delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [dialog show];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[QYSDK sharedSDK] trackHistory:@"设置" enterOrOut:YES key:_key];
    [self buildData];
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[QYSDK sharedSDK] trackHistory:@"设置" enterOrOut:NO key:_key];
    self.key = [[NSUUID UUID] UUIDString];
}

- (void)buildData
{
    NSString *appkey = [QYDemoConfig sharedConfig].appKey;
    NSString *bindAppkey;
    NSString *bindAppkeyDetail = @"";
    if (!appkey) {
        bindAppkey = @"绑定appkey";
    }
    else {
        bindAppkey = @"已绑定AppKey";
        bindAppkeyDetail = @"AppKey: ";
        bindAppkeyDetail = [bindAppkeyDetail stringByAppendingString:appkey];
    }

    NSMutableArray *data = [[NSMutableArray alloc] init];
    [data addObject:@{
                       YSFHeaderTitle:@"",
                       YSFRowContent :@[
                               @{
                                   YSFTitle      :@"个人信息",
                                   YSFCellAction :@"onChangeUserInfo:",
                                   YSFShowAccessory : @(YES)
                                   },
                               @{
                                   YSFTitle      :bindAppkey,
                                   YSFDetailTitle:bindAppkeyDetail,
                                   YSFCellAction :@"onBindAppkey:",
                                   YSFShowAccessory : @(YES)
                                   },
                               ],
                       YSFFooterTitle:@""
                       }];
    [data addObject:@{
                       YSFHeaderTitle:@"",
                       YSFRowContent :@[
                               @{
                                   YSFTitle      :@"切换聊天窗口样式",
                                   YSFCellAction :@"onChangeSkin:",
                                   },
                               
                               @{
                                   YSFTitle      :@"查看log",
                                   YSFCellAction :@"viewNimLog:",
                                   YSFShowAccessory : @(YES)
                                   },

                               @{
                                   YSFTitle      :@"关于",
                                   YSFCellAction :@"onAbout:",
                                   YSFShowAccessory : @(YES)
                                   }
                               
                               ],
                       YSFFooterTitle:@""
                       }];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:@[
                                  @{
                                      YSFTitle      :@"常见问题模版ID",
                                      YSFCellAction :@"onCommonQuestionTemplateId:",
                                      YSFShowAccessory : @(YES)
                                      },
                                  @{
                                      YSFTitle      :@"分组ID",
                                      YSFCellAction :@"onInputGroupId:",
                                      YSFShowAccessory : @(YES)
                                      },
                                  @{
                                      YSFTitle      :@"客服ID",
                                      YSFCellAction :@"onInputStaffId:",
                                      YSFShowAccessory : @(YES)
                                      },
                                  @{
                                      YSFTitle      :@"机器人ID",
                                      YSFCellAction :@"onInputRobotId:",
                                      YSFShowAccessory : @(YES)
                                      },
                                  @{
                                      YSFTitle      :@"vip等级",
                                      YSFCellAction :@"onInputVipLevel:",
                                      YSFShowAccessory : @(YES)
                                      },
                                  @{
                                      YSFTitle      :@"authToken",
                                      YSFCellAction :@"onInputAuthToken:",
                                      YSFShowAccessory : @(YES)
                                      },
                                  @{
                                      YSFCellClass  :@"YSFUnReadCount",
                                      YSFTitle      :@"联系客服",
                                      YSFCellAction :@"onChat",
                                      YSFShowAccessory : @(YES)
                                      },
                                  @{
                                      YSFTitle      :@"清理缓存文件",
                                      YSFCellAction :@"onCleanCache:",
                                      YSFShowAccessory : @(NO)
                                      },
                                  @{
                                      YSFTitle      :@"清空未读数",
                                      YSFCellAction :@"onClearUnreadCount",
                                      YSFShowAccessory : @(NO)
                                      },
                                  @{
                                      YSFTitle      :@"是否显示关闭会话按钮",
                                      YSFCellAction :@"onDisplayCloseSessionButton",
                                      YSFShowAccessory : @(NO)
                                      },
                                  @{
                                      YSFTitle      :@"添加输入区域上方工具栏按钮",
                                      YSFCellAction :@"onAddButton",
                                      YSFShowAccessory : @(YES)
                                      },
                                  ]];
    
    if (isTestMode) {
        [array addObject:@{
                      YSFTitle      :@"会话列表",
                      YSFCellAction :@"onSessionList:",
                      YSFShowAccessory : @(YES)
                      }];
        [array addObject:@{
                      YSFTitle      :@"测试入口",
                      YSFCellAction :@"onTestEntry:",
                      YSFShowAccessory : @(YES)
                      }];
    }
        
    //非测试模式
    [data addObject:@{
                      YSFHeaderTitle:@"",
                      YSFRowContent :array,
                      YSFFooterTitle:@""
                      }];

    
    
    self.data = [YSFCommonTableSection sectionsWithData:data];
}

- (void)onTestEntry:(id)sender
{
    QYTestModeViewController *vc = [[QYTestModeViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onChangeUserInfo:(id)sender
{
    QYUserTableViewController *vc = [[QYUserTableViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)onChangeSkin:(id)sender
{
    if (g_isDefault) {
        g_isDefault = false;
//        [[QYSDK sharedSDK] customUIConfig].sessionTipTextColor = [UIColor blackColor];
//        [[QYSDK sharedSDK] customUIConfig].sessionTipTextFontSize = 20;
//        [[QYSDK sharedSDK] customUIConfig].customMessageTextFontSize = 20;
//        [[QYSDK sharedSDK] customUIConfig].serviceMessageTextFontSize = 20;
//        [[QYSDK sharedSDK] customUIConfig].tipMessageTextColor = [UIColor blueColor];
//        [[QYSDK sharedSDK] customUIConfig].tipMessageTextFontSize = 16;
//        [[QYSDK sharedSDK] customUIConfig].inputTextColor = [UIColor blueColor];
//        [[QYSDK sharedSDK] customUIConfig].inputTextFontSize = 20;
        
        //[[QYSDK sharedSDK] customUIConfig].sessionTipBackgroundColor = [UIColor blueColor];
        //[[QYSDK sharedSDK] customUIConfig].sessionMessageSpacing = 20;
        
        [[QYSDK sharedSDK] customUIConfig].customMessageTextColor = [UIColor blackColor];
        [[QYSDK sharedSDK] customUIConfig].customMessageHyperLinkColor = [UIColor blackColor];
        [[QYSDK sharedSDK] customUIConfig].serviceMessageTextColor = [UIColor blackColor];
        [[QYSDK sharedSDK] customUIConfig].serviceMessageHyperLinkColor = [UIColor blueColor];

        UIImage *backgroundImage = [[UIImage imageNamed:@"session_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeTile];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:backgroundImage];
        imageView.contentMode = UIViewContentModeScaleToFill;
        [[QYSDK sharedSDK] customUIConfig].sessionBackground = imageView;

        [[QYSDK sharedSDK] customUIConfig].customerHeadImage = [UIImage imageNamed:@"customer_head"];
        [[QYSDK sharedSDK] customUIConfig].customerHeadImageUrl = @"http://www.274745.cc/imgall/obuwgnjonzuxa2ldfzrw63i/20100121/1396946_104643942888_2.jpg";
        [[QYSDK sharedSDK] customUIConfig].serviceHeadImage = [UIImage imageNamed:@"service_head"];
        [[QYSDK sharedSDK] customUIConfig].serviceHeadImageUrl = @"http://pic33.nipic.com/20130916/3420027_192919547000_2.jpg";
        
        [[QYSDK sharedSDK] customUIConfig].customerMessageBubbleNormalImage = [[UIImage imageNamed:@"icon_sender_node"]
                                             resizableImageWithCapInsets:UIEdgeInsetsMake(15,15,30,30)
                                             resizingMode:UIImageResizingModeStretch];
        [[QYSDK sharedSDK] customUIConfig].customerMessageBubblePressedImage = [[UIImage imageNamed:@"icon_sender_node"]
                                              resizableImageWithCapInsets:UIEdgeInsetsMake(15,15,30,30)
                                              resizingMode:UIImageResizingModeStretch];
        [[QYSDK sharedSDK] customUIConfig].serviceMessageBubbleNormalImage = [[UIImage imageNamed:@"icon_receiver_node"]
                                            resizableImageWithCapInsets:UIEdgeInsetsMake(15,30,30,15)
                                            resizingMode:UIImageResizingModeStretch];
        [[QYSDK sharedSDK] customUIConfig].serviceMessageBubblePressedImage = [[UIImage imageNamed:@"icon_receiver_node"]
                                             resizableImageWithCapInsets:UIEdgeInsetsMake(15,30,30,15)
                                             resizingMode:UIImageResizingModeStretch];
        [[QYSDK sharedSDK] customUIConfig].rightBarButtonItemColorBlackOrWhite = NO;
    }
    else {
        g_isDefault = true;
        [[[QYSDK sharedSDK] customUIConfig] restoreToDefault];
    }
    
    if ([[QYSDK sharedSDK] customUIConfig].bypassDisplayMode == QYBypassDisplayModeNone) {
        [[QYSDK sharedSDK] customUIConfig].bypassDisplayMode = QYBypassDisplayModeBottom;
    }
    else if ([[QYSDK sharedSDK] customUIConfig].bypassDisplayMode == QYBypassDisplayModeBottom) {
        [[QYSDK sharedSDK] customUIConfig].bypassDisplayMode = QYBypassDisplayModeCenter;
    }
    else if ([[QYSDK sharedSDK] customUIConfig].bypassDisplayMode == QYBypassDisplayModeCenter) {
        [[QYSDK sharedSDK] customUIConfig].bypassDisplayMode = QYBypassDisplayModeNone;
    }
    
    [self.view ysf_makeToast:@"切换成功" duration:2.0 position:YSFToastPositionCenter];
}

- (void)viewNimLog:(id)sender
{
    NSString *path = [[QYSDK sharedSDK] qiyuLogPath];
    QYLogViewController *vc = [[QYLogViewController alloc] initWithFilepath:path];
    vc.title = @"log";
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onAbout:(id)sender
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [infoDictionary objectForKey:@"CFBundleVersion"];
    appVersion = [appVersion stringByAppendingString:@"  "];
    appVersion = [appVersion stringByAppendingString:build];
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"版本号" message:appVersion delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)onChat
{
    QYSource *source = [[QYSource alloc] init];
    source.title =  @"七鱼金融";
    source.urlString = @"https://8.163.com/";
    
    
    QYSessionViewController *sessionViewController = [[QYSDK sharedSDK] sessionViewController];
    sessionViewController.delegate = self;
    sessionViewController.sessionTitle = @"七鱼金融";
    sessionViewController.source = source;
    sessionViewController.groupId = g_groupId;
    sessionViewController.staffId = g_staffId;
    sessionViewController.robotId = g_robotId;
    sessionViewController.vipLevel = g_vipLevel;
    sessionViewController.commonQuestionTemplateId = g_questionId;
    sessionViewController.openRobotInShuntMode = g_openRobotInShuntMode;
    sessionViewController.buttonInfoArray = g_buttonArray;
    __weak typeof(sessionViewController) weakSessionViewController = sessionViewController;
    sessionViewController.buttonClickBlock = ^(QYButtonInfo *action) {
        if ([[NSUserDefaults standardUserDefaults] stringForKey:YSFDemoCommodityInfoTitle]) {
            QYCommodityInfo *commodityInfo = [[QYCommodityInfo alloc] init];
            commodityInfo.title = [[NSUserDefaults standardUserDefaults] stringForKey:YSFDemoCommodityInfoTitle];
            commodityInfo.desc = [[NSUserDefaults standardUserDefaults] stringForKey:YSFDemoCommodityInfoDesc];
            commodityInfo.urlString = [[NSUserDefaults standardUserDefaults] stringForKey:YSFDemoCommodityInfoUrlString];
            commodityInfo.pictureUrlString = [[NSUserDefaults standardUserDefaults] stringForKey:YSFDemoCommodityInfoPictureUrlString];
            commodityInfo.note = [[NSUserDefaults standardUserDefaults] stringForKey:YSFDemoCommodityInfoNote];
            commodityInfo.show = [[NSUserDefaults standardUserDefaults] boolForKey:YSFDemoOnShowKey];
            [weakSessionViewController sendCommodityInfo:commodityInfo];
        }
    };
    g_groupId = 0;
    g_staffId = 0;
    g_robotId = 0;
    g_vipLevel = 0;
    g_questionId = 0;
    BOOL showTabbar = [[NSUserDefaults standardUserDefaults] boolForKey:YSFDemoOnShowTabbar];
    sessionViewController.hidesBottomBarWhenPushed = YES;
    if (showTabbar) {
        sessionViewController.hidesBottomBarWhenPushed = NO;
        [[QYSDK sharedSDK] customUIConfig].bottomMargin = self.tabBarController.tabBar.ysf_frameHeight;
    }
    else {
        [[QYSDK sharedSDK] customUIConfig].bottomMargin = 0;
    }
    [[QYSDK sharedSDK] customActionConfig].botClick = ^(NSString *target, NSString *params) {
        UIViewController *appRootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        UIViewController *topVC = appRootVC;
        if (topVC.presentedViewController) {
            topVC = topVC.presentedViewController;
        }
        NSString *tip = [NSString stringWithFormat:@"target: %@, params: %@", target, params];
        [topVC.view ysf_makeToast:tip duration:2.0 position:YSFToastPositionCenter];
    };

    //如果您的代码要求所有viewController继承某个公共基类，并且公共基类对UINavigationController统一做了某些处理，
    //或者对UINavigationController做了自己的扩展，并且这会导致无法正常集成，
    //或者其他原因导致使用第一种方式集成会有问题，这些情况下，建议您使用第二种方式集成。
    if (g_isDefault) {
        //集成方式一
        [self.navigationController pushViewController:sessionViewController animated:YES];
    }
    else {
        //集成方式二
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sessionViewController];
        sessionViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleBordered target:self action:@selector(onBack:)];
        [self presentViewController:nav animated:YES completion:nil];
    }
    
    if ([[QYSDK sharedSDK] customUIConfig].rightBarButtonItemColorBlackOrWhite == NO) {
        sessionViewController.navigationController.navigationBar.translucent = NO;
        NSDictionary * dict = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
        sessionViewController.navigationController.navigationBar.titleTextAttributes = dict;
        [sessionViewController.navigationController.navigationBar setBarTintColor:YSFRGB(0x62a8ea)];
    }
    else {
        sessionViewController.navigationController.navigationBar.translucent = YES;
        NSDictionary * dict = [NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
        sessionViewController.navigationController.navigationBar.titleTextAttributes = dict;
        [sessionViewController.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    }

}

- (void)onCleanCache:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清理缓存文件提示" message:@"缓存文件清理后将删除客户端接收过的所有文件，是否确认清理？" delegate:nil
                                              cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView ysf_showWithCompletion:^(NSInteger index) {
        [[QYSDK sharedSDK] cleanResourceCacheWithBlock:nil];
    }];
}

- (void)onClearUnreadCount
{
    [[[QYSDK sharedSDK] conversationManager] clearUnreadCount];
}

- (void)onDisplayCloseSessionButton
{
    [[QYSDK sharedSDK] customUIConfig].showCloseSessionEntry = ![[QYSDK sharedSDK] customUIConfig].showCloseSessionEntry;
}

- (void)onTapShopEntrance
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"你点击了商铺入口" delegate:nil
                                              cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView ysf_showWithCompletion:nil];
}

- (void)onTapSessionListEntrance
{
    QYSessionListViewController *vc = [QYSessionListViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onSessionList:(id)sender
{
    QYSessionListViewController *vc = [QYSessionListViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onBindAppkey:(id)sender
{
    QYBindAppkeyViewController *vc = [[QYBindAppkeyViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onCommonQuestionTemplateId:(id)sender
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"请输入常见问题模版ID"
                                                     message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)onInputGroupId:(id)sender
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"请输入分组ID"
                                                     message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"不开启机器人",@"开启机器人",nil];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)onInputStaffId:(id)sender
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"请输入客服ID"
                                                     message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"不开启机器人",@"开启机器人",nil];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)onInputRobotId:(id)sender
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"请输入机器人ID"
                                                     message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)onInputVipLevel:(id)sender
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"请输入vip等级"
                                                     message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)onInputAuthToken:(id)sender
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"请输入autoToken"
                                                     message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)onAddButton
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"请输入按钮文案"
                                                     message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[dialog textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [dialog show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if ([alertView.title isEqualToString:@"请输入autoToken"]) {
            NSString *authToken = [alertView textFieldAtIndex:0].text;
            g_authToken = authToken;
            [[QYSDK sharedSDK] setAuthToken:g_authToken];
        }
        
        int64_t longlongId = [[alertView textFieldAtIndex:0].text longLongValue];
        if ([alertView.title isEqualToString:@"请输入分组ID"]) {
            g_groupId = longlongId;
            g_staffId = 0;
            g_openRobotInShuntMode = NO;
        }
        else if ([alertView.title isEqualToString:@"请输入客服ID"]) {
            g_staffId = longlongId;
            g_groupId = 0;
            g_openRobotInShuntMode = NO;
        }
        else if ([alertView.title isEqualToString:@"请输入机器人ID"]) {
            g_robotId = longlongId;
        }
        else if ([alertView.title isEqualToString:@"请输入常见问题模版ID"]) {
            g_questionId = longlongId;
        }
        else if ([alertView.title isEqualToString:@"请输入vip等级"]) {
            g_vipLevel = (NSInteger)longlongId;
        }
        else if ([alertView.title isEqualToString:@"请输入按钮文案"]) {
            NSString *buttonText = [alertView textFieldAtIndex:0].text;
            QYButtonInfo *buttonInfo = [QYButtonInfo new];
            buttonInfo.title = buttonText;
            [g_buttonArray addObject:buttonInfo];
        }
    }
    else if (buttonIndex == 2) {
        int64_t longlongId = [[alertView textFieldAtIndex:0].text longLongValue];
        if ([alertView.title isEqualToString:@"请输入分组ID"]) {
            g_groupId = longlongId;
            g_staffId = 0;
        }
        else if ([alertView.title isEqualToString:@"请输入客服ID"]) {
            g_staffId = longlongId;
            g_groupId = 0;
        }
        g_openRobotInShuntMode = YES;
    }
}

+ (NSString*)showTime:(NSTimeInterval) msglastTime showDetail:(BOOL)showDetail
{
    //今天的时间
    NSDate * nowDate = [NSDate date];
    NSDate * msgDate = [NSDate dateWithTimeIntervalSince1970:msglastTime];
    NSString *result = nil;
    NSCalendarUnit components = (NSCalendarUnit)(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitHour | NSCalendarUnitMinute);
    NSDateComponents *nowDateComponents = [[NSCalendar currentCalendar] components:components fromDate:nowDate];
    NSDateComponents *msgDateComponents = [[NSCalendar currentCalendar] components:components fromDate:msgDate];
    NSDate *today = [[NSDate alloc] init];
    NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *yesterday = [today dateByAddingTimeInterval: -secondsPerDay];
    NSDateComponents *yesterdayDateComponents = [[NSCalendar currentCalendar] components:components fromDate:yesterday];
    
    NSInteger hour = msgDateComponents.hour;
    result = @"";
    
    if(nowDateComponents.year == msgDateComponents.year
       && nowDateComponents.month == msgDateComponents.month
       && nowDateComponents.day == msgDateComponents.day) //今天,hh:mm
    {
        result = [[NSString alloc] initWithFormat:@"%@ %zd:%02d",result,hour,(int)msgDateComponents.minute];
    }
    else if(yesterdayDateComponents.year == msgDateComponents.year
            && yesterdayDateComponents.month == msgDateComponents.month
            && yesterdayDateComponents.day == msgDateComponents.day)//昨天，昨天 hh:mm
    {
        result = showDetail?  [[NSString alloc] initWithFormat:@"昨天%@ %zd:%02d",result,hour,(int)msgDateComponents.minute] : @"昨天";
    }
    else if(nowDateComponents.year == msgDateComponents.year)//今年，MM/dd hh:mm
    {
        result = [NSString stringWithFormat:@"%02d/%02d %zd:%02d",(int)msgDateComponents.month,(int)msgDateComponents.day,msgDateComponents.hour,(int)msgDateComponents.minute];
    }
    else if((nowDateComponents.year != msgDateComponents.year))//跨年， YY/MM/dd hh:mm
    {
        NSString *day = [NSString stringWithFormat:@"%02d/%02d/%02d", (int)(msgDateComponents.year%100), (int)msgDateComponents.month, (int)msgDateComponents.day];
        result = showDetail? [day stringByAppendingFormat:@" %@ %zd:%02d",result,hour,(int)msgDateComponents.minute]:day;
    }
    return result;
}


@end
