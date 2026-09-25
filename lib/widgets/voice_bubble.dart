import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

/// Play/pause voice message row with progress + duration.
class VoiceBubble extends StatefulWidget {
  final String url;
  final int durationSeconds;
  final bool isMine;

  const VoiceBubble({
    super.key,
    required this.url,
    required this.durationSeconds,
    required this.isMine,
  });

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  late final AudioPlayer _player;
  bool _playing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _duration = Duration(seconds: widget.durationSeconds);
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        await _player.pause();
        setState(() => _playing = false);
      } else {
        await _player.play(UrlSource(widget.url));
        setState(() => _playing = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play voice message.')),
        );
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final total = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: widget.durationSeconds);
    final progress = total.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / total.inMilliseconds;
    final iconColor =
        widget.isMine ? ore.colors.textInverse : ore.colors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Icon(
            _playing ? Icons.pause_circle : Icons.play_circle,
            size: 36,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmt(_position)} / ${_fmt(total)}',
                style: ore.typography.caption.copyWith(
                  color: widget.isMine
                      ? ore.colors.textInverse
                      : ore.colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
