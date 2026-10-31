import 'package:flutter/material.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';
import '../../utils/provider_scope.dart';
import '../../utils/formatters.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  final _ratingCommentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _ratingCommentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final prov = context.read<TicketProvider>();
    prov.addComment(widget.ticket.ticketId, text);
    _commentController.clear();
  }

  void _submitRating() {
    final prov = context.read<TicketProvider>();
    prov.rateTicket(
      widget.ticket.ticketId,
      _selectedRating,
      _ratingCommentController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cảm ơn bạn đã gửi đánh giá chất lượng dịch vụ!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketProv = context.watch<TicketProvider>();
    // Lấy ticket mới nhất từ provider
    final currentTicket = ticketProv.tickets.firstWhere(
      (t) => t.ticketId == widget.ticket.ticketId,
      orElse: () => widget.ticket,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(currentTicket.ticketCode),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh tiến độ 3 bước trực quan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tiến độ giải quyết sự cố',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildStep(
                              step: 1,
                              label: 'Chờ xử lý',
                              isPassed: currentTicket.statusStep >= 0,
                              isActive: currentTicket.statusStep == 0,
                            ),
                            _buildLine(isPassed: currentTicket.statusStep >= 1),
                            _buildStep(
                              step: 2,
                              label: 'Đang sửa',
                              isPassed: currentTicket.statusStep >= 1,
                              isActive: currentTicket.statusStep == 1,
                            ),
                            _buildLine(isPassed: currentTicket.statusStep >= 2),
                            _buildStep(
                              step: 3,
                              label: 'Hoàn thành',
                              isPassed: currentTicket.statusStep >= 2,
                              isActive: currentTicket.statusStep == 2,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chi tiết thông tin phiếu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppFormatters.priorityColor(currentTicket.priority).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentTicket.priority,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppFormatters.priorityColor(currentTicket.priority),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Danh mục: ${currentTicket.categoryName}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppFormatters.ticketStatusColor(currentTicket.status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentTicket.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppFormatters.ticketStatusColor(currentTicket.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentTicket.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentTicket.description,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Thời gian tạo:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(AppFormatters.dateTime(currentTicket.createdAt), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        if (currentTicket.technicianName != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Kỹ thuật viên:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              Text(currentTicket.technicianName!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Khung Đánh giá sao nếu hoàn thành
                  if (currentTicket.status == 'Hoàn thành') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                              SizedBox(width: 6),
                              Text('Đánh giá nghiệm thu sửa chữa',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (currentTicket.rating != null) ...[
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < currentTicket.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                            ),
                            if (currentTicket.ratingComment != null) ...[
                              const SizedBox(height: 6),
                              Text('Nhận xét: "${currentTicket.ratingComment}"',
                                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                            ],
                          ] else ...[
                            const Text('Bạn thấy kết quả sửa chữa thế nào?', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(5, (index) {
                                final star = index + 1;
                                return IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    star <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    setState(() => _selectedRating = star);
                                  },
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ratingCommentController,
                              decoration: InputDecoration(
                                hintText: 'Nhận xét thêm (nhanh nhẹn, sạch sẽ...)...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitRating,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Gửi đánh giá'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Trao đổi tin nhắn
                  const Text('Trao đổi với Kỹ thuật viên & Quản lý',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  ...currentTicket.comments.map((c) {
                    final isMe = c.isFromResident;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF2563EB) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isMe ? 14 : 2),
                            bottomRight: Radius.circular(isMe ? 2 : 14),
                          ),
                          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.authorName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.content,
                              style: TextStyle(fontSize: 13, color: isMe ? Colors.white : const Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                AppFormatters.dateTime(c.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white60 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn trao đổi...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _sendComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required int step, required String label, required bool isPassed, required bool isActive}) {
    final color = isActive
        ? const Color(0xFF2563EB)
        : (isPassed ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1));

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: isPassed && !isActive
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$step',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine({required bool isPassed}) {
    return Container(
      width: 24,
      height: 2,
      color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
    );
  }
}
