import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../core/network/api_client.dart';
import '../bloc/fcm_bloc.dart';
import '../bloc/fcm_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _showSplash = true;
  DateTime? _lastBackPress;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Content overlay state
  WebViewController? _contentController;
  String _contentTitle = '';
  bool _contentLoading = false;
  bool _contentCanGoBack = false;

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
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
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
      ..loadRequest(Uri.parse('https://damo-web.vercel.app/search'));

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

    late final WebViewController contentCtrl;
    if (Platform.isIOS) {
      final contentParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
      contentCtrl = WebViewController.fromPlatformCreationParams(contentParams);
    } else {
      contentCtrl = WebViewController();
    }

    contentCtrl
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _contentLoading = true);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _contentLoading = false);
            if (_contentTitle.isEmpty) {
              final pageTitle = await _contentController?.getTitle();
              if (pageTitle != null && pageTitle.isNotEmpty && mounted) {
                setState(() => _contentTitle = pageTitle);
              }
            }
            // Update canGoBack state for iOS edge-swipe gesture
            final canGoBack = await _contentController?.canGoBack() ?? false;
            if (mounted) setState(() => _contentCanGoBack = canGoBack);
          },
        ),
      )
      ..setUserAgent('$defaultAgent DAMO-App/1.0')
      ..loadRequest(Uri.parse(url));

    // Enable iOS swipe back/forward gesture for content WebView
    if (contentCtrl.platform is WebKitWebViewController) {
      (contentCtrl.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    if (mounted) {
      setState(() {
        _contentController = contentCtrl;
        _contentTitle = title;
        _contentLoading = true;
        _contentCanGoBack = false;
      });
    }
  }

  void _closeContentOverlay() {
    if (mounted) {
      setState(() {
        _contentController = null;
        _contentTitle = '';
        _contentLoading = false;
      });
    }
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
            Uri.parse('https://damo-web.vercel.app/profile'),
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

  Future<bool> _onWillPop() async {
    // Content overlay is open: go back in history or close it
    if (_contentController != null) {
      if (await _contentController!.canGoBack()) {
        _contentController!.goBack();
      } else {
        _closeContentOverlay();
      }
      return false;
    }

    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      return true;
    }

    _lastBackPress = now;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('한 번 더 누르면 앱이 종료됩니다'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
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
                  FadeTransition(
                    opacity: ReverseAnimation(_fadeAnimation),
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'DAMO',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '모든 콘텐츠, 하나로',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF86868B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 40),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Content overlay WebView
                if (_contentController != null)
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // AppBar
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE5E5E7), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1d1d1f)),
                                onPressed: _closeContentOverlay,
                              ),
                              Expanded(
                                child: Text(
                                  _contentTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1d1d1f),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 48), // Balance for back button
                            ],
                          ),
                        ),
                        // Loading indicator
                        if (_contentLoading)
                          const LinearProgressIndicator(
                            color: Color(0xFF6366F1),
                            backgroundColor: Color(0xFFE5E5E7),
                            minHeight: 2,
                          ),
                        // Content WebView
                        Expanded(
                          child: Stack(
                            children: [
                              WebViewWidget(controller: _contentController!),
                              // iOS: left-edge swipe to close overlay when no history
                              if (Platform.isIOS && !_contentCanGoBack)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 20,
                                  child: GestureDetector(
                                    onHorizontalDragEnd: (details) {
                                      if (details.primaryVelocity != null &&
                                          details.primaryVelocity! > 0) {
                                        _closeContentOverlay();
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
