import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin/admin_base.dart';

class AdminErrorBar extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const AdminErrorBar({super.key, this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(fontSize: 12.5, color: Colors.red.shade800, height: 1.35),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: Colors.red.shade700,
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  final String label;
  final int tone;

  const AdminStatusChip(this.label, {super.key, this.tone = 0});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case 1:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 2:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFF8D6E00);
        break;
      case 3:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      default:
        bg = AppColors.sand100;
        fg = AppColors.mute;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg, letterSpacing: 0.2),
      ),
    );
  }
}

class AdminPagingBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalElements;
  final bool isLoading;
  final ValueChanged<int> onGoToPage;

  const AdminPagingBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.isLoading,
    required this.onGoToPage,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text('$totalElements bản ghi',
              style: const TextStyle(fontSize: 12, color: AppColors.mute)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: (page > 0 && !isLoading) ? () => onGoToPage(page - 1) : null,
          ),
          Text(
            'Trang ${page + 1}/$totalPages · $totalElements bản ghi',
            style: const TextStyle(fontSize: 12, color: AppColors.mute),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: (page < totalPages - 1 && !isLoading) ? () => onGoToPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AdminEmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.sand300),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.ink),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> adminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'XOÁ',
  bool destructive = true,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Thôi'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? Colors.red.shade700 : AppColors.clay500,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

void adminToast(BuildContext context, String message, {bool success = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.success : Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: success ? 2 : 4),
    ),
  );
}

Future<bool> adminRun(
  BuildContext context,
  AdminProviderBase provider,
  Future<bool> Function() action, {
  required String successMessage,
}) async {
  final ok = await action();
  if (!context.mounted) return ok;
  adminToast(
    context,
    ok ? successMessage : (provider.errorMessage ?? 'Thao tác không thành công.'),
    success: ok,
  );
  return ok;
}

class AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;

  const AdminField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.obscure = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: obscure ? 1 : maxLines,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: validator ??
            (required
                ? (value) => (value == null || value.trim().isEmpty) ? 'Không được để trống' : null
                : null),
      ),
    );
  }
}
