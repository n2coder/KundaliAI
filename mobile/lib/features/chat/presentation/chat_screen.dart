import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// AI Astrologer chat — loads history from API, sends messages to backend.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final AnimationController _orbCtrl;

  final _messages = <ChatMessageModel>[];
  bool _historyLoaded = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ref.read(chatRepoProvider).getHistory();
      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _historyLoaded = true;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoaded = true);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final userMsg = ChatMessageModel(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(userMsg);
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await ref.read(chatRepoProvider).sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.add(reply);
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CosmicScaffold(
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.cosmicTextDark, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('AI Astrologer',
                          style: AppTextStyles.headingMedium()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz,
                        color: AppColors.cosmicTextDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_historyLoaded
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.cosmicGold))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      itemCount: _messages.length + (_sending ? 2 : 1),
                      itemBuilder: (ctx, i) {
                        if (i == _messages.length) {
                          return _AiOrb(ctrl: _orbCtrl);
                        }
                        if (i == _messages.length + 1) {
                          return const _TypingIndicator();
                        }
                        return _ChatBubble(msg: _messages[i]);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: CosmicCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: AppTextStyles.bodyMedium(
                              color: AppColors.cosmicTextLight),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: AppTextStyles.bodyMedium(),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _sending
                            ? Icons.hourglass_top_rounded
                            : Icons.send_rounded,
                        color: _sending
                            ? AppColors.cosmicTextLight
                            : AppColors.cosmicGold,
                      ),
                      onPressed: _sending ? null : _send,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg});
  final ChatMessageModel msg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment:
            msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? AppColors.featureDark
                  : AppColors.cardBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: msg.isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: msg.isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
              border: msg.isUser
                  ? Border.all(
                      color: AppColors.cosmicGold.withOpacity(0.3),
                      width: 0.8)
                  : Border.all(
                      color: AppColors.cardBorder, width: 0.8),
            ),
            child: Text(
              msg.content,
              style: AppTextStyles.bodyMedium(
                color: msg.isUser
                    ? AppColors.white
                    : AppColors.cosmicTextDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.cosmicGold),
              ),
              const SizedBox(width: 8),
              Text('Consulting the stars...',
                  style: AppTextStyles.bodySmall(
                      color: AppColors.cosmicTextLight)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiOrb extends StatelessWidget {
  const _AiOrb({required this.ctrl});
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) => CustomPaint(
            size: const Size(140, 140),
            painter: _OrbPainter(pulse: ctrl.value),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.pulse});
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * (0.7 + i * 0.12),
        Paint()
          ..color = AppColors.cosmicGold
              .withOpacity(0.06 * i * (0.7 + pulse * 0.3))
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, 8.0 * i),
      );
    }

    final orbitPaint = Paint()
      ..color = AppColors.cosmicGold.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(i * math.pi / 4 + pulse * 0.3);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: r * 1.4, height: r * 0.4),
        orbitPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.55,
      Paint()..color = AppColors.cosmicWheelBg,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.55,
      Paint()
        ..color = AppColors.cosmicGold.withOpacity(0.7 + pulse * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawStar(canvas, Offset(cx, cy), r * 0.28);
  }

  void _drawStar(Canvas canvas, Offset center, double size) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final rr = i.isEven ? size : size * 0.3;
      final x = center.dx + rr * math.cos(angle);
      final y = center.dy + rr * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.pulse != pulse;
}
