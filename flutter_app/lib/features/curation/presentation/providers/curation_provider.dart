import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/curation_remote_datasource.dart';
import '../../domain/entities/chat_message.dart';

const _uuid = Uuid();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Infrastructure
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

final curationDataSourceProvider = Provider<CurationRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CurationRemoteDataSource(dio);
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 큐레이션 챗 상태
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CurationChatState {
  final List<ChatMessage> messages;
  final bool isThinking;
  final String? error;

  const CurationChatState({
    this.messages = const [],
    this.isThinking = false,
    this.error,
  });

  CurationChatState copyWith({
    List<ChatMessage>? messages,
    bool? isThinking,
    String? error,
  }) {
    return CurationChatState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      error: error,
    );
  }

  bool get hasMessages => messages.isNotEmpty;
}

final curationChatProvider =
    StateNotifierProvider<CurationChatNotifier, CurationChatState>(
  (ref) => CurationChatNotifier(ref),
);

class CurationChatNotifier extends StateNotifier<CurationChatState> {
  final Ref _ref;

  CurationChatNotifier(this._ref) : super(const CurationChatState()) {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    state = state.copyWith(messages: [
      ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        text: '안녕하세요! 어떤 콘텐츠를 찾고 계신가요?\n\n'
            '"비오는 날 혼자 볼 영화", "가족과 함께 보기 좋은 따뜻한 드라마" 처럼 자유롭게 말씀해주세요. 🎬',
        timestamp: DateTime.now(),
      ),
    ]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 유저 메시지 추가
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    // 로딩 중인 AI 응답 placeholder
    final loadingMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      text: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isThinking: true,
      error: null,
    );

    try {
      final dataSource = _ref.read(curationDataSourceProvider);
      final response = await dataSource.chat(text.trim());

      // 로딩 메시지를 실제 응답으로 교체
      final updatedMessages = state.messages.map((msg) {
        if (msg.id == loadingMsg.id) {
          return ChatMessage(
            id: msg.id,
            role: MessageRole.assistant,
            text: response.message,
            recommendations: response.contents,
            curatingReason: response.curatingReason,
            timestamp: msg.timestamp,
          );
        }
        return msg;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isThinking: false,
      );
    } catch (e) {
      final updatedMessages = state.messages.map((msg) {
        if (msg.id == loadingMsg.id) {
          return ChatMessage(
            id: msg.id,
            role: MessageRole.assistant,
            text: '죄송해요, 오류가 발생했어요. 다시 시도해주세요.',
            timestamp: msg.timestamp,
          );
        }
        return msg;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isThinking: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() {
    state = const CurationChatState();
    _addWelcomeMessage();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 빠른 예시 질문 (Quick Prompts)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

const quickPrompts = [
  '비오는 날 혼자 보기 좋은 영화',
  '가족과 함께 볼 따뜻한 드라마',
  '잠들기 전 가볍게 볼 코미디',
  '90년대 명작 추천해줘',
  '넷플릭스에서 볼만한 스릴러',
  '요즘 화제작 뭐야?',
];
