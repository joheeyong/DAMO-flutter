import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RedditProxyService {
  final WebViewController _controller;

  RedditProxyService(this._controller);

  Future<void> handleRequest(String message) async {
    String? callback;
    try {
      final data = jsonDecode(message);
      final url = data['url'] as String;
      callback = data['callback'] as String;

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(url));
      request.headers
          .set('User-Agent', 'web:com.damo.app:v1.0.0 (by /u/damo_search)');
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final statusCode = response.statusCode;
      final body = await response.transform(utf8.decoder).join();
      client.close();

      debugPrint(
          'Reddit proxy: status=$statusCode, body=${body.length} bytes');

      // If not JSON (e.g. 403 HTML block page), return empty
      if (statusCode != 200 || !body.trimLeft().startsWith('{')) {
        debugPrint('Reddit proxy: non-JSON response, returning empty');
        await _controller.runJavaScript(
            "if(window['$callback'])window['$callback']('{\"data\":{\"children\":[]}}');");
        return;
      }

      // Transfer data via base64 chunks to avoid JS eval size limits
      final b64 = base64Encode(utf8.encode(body));
      const chunkSize = 32000;
      await _controller.runJavaScript("window._rb='';");
      for (var i = 0; i < b64.length; i += chunkSize) {
        final end =
            (i + chunkSize > b64.length) ? b64.length : i + chunkSize;
        await _controller
            .runJavaScript("window._rb+='${b64.substring(i, end)}';");
      }
      await _controller.runJavaScript(
          "try{var b=atob(window._rb),u=new Uint8Array(b.length);"
          "for(var i=0;i<b.length;i++)u[i]=b.charCodeAt(i);"
          "var s=new TextDecoder().decode(u);"
          "if(window['$callback'])window['$callback'](s);"
          "}catch(e){if(window['$callback'])window['$callback']('{\"data\":{\"children\":[]}}');}"
          "delete window._rb;");
    } catch (e) {
      debugPrint('Reddit proxy error: $e');
      if (callback != null) {
        try {
          await _controller.runJavaScript(
              "if(window['$callback'])window['$callback']('{\"data\":{\"children\":[]}}');");
        } catch (_) {}
      }
    }
  }
}
