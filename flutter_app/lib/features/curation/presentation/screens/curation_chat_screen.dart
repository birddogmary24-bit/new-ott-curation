import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../providers/curation_provider.dart';
import '../widgets/chat_bubble.dart';

class CurationChatScreen extends ConsumerStatefulWidget {
  const CurationChatScreen({super.key});

  @override
  ConsumerState<CurationChatScreen> createState() => _CurationChatScreenState();
}

class _CurationChatScreenState extends ConsumerState<CurationChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showQuickPrompts = true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() => _showQuickPrompts = false);
    ref.read(curationChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(curationChatProvider);

    // 새 메시지 시 스크롤
    ref.listen(curationChatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 큐레이션',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  chatState.isThinking ? '생각 중...' : '온라인',
                  style: TextStyle(
                    color: chatState.isThinking ? AppColors.accent : Colors.greenAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondaryDark),
            onPressed: () {
              ref.read(curationChatProvider.notifier).clearChat();
              setState(() => _showQuickPrompts = true);
            },
          ),
        ],
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimaryDark),
      ),
      body: Column(
        children: [
          // 채팅 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: chatState.messages.length + (_showQuickPrompts ? 1 : 0),
              itemBuilder: (context, index) {
                // 마지막에 빠른 질문 프롬프트
                if (_showQuickPrompts && index == chatState.messages.length) {
                  return _QuickPrompts(onSelect: _sendMessage);
                }
                return ChatBubble(message: chatState.messages[index]);
              },
            ),
          ),

          // 입력 영역
          _ChatInput(
            controller: _controller,
            isLoading: chatState.isThinking,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 빠른 예시 질문
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _QuickPrompts extends StatelessWidget {
  final void Function(String) onSelect;

  const _QuickPrompts({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: quickPrompts.map((prompt) {
          return GestureDetector(
            onTap: () => onSelect(prompt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                prompt,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 채팅 입력 바
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final void Function(String) onSend;

  const _ChatInput({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(top: BorderSide(color: AppColors.dividerDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 15),
              decoration: InputDecoration(
                hintText: '어떤 콘텐츠를 원하시나요?',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
                filled: true,
                fillColor: AppColors.surfaceDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.dividerDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: isLoading
                ? const SizedBox(
                    width: 44, height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.primary,
                    iconSize: 28,
                    onPressed: () => onSend(controller.text),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      shape: const CircleBorder(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
