import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_models.dart';
import '../models/app_models.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ChatRoom> _chatRooms = [];
  List<Message> _currentMessages = [];
  ChatRoom? _currentChatRoom;
  bool _isLoading = false;
  String? _errorMessage = null;
  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  List<Message> get currentMessages => _currentMessages;
  ChatRoom? get currentChatRoom => _currentChatRoom;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int getTotalUnreadCount(String userId) {
    int total = 0;
    for (var room in _chatRooms) {
      total += room.unreadCounts[userId] ?? 0;
    }
    return total;
  }

  // Load user's chat rooms
  Future<void> loadUserChatRooms(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();

      _chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _errorMessage = 'Failed to load chat rooms: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream user's chat rooms for real-time updates
  Stream<List<ChatRoom>> streamUserChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Create individual chat
  Future<ChatRoom?> createIndividualChat(
      String currentUserId,
      String otherUserId,
      String currentUserName,
      String otherUserName,
      ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Check if chat already exists
      final existingChat = await _findExistingIndividualChat(currentUserId, otherUserId);
      if (existingChat != null) {
        return existingChat;
      }

      // Create new individual chat
      final chatRoom = ChatRoom(
        id: '',
        name: otherUserName, // For individual chats, use other user's name
        type: ChatType.individual,
        participants: [currentUserId, otherUserId],
        createdBy: currentUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore
          .collection('chatRooms')
          .add(chatRoom.toMap());

      final newChatRoom = chatRoom.copyWith(id: docRef.id);
      _chatRooms.insert(0, newChatRoom);

      return newChatRoom;
    } catch (e) {
      _errorMessage = 'Failed to create chat: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create group chat
  Future<ChatRoom?> createGroupChat(
      String creatorId,
      String creatorName,
      String groupName,
      String? description,
      List<String> participantIds,
      ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Add creator to participants if not already included
      if (!participantIds.contains(creatorId)) {
        participantIds.add(creatorId);
      }

      final chatRoom = ChatRoom(
        id: '',
        name: groupName,
        description: description,
        type: ChatType.group,
        participants: participantIds,
        createdBy: creatorId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        settings: {
          'admins': [creatorId],
          'allowMembersToAddOthers': true,
          'allowMembersToChangeGroupInfo': false,
        },
      );

      DocumentReference docRef = await _firestore
          .collection('chatRooms')
          .add(chatRoom.toMap());

      final newChatRoom = chatRoom.copyWith(id: docRef.id);
      _chatRooms.insert(0, newChatRoom);

      // Send system message about group creation
      await _sendSystemMessage(
        newChatRoom.id,
        '$creatorName created the group',
      );

      return newChatRoom;
    } catch (e) {
      _errorMessage = 'Failed to create group: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Find existing individual chat
  Future<ChatRoom?> _findExistingIndividualChat(String userId1, String userId2) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chatRooms')
          .where('type', isEqualTo: ChatType.individual.name)
          .where('participants', arrayContains: userId1)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final chatRoom = ChatRoom.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        if (chatRoom.participants.contains(userId2)) {
          return chatRoom;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding existing chat: $e');
      return null;
    }
  }

  // Send message
  Future<bool> sendMessage(
      String chatRoomId,
      String senderId,
      String senderName,
      String content,
      {MessageType type = MessageType.text,
        String? replyToMessageId,
        Map<String, dynamic>? metadata}
      ) async {
    try {
      final message = Message(
        id: '',
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        metadata: metadata ?? {},
      );

      // Add message to messages collection
      DocumentReference messageDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toMap());

      // Update chat room's last message, timestamp and unread counts
      final DocumentSnapshot roomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
      final List<String> participants = List<String>.from(roomDoc['participants'] ?? []);
      
      Map<String, dynamic> updates = {
        'lastMessage': message.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      for (String participantId in participants) {
        if (participantId != senderId) {
          updates['unreadCounts.$participantId'] = FieldValue.increment(1);
        }
      }

      await _firestore.collection('chatRooms').doc(chatRoomId).update(updates);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  // Send system message
  Future<void> _sendSystemMessage(String chatRoomId, String content) async {
    await sendMessage(
      chatRoomId,
      'system',
      'System',
      content,
      type: MessageType.system,
    );
  }

  // Start listening to chat rooms for global state/unread counts
  void startChatRoomsListener(String userId) {
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // If user is in a chat room that just got a new message, reset its unread count
      if (_currentChatRoom != null) {
        final currentRoomIndex = _chatRooms.indexWhere((r) => r.id == _currentChatRoom!.id);
        if (currentRoomIndex != -1) {
          final currentRoom = _chatRooms[currentRoomIndex];
          if ((currentRoom.unreadCounts[userId] ?? 0) > 0) {
            resetUnreadCount(currentRoom.id, userId);
          }
        }
      }
      
      notifyListeners();
    });
  }

  // Load messages for a chat room
  Future<void> loadMessages(String chatRoomId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _currentMessages = snapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream messages for real-time updates
  Stream<List<Message>> streamMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Set current chat room
  void setCurrentChatRoom(ChatRoom? chatRoom) {
    _currentChatRoom = chatRoom;
    if (chatRoom != null) {
      loadMessages(chatRoom.id);
    }
    notifyListeners();
  }

  // Add participants to group chat
  Future<bool> addParticipantsToGroup(
      String chatRoomId,
      List<String> newParticipantIds,
      String addedByUserId,
      String addedByUserName,
      ) async {
    try {
      final chatRoomDoc = _firestore.collection('chatRooms').doc(chatRoomId);

      await chatRoomDoc.update({
        'participants': FieldValue.arrayUnion(newParticipantIds),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message
      await _sendSystemMessage(
        chatRoomId,
        '$addedByUserName added ${newParticipantIds.length} new member(s)',
      );

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add participants: $e';
      notifyListeners();
      return false;
    }
  }

  // Remove participant from group chat
  Future<bool> removeParticipantFromGroup(
      String chatRoomId,
      String participantId,
      String removedByUserId,
      String removedByUserName,
      String participantName,
      ) async {
    try {
      final chatRoomDoc = _firestore.collection('chatRooms').doc(chatRoomId);

      await chatRoomDoc.update({
        'participants': FieldValue.arrayRemove([participantId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message
      await _sendSystemMessage(
        chatRoomId,
        '$removedByUserName removed $participantName',
      );

      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove participant: $e';
      notifyListeners();
      return false;
    }
  }

  // Update group info
  Future<bool> updateGroupInfo(
      String chatRoomId,
      String? newName,
      String? newDescription,
      String? newImageUrl,
      String updatedByUserName,
      ) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (newName != null) updates['name'] = newName;
      if (newDescription != null) updates['description'] = newDescription;
      if (newImageUrl != null) updates['groupImageUrl'] = newImageUrl;

      await _firestore.collection('chatRooms').doc(chatRoomId).update(updates);

      // Send system message
      await _sendSystemMessage(
        chatRoomId,
        '$updatedByUserName updated group info',
      );

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update group: $e';
      notifyListeners();
      return false;
    }
  }

  // Reset unread count for current user
  Future<void> resetUnreadCount(String chatRoomId, String userId) async {
    try {
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      debugPrint('Error resetting unread count: $e');
    }
  }

  // Leave group chat
  Future<bool> leaveGroup(
      String chatRoomId,
      String userId,
      String userName,
      ) async {
    try {
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message
      await _sendSystemMessage(chatRoomId, '$userName left the group');

      // Remove from local list
      _chatRooms.removeWhere((room) => room.id == chatRoomId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to leave group: $e';
      notifyListeners();
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      // This is a simplified version - in production, you'd want to batch update
      // unread messages for better performance
      final messagesQuery = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('readBy', arrayContains: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a chat room
  Future<int> getUnreadMessageCount(String chatRoomId, String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('readBy', arrayContainsAny: [userId])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // Search chat rooms
  List<ChatRoom> searchChatRooms(String query) {
    if (query.isEmpty) return _chatRooms;

    return _chatRooms.where((room) {
      return room.name.toLowerCase().contains(query.toLowerCase()) ||
          room.description?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Upload file to Firebase Storage
  Future<String?> uploadFile(File file, String folder) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child(folder).child(fileName);
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _errorMessage = 'Failed to upload file: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  // Clear current chat
  void clearCurrentChat() {
    _currentChatRoom = null;
    _currentMessages.clear();
    notifyListeners();
  }

  // Clear all data on logout
  void clearAllData() {
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;
    _chatRooms = [];
    _currentMessages = [];
    _currentChatRoom = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}