import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/widgets/content_card.dart';
import '../../../../routing/app_router.dart';
import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _UserBubble(message: message);
    }
    return _AssistantBubble(message: message);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 유저 말풍선
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 60, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AI 어시스턴트 말풍선
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;
  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 아바타 + 텍스트
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI 아이콘
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),

              // 텍스트 버블
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 40, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: message.isLoading
                      ? const _TypingIndicator()
                      : Text(
                          message.text,
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // 추천 콘텐츠 리스트
          if (message.hasRecommendations) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.curatingReason != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        message.curatingReason!,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.recommendations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final content = message.recommendations[index];
                        return ContentCard(
                          content: content,
                          onTap: () => context.push(Routes.contentDetail(content.id)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 타이핑 인디케이터 (점 세 개 애니메이션)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true);
    });

    _animations = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    // 순차적으로 시작
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) {
            return Container(
              margin: EdgeInsets.only(
                right: i < 2 ? 4 : 0,
                bottom: _animations[i].value,
              ),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
