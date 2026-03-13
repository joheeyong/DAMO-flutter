import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../core/constants/app_constants.dart';

class ContentOverlay extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onClose;

  const ContentOverlay({
    super.key,
    required this.isDarkMode,
    required this.onClose,
  });

  @override
  State<ContentOverlay> createState() => ContentOverlayState();
}

class ContentOverlayState extends State<ContentOverlay>
    with TickerProviderStateMixin {
  WebViewController? _contentController;
  String _contentTitle = '';
  bool _contentLoading = false;
  bool _contentCanGoBack = false;

  double _overlaySlideOffset = 0.0;
  late final AnimationController _slideController;
  Animation<double>? _slideAnimation;

  bool get isOpen => _contentController != null;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_slideAnimation != null && mounted) {
          setState(() => _overlaySlideOffset = _slideAnimation!.value);
        }
      });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> open(String url, String title,
      {required String userAgent}) async {
    late final WebViewController contentCtrl;
    if (Platform.isIOS) {
      final contentParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      contentCtrl =
          WebViewController.fromPlatformCreationParams(contentParams);
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
            final canGoBack = await _contentController?.canGoBack() ?? false;
            if (mounted) setState(() => _contentCanGoBack = canGoBack);
          },
        ),
      )
      ..setUserAgent('$userAgent DAMO-App/1.0')
      ..loadRequest(Uri.parse(url));

    if (contentCtrl.platform is WebKitWebViewController) {
      (contentCtrl.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    if (mounted) {
      _slideController.reset();
      _slideAnimation = null;
      setState(() {
        _overlaySlideOffset = 0;
        _contentController = contentCtrl;
        _contentTitle = title;
        _contentLoading = true;
        _contentCanGoBack = false;
      });
    }
  }

  void close() {
    if (mounted) {
      _slideController.reset();
      _slideAnimation = null;
      setState(() {
        _overlaySlideOffset = 0;
        _contentController = null;
        _contentTitle = '';
        _contentLoading = false;
      });
    }
    widget.onClose();
  }

  Future<bool> handleBackNavigation() async {
    if (_contentController == null) return false;
    if (await _contentController!.canGoBack()) {
      _contentController!.goBack();
    } else {
      close();
    }
    return true;
  }

  void _onOverlayDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    setState(() {
      _overlaySlideOffset =
          (_overlaySlideOffset + details.delta.dx)
              .clamp(0.0, MediaQuery.of(context).size.width);
    });
  }

  void _onOverlayDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.primaryVelocity ?? 0;

    if (velocity > 300 || _overlaySlideOffset > screenWidth * 0.35) {
      _slideAnimation = Tween<double>(
        begin: _overlaySlideOffset,
        end: screenWidth,
      ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
      _slideController.forward(from: 0).then((_) {
        close();
        _overlaySlideOffset = 0;
        _slideController.reset();
      });
    } else {
      _slideAnimation = Tween<double>(
        begin: _overlaySlideOffset,
        end: 0,
      ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
      _slideController.forward(from: 0).then((_) {
        _slideController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_contentController == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Dim background as overlay slides
        if (_overlaySlideOffset > 0)
          Container(
            color: Colors.black.withValues(
              alpha: 0.3 *
                  (1 -
                      _overlaySlideOffset /
                          MediaQuery.of(context).size.width),
            ),
          ),
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(_overlaySlideOffset, 0),
            child: Container(
              color: widget.isDarkMode
                  ? AppConstants.darkBackground
                  : Colors.white,
              child: Column(
                children: [
                  // AppBar
                  Container(
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? AppConstants.darkBackground
                          : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: widget.isDarkMode
                              ? AppConstants.darkBorder
                              : const Color(0xFFE5E5E7),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              size: 20,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1d1d1f)),
                          onPressed: close,
                        ),
                        Expanded(
                          child: Text(
                            _contentTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1d1d1f),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
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
                    child: WebViewWidget(controller: _contentController!),
                  ),
                ],
              ),
            ),
          ),
        ),
        // iOS: left-edge swipe gesture to dismiss overlay when no history
        if (Platform.isIOS && !_contentCanGoBack)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 24,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _onOverlayDragUpdate,
              onHorizontalDragEnd: _onOverlayDragEnd,
            ),
          ),
      ],
    );
  }
}
