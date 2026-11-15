import 'package:flutter/material.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/provider_scope.dart';
import '../../utils/formatters.dart';
import '../../widgets/ai_floating_bubble.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  String _activeToolBadge = 'Trạng thái: Chờ lệnh';
  Color _activeToolColor = const Color(0xFF64748B);
  List<String> _actionLogDetails = [
    'Khi bạn chat yêu cầu kiểm tra doanh thu, phòng trống, sửa chữa hoặc phát thông báo, AI sẽ tự động kích hoạt API & cập nhật dữ liệu Realtime.',
  ];
  String? _actionStatusSummary;

  static const List<String> _adminQuickCommands = [
    'Báo cáo doanh thu & công nợ tháng này',
    'Thống kê phòng trống & tỷ lệ lấp đầy',
    'Kiểm tra sự cố Kanban khẩn cấp',
    'Phát thông báo nhắc đóng phí toàn tòa nhà',
    'Mở khóa cửa IoT từ xa P.305',
  ];

  static const List<String> _residentQuickCommands = [
    'Phòng tôi bị rỉ nước vòi sen, gọi thợ sửa gấp giùm!',
    'Tại sao tháng này tiền điện phòng tôi cao vậy?',
    'Quy định gửi xe qua đêm của tòa nhà thế nào?',
    'Tạo mã VietQR thanh toán tiền phòng tháng này',
    'Mở khóa từ xa cửa phòng P.305 cho bạn tôi vào',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final roleMode = auth.effectiveAiRoleMode;
      context.read<AiChatProvider>().syncRoleGreeting(
            isAdmin: roleMode != 'resident',
            roleMode: roleMode,
            userName: auth.user?.fullName,
            roomCode: auth.user?.effectiveRoomCode,
          );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = (textToSend ?? _inputController.text).trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final prov = context.read<AiChatProvider>();

    if (textToSend == null) {
      _inputController.clear();
    }

    final toolResult = await executeSmartStayAiTools(
      context: context,
      query: text,
      isAdminMode: auth.effectiveAiRoleMode != 'resident',
    );
    if (!mounted) return;

    if (toolResult != null) {
      setState(() {
        _activeToolBadge = toolResult.toolBadge;
        _activeToolColor = toolResult.toolColor;
        _actionLogDetails = toolResult.details;
        _actionStatusSummary = toolResult.statusSummary;
      });
      if (toolResult.snackbarMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toolResult.snackbarMessage!),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }

    await prov.sendMessage(
      text,
      currentUser: auth.user,
      forceAdminMode: auth.effectiveAiRoleMode != 'resident',
      roleMode: auth.effectiveAiRoleMode,
      adminContextSummary: toolResult?.liveReplySummary,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiChatProvider>();
    final auth = context.watch<AuthProvider>();
    final effectiveRoleMode = auth.effectiveAiRoleMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          switch (effectiveRoleMode) {
            'admin' => 'Trợ Lý AI Copilot Quản Trị Hệ Thống',
            'manager' => 'Trợ Lý AI Điều Hành Ban Quản Lý',
            _ => 'Trợ Lý Ảo AI Hỗ Trợ Cư Dân',
          },
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              aiProv.clearChat(
                isAdmin: effectiveRoleMode != 'resident',
                roleMode: effectiveRoleMode,
                userName: auth.user?.fullName,
                roomCode: auth.user?.effectiveRoomCode,
              );
              setState(() {
                _activeToolBadge = 'Trạng thái: Chờ lệnh';
                _activeToolColor = const Color(0xFF64748B);
                _actionLogDetails = [
                  'Khi bạn chat yêu cầu kiểm tra doanh thu, phòng trống, sửa chữa hoặc phát thông báo, AI sẽ tự động kích hoạt API & cập nhật dữ liệu Realtime.',
                ];
                _actionStatusSummary = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Làm mới chat', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Header giống hệt Web AiConcierge.cshtml
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'AGENTIC AI 2026',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Text(
                              'Gemini Multi-turn Assistant',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy_rounded, color: Color(0xFF8B5CF6), size: 22),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Trợ Lý Ảo AI Tự Hành (Agentic Concierge 24/7)',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tự động nhận diện ngữ cảnh chat, phân tích tài chính điện nước, và tự hành tạo phiếu sự cố kỹ thuật Kanban mà cư dân không cần điền form',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sensors_rounded, color: Color(0xFF16A34A), size: 15),
                        SizedBox(width: 6),
                        Text(
                          'LLM Online: Gemini 1.5 Pro',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Layout 2 cột trên màn hình rộng (Web/Tablet) hoặc xếp dọc trên Mobile
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 760;
                final chatBox = _buildChatPanel(aiProv, auth);
                final toolBox = _buildToolCallingPanel();

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 8, child: chatBox),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: toolBox),
                    ],
                  );
                }
                return Column(
                  children: [
                    chatBox,
                    const SizedBox(height: 16),
                    toolBox,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(AiChatProvider aiProv, AuthProvider auth) {
    final quickCommands =
        auth.isAdmin ? _adminQuickCommands : _residentQuickCommands;

    return Container(
      height: 540,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header khung chat
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.isAdmin
                          ? 'SmartStay AI Copilot (Quản Trị & Vận Hành)'
                          : 'SmartStay AI Concierge',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            auth.isAdmin
                                ? 'Sẵn sàng hỗ trợ Quản lý ${auth.user?.fullName ?? "Quản Trị Viên"}'
                                : 'Sẵn sàng hỗ trợ cư dân ${auth.user?.fullName ?? "Hồ Ngọc Bảo"} (${auth.user?.effectiveRoomCode ?? "P.305"})',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: aiProv.messages.length + (aiProv.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == aiProv.messages.length && aiProv.isTyping) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Agentic AI đang phân tích & gọi công cụ tự hành...',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = aiProv.messages[index];
                final isMe = msg.isUser;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF4F46E5) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: isMe ? Colors.white : const Color(0xFF1E293B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            AppFormatters.dateTime(msg.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 16),

          // Các nút câu lệnh nhanh giống bản Web
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickCommands.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cmd = quickCommands[index];
                return OutlinedButton(
                  onPressed: () => _sendMessage(cmd),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    '⚡ "$cmd"',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Ô nhập tin nhắn
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Hỏi AI bất kỳ điều gì hoặc ra lệnh báo hỏng thiết bị...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _sendMessage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCallingPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nhật Ký Hành Động Tự Hành Của AI (Tool Calling)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hộp trạng thái thực thi Tool
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _activeToolColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _activeToolBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._actionLogDetails.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                    ),
                  ),
                ),
                if (_actionStatusSummary != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 15),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _actionStatusSummary!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Danh sách các Function Tools tích hợp
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CÁC CÔNG CỤ TỰ HÀNH ĐÃ ĐƯỢC TÍCH HỢP (FUNCTION TOOLS):',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                _buildToolRow(
                  'create_kanban_ticket(): Tạo phiếu sự cố',
                  const Color(0xFF2563EB),
                ),
                const SizedBox(height: 6),
                _buildToolRow(
                  'query_invoice_breakdown(): Bóc tách hóa đơn',
                  const Color(0xFF16A34A),
                ),
                const SizedBox(height: 6),
                _buildToolRow(
                  'generate_vietqr_link(): Sinh link VietQR',
                  const Color(0xFFD97706),
                ),
                const SizedBox(height: 6),
                _buildToolRow(
                  'remote_iot_lock_control(): Điều khiển khóa',
                  const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolRow(String label, Color color) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
