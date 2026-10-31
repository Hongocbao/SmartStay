import 'package:flutter/material.dart';

class AppFormatters {
  static String currency(num amount) {
    final isNegative = amount < 0;
    final digits = amount.abs().round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()} đ';
  }

  static String number(num value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  static String date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static String dateTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm - ${AppFormatters.date(date)}';
  }

  static String time(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String monthYear(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    return '$m/${date.year}';
  }

  static Color invoiceStatusColor(String status) {
    switch (status) {
      case 'Đã thanh toán':
        return const Color(0xFF16A34A);
      case 'Thanh toán một phần':
        return const Color(0xFF2563EB);
      case 'Đã phát hành':
        return const Color(0xFFD97706);
      case 'Quá hạn':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color ticketStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF16A34A);
      case 'Đang sửa':
        return const Color(0xFF2563EB);
      case 'Chờ xử lý':
        return const Color(0xFFD97706);
      case 'Từ chối':
      case 'Đã hủy':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color priorityColor(String priority) {
    switch (priority) {
      case 'Khẩn cấp':
        return const Color(0xFFDC2626);
      case 'Cao':
        return const Color(0xFFEA580C);
      case 'Trung bình':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class Formatters {
  static String formatCurrency(num amount) => AppFormatters.currency(amount);
  static String formatDate(DateTime date) => AppFormatters.date(date);
  static String formatDateTime(DateTime date) => AppFormatters.dateTime(date);
  static String formatTime(DateTime date) => AppFormatters.time(date);
}
