import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { individual, group }
enum MessageType { text, image, file, system }
enum MessageStatus { sent, delivered, read }

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final List<String> participants;
  final String? groupImageUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final Map<String, dynamic> settings;
  final Map<String, int> unreadCounts;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participants,
    this.groupImageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.settings = const {},
    this.unreadCounts = const {},
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'participants': participants,
      'groupImageUrl': groupImageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage?.toMap(),
      'settings': settings,
      'unreadCounts': unreadCounts,
      'isActive': isActive,
    };
  }

  factory ChatRoom.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoom(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      type: ChatType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ChatType.individual,
      ),
      participants: List<String>.from(map['participants'] ?? []),
      groupImageUrl: map['groupImageUrl'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'] != null
          ? Message.fromMap('', map['lastMessage'] as Map<String, dynamic>)
          : null,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      isActive: map['isActive'] ?? true,
    );
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    ChatType? type,
    List<String>? participants,
    String? groupImageUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Message? lastMessage,
    Map<String, dynamic>? settings,
    Map<String, int>? unreadCounts,
    bool? isActive,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      settings: settings ?? this.settings,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get display name for individual chats
  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return name;
    }

    // For individual chats, return the other participant's name
    // This would need to be resolved with actual user data
    return name.isNotEmpty ? name : 'Private Chat';
  }

  // Check if user is admin (for groups)
  bool isUserAdmin(String userId) {
    return settings['admins']?.contains(userId) ?? (createdBy == userId);
  }
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToMessageId;
  final Map<String, dynamic> metadata;
  final List<String> readBy;
  final bool isEdited;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.replyToMessageId,
    this.metadata = const {},
    this.readBy = const [],
    this.isEdited = false,
    this.editedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      'readBy': readBy,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      replyToMessageId: map['replyToMessageId'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      readBy: List<String>.from(map['readBy'] ?? []),
      isEdited: map['isEdited'] ?? false,
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  bool get isSystemMessage => type == MessageType.system;
  bool get isFromCurrentUser => false; // This should be determined by comparing with current user ID

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class ChatParticipant {
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime joinedAt;
  final DateTime? lastSeen;
  final bool isOnline;
  final bool isAdmin;
  final bool isMuted;

  ChatParticipant({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.joinedAt,
    this.lastSeen,
    this.isOnline = false,
    this.isAdmin = false,
    this.isMuted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
      'isAdmin': isAdmin,
      'isMuted': isMuted,
    };
  }

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      isOnline: map['isOnline'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      isMuted: map['isMuted'] ?? false,
    );
  }

  ChatParticipant copyWith({
    String? userId,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? joinedAt,
    DateTime? lastSeen,
    bool? isOnline,
    bool? isAdmin,
    bool? isMuted,
  }) {
    return ChatParticipant(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      isAdmin: isAdmin ?? this.isAdmin,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}