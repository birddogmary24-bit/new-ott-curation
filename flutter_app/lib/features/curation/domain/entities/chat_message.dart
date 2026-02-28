import '../../../home/domain/entities/content.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final List<Content> recommendations;
  final String? curatingReason;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.recommendations = const [],
    this.curatingReason,
    required this.timestamp,
    this.isLoading = false,
  });

  bool get isUser      => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get hasRecommendations => recommendations.isNotEmpty;

  ChatMessage copyWith({
    String? text,
    List<Content>? recommendations,
    String? curatingReason,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      recommendations: recommendations ?? this.recommendations,
      curatingReason: curatingReason ?? this.curatingReason,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
