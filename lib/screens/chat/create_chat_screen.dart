import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_models.dart';
import '../../models/app_models.dart';
import '../../core/widgets/toast_notification.dart';
import 'chat_screen.dart';

class CreateChatScreen extends StatefulWidget {
  final ChatType chatType;

  const CreateChatScreen({super.key, required this.chatType});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  List<String> _selectedUserIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers(); // Assume this loads all foundation members
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatType == ChatType.individual ? 'New Private Chat' : 'New Group Chat',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
            if (widget.chatType == ChatType.group) _buildGroupDetailsForm(),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createChat,
        backgroundColor: AppTheme.primaryColor,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16.r),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 16.sp),
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: TextStyle(fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, size: 24.r),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: Icon(Icons.clear, size: 20.r),
          )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildGroupDetailsForm() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _groupNameController,
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: 'Group Name',
              hintStyle: TextStyle(fontSize: 14.sp),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _groupDescriptionController,
            style: TextStyle(fontSize: 16.sp),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Group Description (optional)',
              hintStyle: TextStyle(fontSize: 14.sp),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Consumer3<UserProvider, AuthProvider, ChatProvider>(
      builder: (context, userProvider, authProvider, chatProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = authProvider.user?.uid ?? '';
        final searchQuery = _searchController.text.toLowerCase();

        final filteredUsers = userProvider.users.where((user) {
          if (user.uid == currentUserId) return false; // Exclude self
          final name = user.fullName.toLowerCase();
          final email = user.email.toLowerCase();
          return name.contains(searchQuery) || email.contains(searchQuery);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('No members found'));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final isSelected = _selectedUserIds.contains(user.uid);

            return ListTile(
              leading: CircleAvatar(
                radius: 20.r,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(user.fullName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              subtitle: Text(user.email, style: TextStyle(fontSize: 13.sp)),
              trailing: widget.chatType == ChatType.individual
                  ? Radio<String>(
                value: user.uid,
                groupValue: _selectedUserIds.isNotEmpty ? _selectedUserIds[0] : null,
                onChanged: (value) {
                  setState(() {
                    _selectedUserIds = value != null ? [value] : [];
                  });
                },
              )
                  : Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedUserIds.add(user.uid);
                    } else {
                      _selectedUserIds.remove(user.uid);
                    }
                  });
                },
              ),
              onTap: () {
                if (widget.chatType == ChatType.individual) {
                  setState(() {
                    _selectedUserIds = [user.uid];
                  });
                } else {
                  setState(() {
                    if (isSelected) {
                      _selectedUserIds.remove(user.uid);
                    } else {
                      _selectedUserIds.add(user.uid);
                    }
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _createChat() async {
    if (_selectedUserIds.isEmpty) {
      ToastNotification.showError(context, 'Please select at least one member');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.user;
    final currentUserName = authProvider.appUser?.fullName ?? 'User';

    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    ChatRoom? newChatRoom;

    if (widget.chatType == ChatType.individual) {
      final otherUserId = _selectedUserIds.first;
      final otherUser = context.read<UserProvider>().getUserById(otherUserId);
      final otherUserName = otherUser?.fullName ?? 'User';
      newChatRoom = await chatProvider.createIndividualChat(
        currentUser.uid,
        otherUserId,
        currentUserName,
        otherUserName,
      );
    } else {
      if (_groupNameController.text.trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ToastNotification.showError(context, 'Please enter a group name');
        return;
      }

      newChatRoom = await chatProvider.createGroupChat(
        currentUser.uid,
        currentUserName,
        _groupNameController.text.trim(),
        _groupDescriptionController.text.trim(),
        _selectedUserIds,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (newChatRoom != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoom: newChatRoom!),
        ),
      );
    } else {
      ToastNotification.showError(context, chatProvider.errorMessage ?? 'Failed to create chat');
    }
  }
}