import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../bloc/fcm_bloc.dart';
import '../bloc/fcm_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            // Allow all navigation within damo-web
            if (request.url.contains('damo-web.vercel.app') ||
                request.url.contains('accounts.google.com') ||
                request.url.contains('nid.naver.com') ||
                request.url.contains('naver.com/oauth') ||
                request.url.contains('googleapis.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent('DAMO-App/1.0 Flutter')
      ..loadRequest(Uri.parse('https://damo-web.vercel.app/search'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
