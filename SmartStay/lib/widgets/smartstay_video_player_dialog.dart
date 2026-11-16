import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Hiển thị hộp thoại phát Video thực tế bằng `video_player` (hỗ trợ Web HTML5 `<video>` và Android/iOS).
Future<void> showSmartStayVideoPlayerDialog(
  BuildContext context, {
  required String title,
  required String videoUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SmartStayVideoPlayerDialog(
      title: title,
      videoUrl: videoUrl,
    ),
  );
}

class _SmartStayVideoPlayerDialog extends StatefulWidget {
  final String title;
  final String videoUrl;

  const _SmartStayVideoPlayerDialog({
    required this.title,
    required this.videoUrl,
  });

  @override
  State<_SmartStayVideoPlayerDialog> createState() =>
      _SmartStayVideoPlayerDialogState();
}

class _SmartStayVideoPlayerDialogState
    extends State<_SmartStayVideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  bool _muted = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final raw = widget.videoUrl.trim();
    if (raw.isEmpty || raw.startsWith('demo://')) {
      setState(() {
        _initializing = false;
        _errorMsg =
            'Sản phẩm này chưa có tệp video thực tế. Hãy quay hoặc tải video mới để phát.';
      });
      return;
    }

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(raw));
      _controller = ctrl;
      ctrl.addListener(_onPlayerTick);
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMsg = 'Không thể phát video từ nguồn này: $e';
      });
    }
  }

  void _onPlayerTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerTick);
    _controller?.dispose();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final isReady = ctrl != null && ctrl.value.isInitialized;
    final isPlaying = isReady && ctrl.value.isPlaying;
    final pos = isReady ? ctrl.value.position : Duration.zero;
    final dur = isReady ? ctrl.value.duration : Duration.zero;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      title: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Video thực tế: ${widget.title}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Đóng',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: const Color(0xFF020617),
                constraints: const BoxConstraints(minHeight: 200, maxHeight: 300),
                child: _initializing
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 10),
                            Text(
                              'Đang tải luồng Video HD...',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : _errorMsg != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.videocam_off_rounded,
                                      color: Colors.orangeAccent, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMsg!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio: ctrl!.value.aspectRatio > 0
                                    ? ctrl.value.aspectRatio
                                    : 16 / 9,
                                child: VideoPlayer(ctrl),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (isPlaying) {
                                    ctrl.pause();
                                  } else {
                                    ctrl.play();
                                  }
                                },
                                child: AnimatedOpacity(
                                  opacity: isPlaying ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            if (isReady) ...[
              const SizedBox(height: 8),
              VideoProgressIndicator(
                ctrl,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFDC2626),
                  bufferedColor: Color(0xFFCBD5E1),
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 30,
                    ),
                    tooltip: isPlaying ? 'Tạm dừng' : 'Phát',
                    onPressed: () {
                      if (isPlaying) {
                        ctrl.pause();
                      } else {
                        ctrl.play();
                      }
                    },
                  ),
                  Text(
                    '${_fmtDuration(pos)} / ${_fmtDuration(dur)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: const Color(0xFF475569),
                    ),
                    tooltip: _muted ? 'Bật tiếng' : 'Tắt tiếng',
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      ctrl.setVolume(_muted ? 0.0 : 1.0);
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Nguồn Video: ${widget.videoUrl.length > 60 ? '${widget.videoUrl.substring(0, 60)}...' : widget.videoUrl}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
