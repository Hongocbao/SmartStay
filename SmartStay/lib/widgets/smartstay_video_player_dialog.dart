import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/smartstay_theme.dart';

/// Hiển thị hộp thoại phát Video thực tế / Video Tour bằng `video_player`
/// (hỗ trợ Web HTML5 `<video>`, Android/iOS, có âm thanh mặc định & nút phóng to toàn màn hình).
Future<void> showSmartStayVideoPlayerDialog(
  BuildContext context, {
  required String title,
  required String videoUrl,
  String headerPrefix = 'Video thực tế',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SmartStayVideoPlayerDialog(
      title: title,
      videoUrl: videoUrl,
      headerPrefix: headerPrefix,
    ),
  );
}

class _SmartStayVideoPlayerDialog extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String headerPrefix;

  const _SmartStayVideoPlayerDialog({
    required this.title,
    required this.videoUrl,
    required this.headerPrefix,
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
  bool _isFullscreen = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  static const String _defaultSampleAudioVideoUrl =
      'https://www.w3schools.com/html/mov_bbb.mp4';

  String _resolvePlayableVideoUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('demo://') ||
        trimmed.contains('interactive-examples.mdn.mozilla.net/media/cc0-videos/flower')) {
      return _defaultSampleAudioVideoUrl;
    }
    return trimmed;
  }

  Future<void> _initPlayer() async {
    final resolved = _resolvePlayableVideoUrl(widget.videoUrl);
    if (resolved.isEmpty) {
      setState(() {
        _initializing = false;
        _errorMsg =
            'Chưa có tệp video thực tế cho mục này. Hãy quay hoặc tải video mới để phát.';
      });
      return;
    }

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(resolved));
      _controller = ctrl;
      ctrl.addListener(_onPlayerTick);
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(1.0);
      _muted = false;
      try {
        await ctrl.play();
      } catch (_) {
        // Nếu trình duyệt yêu cầu tương tác trực tiếp để phát âm thanh, nút Play vẫn sẵn sàng bật tiếng.
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;

    final size = MediaQuery.of(context).size;
    final ctrl = _controller;
    final isReady = ctrl != null && ctrl.value.isInitialized;
    final isPlaying = isReady && ctrl.value.isPlaying;
    final pos = isReady ? ctrl.value.position : Duration.zero;
    final dur = isReady ? ctrl.value.duration : Duration.zero;

    final double dialogWidth = _isFullscreen
        ? size.width
        : (size.width > 640 ? 580.0 : size.width - 24);
    final double videoMinHeight = _isFullscreen ? (size.height - 210).clamp(260.0, 680.0) : 220.0;
    final double videoMaxHeight = _isFullscreen ? (size.height - 190).clamp(280.0, 740.0) : 340.0;

    return Dialog(
      insetPadding: _isFullscreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 20),
        side: _isFullscreen ? BorderSide.none : BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: _isFullscreen ? size.height : (size.height * 0.88),
        ),
        child: Column(
          mainAxisSize: _isFullscreen ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: SmartStayColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: SmartStayColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.headerPrefix}: ${widget.title}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      color: textPrimary,
                    ),
                    tooltip: _isFullscreen ? 'Thu nhỏ' : 'Phóng to toàn màn hình',
                    onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textPrimary),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Video Stage + Controls
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: _isFullscreen ? MainAxisSize.max : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      fit: _isFullscreen ? FlexFit.tight : FlexFit.loose,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          color: const Color(0xFF020617),
                          constraints: BoxConstraints(
                            minHeight: videoMinHeight,
                            maxHeight: videoMaxHeight,
                          ),
                          child: _initializing
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(height: 10),
                                      Text(
                                        'Đang tải luồng Video HD...',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
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
                                            const Icon(
                                              Icons.videocam_off_rounded,
                                              color: Colors.orangeAccent,
                                              size: 36,
                                            ),
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
                                        Center(
                                          child: AspectRatio(
                                            aspectRatio: ctrl!.value.aspectRatio > 0
                                                ? ctrl.value.aspectRatio
                                                : 16 / 9,
                                            child: VideoPlayer(ctrl),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.translucent,
                                            onTap: () async {
                                              if (isPlaying) {
                                                await ctrl.pause();
                                              } else {
                                                if (!_muted) {
                                                  await ctrl.setVolume(1.0);
                                                }
                                                await ctrl.play();
                                              }
                                            },
                                            child: Center(
                                              child: AnimatedOpacity(
                                                opacity: isPlaying ? 0.0 : 1.0,
                                                duration: const Duration(milliseconds: 200),
                                                child: Container(
                                                  width: 58,
                                                  height: 58,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.6),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white54,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow_rounded,
                                                    color: Colors.white,
                                                    size: 36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => setState(
                                                () => _isFullscreen = !_isFullscreen,
                                              ),
                                              borderRadius: BorderRadius.circular(99),
                                              child: Container(
                                                constraints: const BoxConstraints(minHeight: 36),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F172A)
                                                      .withValues(alpha: 0.78),
                                                  borderRadius: BorderRadius.circular(99),
                                                  border: Border.all(color: Colors.white38),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _isFullscreen
                                                          ? Icons.fullscreen_exit_rounded
                                                          : Icons.fullscreen_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _isFullscreen ? 'Thu nhỏ' : 'Toàn màn hình',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    if (isReady) ...[
                      const SizedBox(height: 10),
                      VideoProgressIndicator(
                        ctrl,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        colors: const VideoProgressColors(
                          playedColor: SmartStayColors.primary,
                          bufferedColor: Color(0xFF94A3B8),
                          backgroundColor: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                  color: SmartStayColors.primary,
                                  size: 34,
                                ),
                                tooltip: isPlaying ? 'Tạm dừng' : 'Phát',
                                onPressed: () async {
                                  if (isPlaying) {
                                    await ctrl.pause();
                                  } else {
                                    if (!_muted) {
                                      await ctrl.setVolume(1.0);
                                    }
                                    await ctrl.play();
                                  }
                                },
                              ),
                              Text(
                                '${_fmtDuration(pos)} / ${_fmtDuration(dur)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  setState(() => _muted = !_muted);
                                  await ctrl.setVolume(_muted ? 0.0 : 1.0);
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                                icon: Icon(
                                  _muted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  size: 18,
                                  color: _muted
                                      ? SmartStayColors.danger
                                      : SmartStayColors.success,
                                ),
                                label: Text(
                                  _muted ? 'Đang tắt tiếng' : 'Âm thanh: Bật',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _muted
                                        ? SmartStayColors.danger
                                        : SmartStayColors.success,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SmartStayColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Builder(
                      builder: (_) {
                        final resolved = _resolvePlayableVideoUrl(widget.videoUrl);
                        final shown = resolved.isEmpty ? widget.videoUrl : resolved;
                        return Text(
                          'Nguồn Video: ${shown.length > 68 ? '${shown.substring(0, 68)}...' : shown}',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
