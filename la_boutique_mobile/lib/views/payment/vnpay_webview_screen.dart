import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/payment_provider.dart';

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
  WebViewController? _controller;
  Timer? _webPollTimer;
  bool _isLoading = true;
  int _progress = 0;
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _startWebPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openVnpayInBrowser();
      });
    } else {
      _initWebView();
    }
  }

  @override
  void dispose() {
    _webPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openVnpayInBrowser() async {
    try {
      final uri = Uri.parse(widget.paymentUrl);
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } catch (e) {
      debugPrint('[VNPay Web] Error launching URL: $e');
    }
  }

  void _startWebPolling() {
    _webPollTimer?.cancel();
    // Định kỳ poll mỗi 2.5s kiểm tra xem khách đã hoàn tất thanh toán trên tab VNPay chưa
    _webPollTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final paymentProv = context.read<PaymentProvider>();
      final status = await paymentProv.fetchPaymentStatus(widget.orderNumber);
      if (!mounted) return;
      if (status != null && !status.isPending) {
        timer.cancel();
        Navigator.of(context).pop(true);
      }
    });
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

  Widget _buildWebPaymentView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: AppColors.sand200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.clay500.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    size: 38,
                    color: AppColors.clay500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Thanh toán VNPay Sandbox',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã đơn hàng: #${widget.orderNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mute,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sand50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sand200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.clay500),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cổng thanh toán VNPay đã được mở trong một tab mới của trình duyệt. Vui lòng thao tác thanh toán tại tab đó.',
                              style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.clay500),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hệ thống đang tự động lắng nghe kết quả thanh toán...',
                              style: TextStyle(fontSize: 12, color: AppColors.mute, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.clay500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: const Text(
                      'TÔI ĐÃ HOÀN TẤT THANH TOÁN',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                    onPressed: () {
                      _webPollTimer?.cancel();
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.sand300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(
                      'MỞ LẠI TRANG VNPAY (NẾU BỊ CHẶN POPUP)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    onPressed: _openVnpayInBrowser,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final shouldExit = await _showExitDialog();
                    if (!mounted) return;
                    if (shouldExit) {
                      _webPollTimer?.cancel();
                      Navigator.of(context).pop(false);
                    }
                  },
                  child: const Text(
                    'Hủy hoặc thanh toán sau',
                    style: TextStyle(color: AppColors.mute, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          _webPollTimer?.cancel();
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
                _webPollTimer?.cancel();
                Navigator.of(context).pop(false);
              }
            },
          ),
          actions: [
            if (!kIsWeb)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Tải lại trang',
                onPressed: () => _controller?.reload(),
              ),
          ],
          bottom: (!kIsWeb && _isLoading)
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
        body: kIsWeb
            ? _buildWebPaymentView()
            : (_controller != null
                ? WebViewWidget(controller: _controller!)
                : const SizedBox.shrink()),
      ),
    );
  }
}
