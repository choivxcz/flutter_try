class Message {
  final String role;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    this.imageUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  Message copyWith({
    String? role,
    String? content,
    String? imageUrl,
    DateTime? timestamp,
  }) {
    return Message(
      role: role ?? this.role,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'Message(role: $role, content: $content, imageUrl: $imageUrl)';
}
