import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';

class VnpayWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderNumber;

  const VnpayWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderNumber,
  });

  @override
  State<VnpayWebviewScreen> createState() => _VnpayWebviewScreenState();
}

class _VnpayWebviewScreenState extends State<VnpayWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _progress = 0;
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
            _checkRedirect(url);
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkRedirect(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkRedirect(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('[VNPay WebView] error: ${error.errorCode} - ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _checkRedirect(String url) {
    if (_hasRedirected) return true;

    // Khi VNPay chuyển hướng về endpoint return URL của backend (/payments/vnpay/return)
    if (url.contains('/payments/vnpay/return')) {
      _hasRedirected = true;
      // Đóng WebView và trả về true (đã qua cổng VNPay, cần kiểm tra kết quả)
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    }
    return false;
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sand50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Rời cổng thanh toán?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Giao dịch thanh toán chưa hoàn tất. '
          'Nếu thoát bây giờ, bạn có thể thanh toán lại trong vòng 15 phút tại mục Chi tiết đơn hàng.',
          style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở LẠI TIẾP TỤC', style: TextStyle(color: AppColors.clay500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('THOÁT RA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (!context.mounted) return;
        if (shouldExit) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CỔNG THANH TOÁN VNPAY',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Đơn #${widget.orderNumber}',
                style: const TextStyle(fontSize: 11, color: AppColors.mute),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Hủy thanh toán',
            onPressed: () async {
              final shouldExit = await _showExitDialog();
              if (!context.mounted) return;
        if (shouldExit) {
                Navigator.of(context).pop(false);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Tải lại trang',
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: AppColors.sand200,
                    color: AppColors.clay500,
                    minHeight: 2,
                  ),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
