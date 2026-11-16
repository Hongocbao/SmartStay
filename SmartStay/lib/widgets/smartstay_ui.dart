import 'package:flutter/material.dart';
import '../theme/smartstay_theme.dart';

/// Hiển thị thông báo Toast/Snackbar mượt mà, đồng nhất theo Design System.
void showSmartStayToast(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  if (!context.mounted) return;
  final bg = isError
      ? SmartStayColors.danger
      : (isSuccess ? SmartStayColors.success : SmartStayColors.primary);
  final icon = isError
      ? Icons.error_outline_rounded
      : (isSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Khối Shimmer Skeleton Loading nhẹ, không phụ thuộc thư viện ngoài.
class SmartStayShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SmartStayShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<SmartStayShimmerBox> createState() => _SmartStayShimmerBoxState();
}

class _SmartStayShimmerBoxState extends State<SmartStayShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(baseColor, highlightColor, _controller.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Skeleton Loading cho màn hình Dashboard / Home khi đang đồng bộ dữ liệu.
class SmartStayDashboardSkeleton extends StatelessWidget {
  const SmartStayDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SmartStayShimmerBox(height: 108, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SmartStayShimmerBox(height: 108, borderRadius: 16)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SmartStayShimmerBox(height: 108, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SmartStayShimmerBox(height: 108, borderRadius: 16)),
            ],
          ),
          SizedBox(height: 20),
          SmartStayShimmerBox(height: 210, borderRadius: 16),
          SizedBox(height: 16),
          SmartStayShimmerBox(height: 120, borderRadius: 16),
        ],
      ),
    );
  }
}

/// Trạng thái trống (Empty State) chuẩn hóa có icon minh họa và nút hành động.
class SmartStayEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SmartStayEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? SmartStayColors.primary.withValues(alpha: 0.2)
                    : SmartStayColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: SmartStayColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? SmartStayColors.textPrimaryDark
                    : SmartStayColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? SmartStayColors.textSecondaryDark
                    : SmartStayColors.textSecondaryLight,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmartStayColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
