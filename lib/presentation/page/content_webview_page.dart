import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentWebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const ContentWebViewPage({
    super.key,
    required this.url,
    this.title = '',
  });

  @override
  State<ContentWebViewPage> createState() => _ContentWebViewPageState();
}

class _ContentWebViewPageState extends State<ContentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _isLoading = false);
            // Update title from page if not provided
            if (_currentTitle.isEmpty) {
              final title = await _controller.getTitle();
              if (title != null && title.isNotEmpty && mounted) {
                setState(() => _currentTitle = title);
              }
            }
          },
        ),
      )
      ..setUserAgent('DAMO-App/1.0 Flutter')
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1d1d1f)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _currentTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1d1d1f),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E5E7),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF6366F1),
              backgroundColor: Color(0xFFE5E5E7),
              minHeight: 2,
            ),
        ],
      ),
    );
  }
}
