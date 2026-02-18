import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import '../../core/utils/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_models.dart';
import '../../core/widgets/toast_notification.dart';
import 'group_info_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  Message? _replyToMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();
      
      chatProvider.setCurrentChatRoom(widget.chatRoom);
      
      if (authProvider.user != null) {
        chatProvider.resetUnreadCount(widget.chatRoom.id, authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_replyToMessage != null) _buildReplyPreview(),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          _buildChatAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getChatDisplayName(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.chatRoom.type == ChatType.group)
                  Text(
                    '${widget.chatRoom.participants.length} members',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  )
                else
                  Text(
                    'Active Now',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (widget.chatRoom.type == ChatType.group)
          IconButton(
            onPressed: () => _showGroupInfo(),
            icon: const Icon(Icons.info_outline),
          )
        else
          IconButton(
            onPressed: () => _showChatInfo(),
            icon: const Icon(Icons.more_vert),
          ),
      ],
    );
  }

  Widget _buildChatAvatar() {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        color: widget.chatRoom.type == ChatType.group
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Center(
        child: widget.chatRoom.type == ChatType.group
            ? Icon(Icons.group, color: Colors.white, size: 20.r)
            : Text(
          _getChatDisplayName().isNotEmpty
              ? _getChatDisplayName()[0].toUpperCase()
              : 'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyToMessage == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 4.w,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyToMessage!.senderName}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _replyToMessage!.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyToMessage = null),
            icon: Icon(Icons.close, size: 18.r),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer2<ChatProvider, AuthProvider>(
      builder: (context, chatProvider, authProvider, child) {
        if (chatProvider.isLoading && chatProvider.currentMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<Message>>(
          stream: chatProvider.streamMessages(widget.chatRoom.id),
          builder: (context, snapshot) {
            final messages = snapshot.data ?? chatProvider.currentMessages;

            if (messages.isEmpty) {
              return _buildEmptyMessagesState();
            }

            return ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final currentUserId = authProvider.user?.uid ?? '';
                final isFromCurrentUser = message.senderId == currentUserId;

                return _buildMessageBubble(message, isFromCurrentUser);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              widget.chatRoom.type == ChatType.group
                  ? Icons.group_outlined
                  : Icons.chat_bubble_outline,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            widget.chatRoom.type == ChatType.group
                ? 'Welcome to ${widget.chatRoom.name}!'
                : 'Start your conversation',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.chatRoom.type == ChatType.group
                ? 'This is the beginning of your group conversation.'
                : 'Send a message to start chatting.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isFromCurrentUser) {
    if (message.isSystemMessage) {
      return _buildSystemMessage(message);
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isFromCurrentUser),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          mainAxisAlignment: isFromCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isFromCurrentUser && widget.chatRoom.type == ChatType.group)
              _buildMessageAvatar(message.senderName),

            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 0.75.sw,
                ),
                margin: EdgeInsets.only(
                  left: isFromCurrentUser ? 40.w : 8.w,
                  right: isFromCurrentUser ? 8.w : 40.w,
                ),
                child: Column(
                  crossAxisAlignment: isFromCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isFromCurrentUser && widget.chatRoom.type == ChatType.group)
                      Padding(
                        padding: EdgeInsets.only(left: 12.w, bottom: 4.h),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: _getColorForUser(message.senderId),
                          ),
                        ),
                      ),

                    if (message.replyToMessageId != null)
                      _buildReplyIndicator(message),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: isFromCurrentUser
                            ? AppTheme.primaryGradient
                            : null,
                        color: isFromCurrentUser
                            ? null
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                          bottomLeft: Radius.circular(isFromCurrentUser ? 16.r : 4.r),
                          bottomRight: Radius.circular(isFromCurrentUser ? 4.r : 16.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.type == MessageType.image)
                            GestureDetector(
                              onTap: () => _showFullImage(message.content),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.network(
                                  message.content,
                                  width: 250.w,
                                  height: 250.h,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 250.w,
                                      height: 250.h,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.error, size: 24.r),
                                ),
                              ),
                            )
                          else if (message.type == MessageType.file)
                            GestureDetector(
                              onTap: () => _openFile(message.content),
                              child: Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: isFromCurrentUser
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file,
                                      color: isFromCurrentUser
                                          ? Colors.white
                                          : AppTheme.primaryColor,
                                      size: 24.r,
                                    ),
                                    SizedBox(width: 12.w),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.metadata['fileName'] ?? 'Document',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color: isFromCurrentUser
                                                  ? Colors.white
                                                  : Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (message.metadata['fileSize'] != null)
                                            Text(
                                              '${(message.metadata['fileSize'] / 1024).toStringAsFixed(1)} KB',
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: isFromCurrentUser
                                                    ? Colors.white70
                                                    : Theme.of(context).textTheme.bodySmall?.color,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Text(
                              message.content,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: isFromCurrentUser
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),

                          SizedBox(height: 4.h),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(message.timestamp),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isFromCurrentUser
                                      ? Colors.white70
                                      : Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),

                              if (message.isEdited) ...[
                                SizedBox(width: 4.w),
                                Text(
                                  '(edited)',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontStyle: FontStyle.italic,
                                    color: isFromCurrentUser
                                        ? Colors.white60
                                        : Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],

                              if (isFromCurrentUser) ...[
                                SizedBox(width: 4.w),
                                Icon(
                                  _getMessageStatusIcon(message.status),
                                  size: 12.r,
                                  color: Colors.white70,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildSystemMessage(Message message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageAvatar(String senderName) {
    return Container(
      width: 24.r,
      height: 24.r,
      margin: EdgeInsets.only(right: 8.w, top: 16.h),
      decoration: BoxDecoration(
        color: _getColorForUser(senderName),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyIndicator(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final repliedTo = chatProvider.currentMessages.firstWhere(
            (m) => m.id == message.replyToMessageId,
            orElse: () => Message(
              id: '',
              chatRoomId: '',
              senderId: '',
              senderName: 'Original Message',
              content: 'Message deleted or unavailable',
              timestamp: DateTime.now(),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Replying to ${repliedTo.senderName}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                repliedTo.content,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: Icon(Icons.attach_file, size: 24.r),
              color: AppTheme.primaryColor,
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(fontSize: 16.sp),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            Consumer2<ChatProvider, AuthProvider>(
              builder: (context, chatProvider, authProvider, child) {
                return FloatingActionButton.small(
                  onPressed: chatProvider.isLoading ? null : () => _sendMessage(),
                  backgroundColor: AppTheme.primaryColor,
                  child: chatProvider.isLoading
                      ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Icon(Icons.send, color: Colors.white, size: 20.r),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getChatDisplayName() {
    if (widget.chatRoom.type == ChatType.group) {
      return widget.chatRoom.name;
    }
    return widget.chatRoom.name.isNotEmpty ? widget.chatRoom.name : 'Private Chat';
  }

  Color _getColorForUser(String identifier) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final hash = identifier.hashCode;
    return colors[hash.abs() % colors.length];
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.user == null || authProvider.appUser == null) return;

    chatProvider.sendMessage(
      widget.chatRoom.id,
      authProvider.user!.uid,
      authProvider.appUser!.fullName,
      content,
      replyToMessageId: _replyToMessage?.id,
    );

    _messageController.clear();
    setState(() {
      _replyToMessage = null;
    });

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showMessageOptions(Message message, bool isFromCurrentUser) {
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

            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessage = message;
                });
                _messageFocusNode.requestFocus();
              },
            ),

            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                // Copy to clipboard logic here
                ToastNotification.showInfo(context, 'Message copied to clipboard');
              },
            ),

            if (isFromCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(message);
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }





  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image_rounded,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        _sendMediaMessage(File(image.path), MessageType.image);
      }
    } catch (e) {
      ToastNotification.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        _sendMediaMessage(File(result.files.single.path!), MessageType.file);
      }
    } catch (e) {
      ToastNotification.showError(context, 'Failed to pick file: $e');
    }
  }

  Future<void> _sendMediaMessage(File file, MessageType type) async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user == null || authProvider.appUser == null) return;

    final folder = type == MessageType.image ? 'chat_images' : 'chat_files';
    final downloadUrl = await chatProvider.uploadFile(file, folder);

    if (downloadUrl != null) {
      Map<String, dynamic> metadata = {};
      if (type == MessageType.file) {
        metadata = {
          'fileName': file.path.split('/').last,
          'fileSize': await file.length(),
        };
      }

      await chatProvider.sendMessage(
        widget.chatRoom.id,
        authProvider.user!.uid,
        authProvider.appUser!.fullName,
        downloadUrl,
        type: type,
        metadata: metadata,
        replyToMessageId: _replyToMessage?.id,
      );

      _scrollToBottom();
      
      setState(() {
        _replyToMessage = null;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ToastNotification.showError(context, 'Could not open file');
      }
    }
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32.r,
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _editMessage(Message message) {
    _messageController.text = message.content;
    _messageFocusNode.requestFocus();

    // In production, you'd implement message editing logic here
    ToastNotification.showInfo(context, 'Message editing will be implemented');
  }

  void _showDeleteConfirmation(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In production, implement message deletion
              ToastNotification.showInfo(context, 'Message deletion will be implemented');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupInfoScreen(chatRoom: widget.chatRoom),
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            Text(
              'Chat Options',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            ListTile(
              leading: Icon(Icons.search, size: 24.r),
              title: Text('Search Messages', style: TextStyle(fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(context);
                // Implement message search
              },
            ),

            ListTile(
              leading: Icon(Icons.notifications_off, size: 24.r),
              title: Text('Mute Notifications', style: TextStyle(fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(context);
                // Implement mute functionality
              },
            ),

            ListTile(
              leading: Icon(Icons.block, color: Colors.red, size: 24.r),
              title: Text('Block User', style: TextStyle(color: Colors.red, fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(context);
                // Implement block functionality
              },
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
