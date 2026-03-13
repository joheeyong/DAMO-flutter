import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/reddit_proxy_service.dart';
import '../bloc/fcm_bloc.dart';
import '../bloc/fcm_state.dart';
import '../widget/content_overlay.dart';
import '../widget/splash_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final WebViewController _controller;
  late final RedditProxyService _redditProxyService;
  bool _showSplash = true;
  bool _isDarkMode = false;
  DateTime? _lastBackPress;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final GlobalKey<ContentOverlayState> _contentOverlayKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _updateSystemUI(false);

    // Fallback: hide splash after 10 seconds regardless
    Future.delayed(const Duration(seconds: 10), () {
      if (_showSplash && mounted) {
        _dismissSplash();
      }
    });

    // Handle FCM notification taps
    _setupFcmNavigation();

    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'DamoReady',
        onMessageReceived: (message) {
          _dismissSplash();
        },
      )
      ..addJavaScriptChannel(
        'DamoAuth',
        onMessageReceived: (message) {
          _registerFcmWithAuth(message.message);
        },
      )
      ..addJavaScriptChannel(
        'DamoTheme',
        onMessageReceived: (message) {
          final dark = message.message == 'dark';
          if (mounted && dark != _isDarkMode) {
            setState(() => _isDarkMode = dark);
            _updateSystemUI(dark);
          }
        },
      )
      ..addJavaScriptChannel(
        'DamoReddit',
        onMessageReceived: (message) {
          _redditProxyService.handleRequest(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            // Allow iframe loads (e.g. YouTube embed for Shorts preview)
            if (!request.isMainFrame) {
              return NavigationDecision.navigate;
            }
            // Allow our own domain and OAuth flows
            if (url.contains('damo-web.vercel.app') ||
                url.contains('accounts.google.com') ||
                url.contains('nid.naver.com') ||
                url.contains('kauth.kakao.com') ||
                url.contains('naver.com/oauth') ||
                url.contains('localhost')) {
              return NavigationDecision.navigate;
            }
            // External URL: intercept and open in overlay WebView
            _openContentOverlay(url, '');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('${AppConstants.webAppUrl}/search'));

    _redditProxyService = RedditProxyService(_controller);

    // Set user agent: default + DAMO-App identifier
    _controller.getUserAgent().then((defaultAgent) {
      _controller.setUserAgent('${defaultAgent ?? ''} DAMO-App/1.0');
    });

    // Enable iOS swipe back/forward navigation gesture
    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
  }

  Future<void> _openContentOverlay(String url, String title) async {
    final defaultAgent = await _controller.getUserAgent() ?? '';
    _contentOverlayKey.currentState
        ?.open(url, title, userAgent: defaultAgent);
  }

  void _setupFcmNavigation() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleFcmAction(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleFcmAction(message.data);
    });
  }

  void _handleFcmAction(Map<String, dynamic> data) {
    final action = data['action'];
    if (action == 'open_interests') {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.loadRequest(
            Uri.parse('${AppConstants.webAppUrl}/profile'),
          );
        }
      });
    }
  }

  Future<void> _registerFcmWithAuth(String jwt) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      final platform = Platform.isIOS ? 'ios' : 'android';
      final apiClient = ApiClient();
      await apiClient.post('/api/fcm/register', body: {
        'token': fcmToken,
        'platform': platform,
      }, headers: {
        'Authorization': 'Bearer $jwt',
      });
      debugPrint('FCM token registered with user auth');
    } catch (e) {
      debugPrint('FCM auth registration failed: $e');
    }
  }

  void _updateSystemUI(bool dark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          dark ? AppConstants.darkBackground : Colors.white,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
    ));
  }

  void _dismissSplash() {
    if (!_showSplash || !mounted) return;
    _fadeController.forward().then((_) {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;

    // Content overlay is open: go back in history or close it
    final overlayState = _contentOverlayKey.currentState;
    if (overlayState != null && overlayState.isOpen) {
      final handled = await overlayState.handleBackNavigation();
      if (handled) return;
    }

    if (await _controller.canGoBack()) {
      _controller.goBack();
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    _lastBackPress = now;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\ud55c \ubc88 \ub354 \ub204\ub974\uba74 \uc571\uc774 \uc885\ub8cc\ub429\ub2c8\ub2e4'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor:
            _isDarkMode ? AppConstants.darkBackground : Colors.white,
        body: BlocListener<FcmBloc, FcmState>(
          listenWhen: (prev, curr) => prev.lastMessage != curr.lastMessage,
          listener: (context, state) {
            if (state.lastMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${state.lastMessage!.title}: ${state.lastMessage!.body}',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                // Main WebView (always alive)
                WebViewWidget(controller: _controller),

                // Splash screen
                if (_showSplash)
                  SplashOverlay(
                    isDarkMode: _isDarkMode,
                    fadeAnimation: _fadeAnimation,
                  ),

                // Content overlay WebView
                ContentOverlay(
                  key: _contentOverlayKey,
                  isDarkMode: _isDarkMode,
                  onClose: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
