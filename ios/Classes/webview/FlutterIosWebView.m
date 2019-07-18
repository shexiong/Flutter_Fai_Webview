//
//  FlutterIosWebView.m
//  Runner
//
//  Created by  androidlongs on 2019/7/18.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "FlutterIosWebView.h"

@interface FlutterIosWebView() <UIWebViewDelegate,UIScrollViewDelegate>

@end

@implementation FlutterIosWebView{
    //FlutterIosTextLabel 创建后的标识
    int64_t _viewId;
    UIWebView * _webView;
    //消息回调
    FlutterMethodChannel* _channel;
}

-(instancetype)initWithWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger{
    if ([super init]) {
        if (frame.size.width==0) {
            frame=CGRectMake(frame.origin.x, frame.origin.y, [UIScreen mainScreen].bounds.size.width, 22);
        }
        _webView =[[UIWebView alloc] initWithFrame:frame];
        _webView.delegate=self;
        _webView.scrollView.delegate = self;
        _viewId = viewId;

        //接收 初始化参数
        NSDictionary *dic = args;
        NSString *content = dic[@"content"];


        // 注册flutter 与 ios 通信通道
        NSString* channelName = [NSString stringWithFormat:@"com.flutter_to_native_webview_%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        __weak __typeof__(self) weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall *  call, FlutterResult  result) {
            [weakSelf onMethodCall:call result:result];
        }];

    }
    return self;

}

-(void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    if ([[call method] isEqualToString:@"load"]) {
        //获取参数
        NSDictionary *dict = call.arguments;
        NSString *url = dict[@"url"];
        NSURL *requestUrl = [NSURL URLWithString:url];
        NSURLRequest *request = [NSURLRequest requestWithURL:requestUrl];
        [_webView loadRequest:request];

    }else{
        //其他方法的回调
    }
}


- (nonnull UIView *)view {
    return _webView;
}

//web view 代理相关
// Sent before a web view begins loading a frame.请求发送前都会调用该方法,返回NO则不处理这个请求
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    return YES;
}
// Sent after a web view starts loading a frame. 请求发送之后开始接收响应之前会调用这个方法
- (void)webViewDidStartLoad:(UIWebView *)webView{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:401] forKey:@"code"];
    [dict setObject:@"webview 开始加载" forKey:@"message"];
    [dict setObject:@"success" forKey:@"content"];

    [self messagePost:dict];
}

// Sent after a web view finishes loading a frame. 请求发送之后,并且服务器已经返回响应之后调用该方法
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:402] forKey:@"code"];
    [dict setObject:@"webview 加载完成" forKey:@"message"];
    [dict setObject:@"success" forKey:@"content"];

    [self messagePost:dict];
}

// Sent if a web view failed to load a frame. 网页请求失败则会调用该方法
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:404] forKey:@"code"];
    [dict setObject:@"webview 加载出错" forKey:@"message"];
    [dict setObject:@"err" forKey:@"content"];

    [self messagePost:dict];
}

// 开始
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

}

// 结束
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

}

int _lastPosition;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{

    int currentPostion = scrollView.contentOffset.y;
    if (currentPostion - _lastPosition > 25) {
        _lastPosition = currentPostion;
        NSLog(@"ScrollUp now");
        //向上滑动
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSNumber numberWithInt:303] forKey:@"code"];
        [dict setObject:@"webview 向上滑动" forKey:@"message"];
        [dict setObject:@"scroll " forKey:@"content"];

        [self messagePost:dict];
    }
    else if (_lastPosition - currentPostion > 25)
    {
        _lastPosition = currentPostion;
        NSLog(@"ScrollDown now");
        //向下滑动
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSNumber numberWithInt:302] forKey:@"code"];
        [dict setObject:@"webview 向下滑动" forKey:@"message"];
        [dict setObject:@"scroll" forKey:@"content"];

        [self messagePost:dict];
    }



}


-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)conOffset{

    if (velocity.y > 0.0f) {
        //不在顶部
        NSLog(@"ScrollDown now");
        CGPoint offset = scrollView.contentOffset;
        CGRect bounds = scrollView.bounds;
        CGSize size = scrollView.contentSize;
        UIEdgeInsets inset = scrollView.contentInset;
        CGFloat currentOffset = offset.y + bounds.size.height - inset.bottom;
        CGFloat maximumOffset = size.height;
        //当currentOffset与maximumOffset的值相等时，说明scrollview已经滑到底部了。
        if(currentOffset>=maximumOffset){
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:[NSNumber numberWithInt:304] forKey:@"code"];
            [dict setObject:@"webview 滑动到了底部" forKey:@"message"];
            [dict setObject:@"scroll" forKey:@"content"];
            [self messagePost:dict];
        }


    }else if (velocity.y < - 0.0f ){
       //在顶部
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSNumber numberWithInt:301] forKey:@"code"];
        [dict setObject:@"webview 滑动到了顶部" forKey:@"message"];
        [dict setObject:@"scroll" forKey:@"content"];

        [self messagePost:dict];

    }else{
        //在中间
    }

}





-(void) messagePost:(NSDictionary *)dict{

    dispatch_async(dispatch_get_main_queue(), ^{
        // UI更新代码
        [self->_channel invokeMethod:@"ios" arguments:dict];
    });
}
@end