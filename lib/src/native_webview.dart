import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native_webview_event.dart';

class FaiWebViewWidget extends StatefulWidget {
  //加载的网页 URL
  String url;

  //加载 完整html 文件数据 如 <html><head> .... .. </head></html>
  String htmlData;

  //加载 html 代码块 如<p> .... </p>
  String htmlBlockData;

  //日志输出
  bool isLog = false;

  bool htmlImageIsClick = false;

  //回调
  Function(int code, String message, dynamic content) callback;
  Function(int index, String url,String images) imageCallBack;

  FaiWebViewWidget(
      {this.callback, this.url, this.htmlData, this.htmlBlockData, this.isLog,this.htmlImageIsClick,this.imageCallBack});

  @override
  State<StatefulWidget> createState() {
    viewState = new AndroidWebViewState(callback,
        url: url,
        htmlBlockData: htmlBlockData,
        isLog: isLog,
        htmlImageIsClick: htmlImageIsClick,
        imageCallBack: imageCallBack,
        htmlData: htmlData);
    return viewState;
  }

  AndroidWebViewState viewState;

  void refresh({String htmlData, String htmlBlockData, String htmlUrl}) {
    NativeEventMessage.getDefault().post({
      "code": 100,
      "htmlUrl": htmlUrl,
      "htmlBlockData": htmlBlockData,
      "htmlData": htmlData,
    });
  }
}

class AndroidWebViewState extends State<FaiWebViewWidget> {
  //加载的网页 URL
  String url;
  //自定义网页中的所有的图片的点击事件处理
  bool htmlImageIsClick = false;
  //加载 完整html 文件数据 如 <html><head> .... .. </head></html>
  String htmlData;
  //加载 html 代码块 如<p> .... </p>
  String htmlBlockData;
  //日志输出
  bool isLog = false;
  int viewId = -1;
  MethodChannel _channel;
  //回调
  Function(int code, String message, dynamic content) callback;
  Function(int index, String url,String images) imageCallBack;
  AndroidWebViewState(this.callback,
      {this.url, this.htmlData, this.htmlBlockData, this.isLog,this.htmlImageIsClick=false,this.imageCallBack});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    NativeEventMessage.getDefault().register((event) {
      int code = event["code"];
      if (code == 100) {
        String htmlData = event["htmlData"];
        String htmlBlockData = event["htmlBlockData"];
        String htmlUrl = event["htmlUrl"];

        if (htmlData != null) {
          this.htmlData = htmlData;
        }
        if (htmlBlockData != null) {
          this.htmlBlockData = htmlBlockData;
        }
        if (htmlUrl != null) {
          this.url = htmlUrl;
        }
        refresh();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
   // NativeEventMessage.getDefault().unregister();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      //ios相关代码
      return buildIosWebView();
    } else if (Platform.isAndroid) {
      //android相关代码
      return buildAndroidWebView();
    } else {
      return Container();
    }
  }

  /**
   * 设置消息监听
   * code
   * 201 测量webview 成功
   * 202 JS调用
   * 301 滑动到顶部
   * 302 向下滑动
   * 303	向上滑动
   * 304 滑动到底部
   * 401 webview 开始加载
   * 402 webview 加载完成
   * 403 webview html中日志输出
   * 404 webview 加载出错
   *
   * @param map
   */
  Future<dynamic> nativeMessageListener() async {
    _channel.setMethodCallHandler((resultCall) {
      //处理原生 Android iOS 发送过来的消息
      MethodCall call = resultCall;
      String method = call.method;
      Map arguments = call.arguments;

      int code = arguments["code"];
      String message = arguments["message"];
      dynamic content = arguments["content"];
      print("native_webview:code-> " +
          code.toString() +
          " ; message:" +
          message.toString() +
          "; content " +
          content.toString());

      if(code==203){
        int index = arguments["index"];
        String url = arguments["url"];
        String urls = arguments["urls"];
        if(imageCallBack!=null){
          imageCallBack(index,url,urls);
        }

      }

      if (callback != null) {
        print("native_webview callback" );
        callback(code, message, content);
      }else{
        print("native_webview callback is null " );
      }
    });
  }

  void loadUrl() async {
    _channel.invokeMethod('load', {
      "url": url,
      "htmlData": htmlData,
      "htmlBlockData": htmlBlockData,
    });
  }
  void reLoad() async {
    _channel.invokeMethod('reload');
  }

  Widget buildAndroidWebView() {
    return AndroidView(
      //调用标识
      viewType: "com.flutter_to_native_webview",
      //参数初始化
      creationParams: {
        //调用view参数标识
        "isScrollListen": true,
        "htmlImageIsClick":htmlImageIsClick
      },
      //参数的编码方式
      creationParamsCodec: const StandardMessageCodec(),
      //webview 创建后的回调
      onPlatformViewCreated: (id) {
        viewId = id;
        print("onPlatformViewCreated " + id.toString());
        //创建通道
        _channel = new MethodChannel('com.flutter_to_native_webview_$viewId');
        //设置监听
        nativeMessageListener();
        //加载页面
        loadUrl();
      },
    );
  }

  Widget buildIosWebView() {
    return UiKitView(
      //调用标识
      viewType: "com.flutter_to_native_webview",
      //参数初始化
      creationParams: {
        //调用view参数标识
        "isScrollListen": true,
      },
      //参数的编码方式
      creationParamsCodec: const StandardMessageCodec(),
      //webview 创建后的回调
      onPlatformViewCreated: (id) {
        viewId = id;
        print("onPlatformViewCreated " + id.toString());
        //创建通道
        _channel = new MethodChannel('com.flutter_to_native_webview_$viewId');
        //设置监听
        nativeMessageListener();
        //加载页面
        loadUrl();
      },
    );
  }

  void refresh() {
    reLoad();
  }
}
