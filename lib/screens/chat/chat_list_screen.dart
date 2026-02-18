import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_models.dart';
import '../../models/app_models.dart';
import 'chat_screen.dart';
import 'create_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<ChatProvider>().loadUserChatRooms(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showCreateChatOptions(),
            icon: const Icon(Icons.add_comment),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Consumer2<ChatProvider, AuthProvider>(
                builder: (context, chatProvider, authProvider, child) {
                  final userId = authProvider.user?.uid ?? '';
                  if (userId.isEmpty) return const SizedBox.shrink();

                  return StreamBuilder<List<ChatRoom>>(
                    stream: chatProvider.streamUserChatRooms(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final chatRooms = snapshot.data ?? [];
                      final searchQuery = _searchController.text.toLowerCase();
                      
                      final filteredChatRooms = searchQuery.isEmpty
                          ? chatRooms
                          : chatRooms.where((room) {
                              return room.name.toLowerCase().contains(searchQuery) ||
                                  room.description?.toLowerCase().contains(searchQuery) == true;
                            }).toList();

                      if (filteredChatRooms.isEmpty) {
                        return _buildEmptyState();
                      }

                      return _buildChatList(filteredChatRooms, userId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatOptions(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Start connecting with fellow members\nof the foundation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () => _showCreateChatOptions(),
            icon: const Icon(Icons.add),
            label: const Text('Start Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatRoom> chatRooms, String currentUserId) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        return _buildChatItem(chatRoom, currentUserId);
      },
    );
  }

  Widget _buildChatItem(ChatRoom chatRoom, String currentUserId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: _buildChatAvatar(chatRoom, currentUserId),
          title: Text(
            _getChatDisplayName(chatRoom, currentUserId),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chatRoom.type == ChatType.group && chatRoom.description != null)
                Text(
                  chatRoom.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 4),

              Row(
                children: [
                  if (chatRoom.lastMessage != null) ...[
                    Expanded(
                      child: Text(
                        _getLastMessagePreview(chatRoom.lastMessage!, currentUserId),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (chatRoom.lastMessage != null)
                Text(
                  _formatTimestamp(chatRoom.lastMessage!.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: (chatRoom.unreadCounts[currentUserId] ?? 0) > 0
                        ? AppTheme.primaryColor
                        : Colors.black45,
                    fontWeight: (chatRoom.unreadCounts[currentUserId] ?? 0) > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),

              const SizedBox(height: 4),

              if ((chatRoom.unreadCounts[currentUserId] ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${chatRoom.unreadCounts[currentUserId]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chatRoom.type == ChatType.group)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.group,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),

                    const SizedBox(width: 4),

                    Text(
                      '${chatRoom.participants.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          onTap: () => _openChat(chatRoom),
        ),
      ),
    );
  }

  Widget _buildChatAvatar(ChatRoom chatRoom, String currentUserId) {
    if (chatRoom.type == ChatType.group) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                chatRoom.name.isNotEmpty ? chatRoom.name[0].toUpperCase() : 'G',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.group,
                  size: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Individual chat avatar
      final displayName = _getChatDisplayName(chatRoom, currentUserId);
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  String _getChatDisplayName(ChatRoom chatRoom, String currentUserId) {
    if (chatRoom.type == ChatType.group) {
      return chatRoom.name;
    }

    // For individual chats, we need to get the other participant's name
    // This is a simplified version - in production, you'd resolve names from user data
    return chatRoom.name.isNotEmpty ? chatRoom.name : 'Private Chat';
  }

  String _getLastMessagePreview(Message lastMessage, String currentUserId) {
    String prefix = '';
    if (lastMessage.senderId == currentUserId) {
      prefix = 'You: ';
    } else if (lastMessage.type != MessageType.system) {
      prefix = '${lastMessage.senderName}: ';
    }

    switch (lastMessage.type) {
      case MessageType.text:
        return '$prefix${lastMessage.content}';
      case MessageType.image:
        return '${prefix}📷 Photo';
      case MessageType.file:
        return '${prefix}📎 File';
      case MessageType.system:
        return lastMessage.content;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(timestamp);
    } else {
      return DateFormat('MM/dd').format(timestamp);
    }
  }

  void _showCreateChatOptions() {
    final authProvider = context.read<AuthProvider>();
    final isExco = authProvider.appUser != null && 
        (authProvider.appUser!.role == UserRole.president || 
         authProvider.appUser!.role == UserRole.registrar || 
         authProvider.appUser!.role == UserRole.cashier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Text(
              'Start New Conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.blue,
                ),
              ),
              title: const Text('Private Chat'),
              subtitle: const Text('Chat with a foundation member'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateChatScreen(
                      chatType: ChatType.individual,
                     ),
                  ),
                );
              },
            ),

            if (isExco)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.group_add,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: const Text('Group Chat'),
                subtitle: const Text('Create a group with multiple members'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateChatScreen(
                        chatType: ChatType.group,
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openChat(ChatRoom chatRoom) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.setCurrentChatRoom(chatRoom);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chatRoom),
      ),
    );
  }
}