import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_models.dart';
import '../../models/app_models.dart';
class GroupInfoScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const GroupInfoScreen({super.key, required this.chatRoom});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _groupNameController.text = widget.chatRoom.name;
    _groupDescriptionController.text = widget.chatRoom.description ?? '';
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final isAdmin = widget.chatRoom.isUserAdmin(authProvider.user?.uid ?? '');

              if (isAdmin) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: Icon(_isEditing ? Icons.close : Icons.edit),
                );
              }
              return const SizedBox.shrink();
            },
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildGroupHeader(),
              _buildGroupDetails(),
              _buildMembersSection(),
              _buildGroupActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primaryColor,
                backgroundImage: widget.chatRoom.groupImageUrl != null
                    ? CachedNetworkImageProvider(widget.chatRoom.groupImageUrl!)
                    : null,
                child: widget.chatRoom.groupImageUrl == null
                    ? Text(
                  widget.chatRoom.name.isNotEmpty ? widget.chatRoom.name[0].toUpperCase() : 'G',
                  style: const TextStyle(color: Colors.white, fontSize: 40),
                )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: () {
                          _showUpdateGroupImageDialog(context);
                        },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGroupDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isAdmin = widget.chatRoom.isUserAdmin(authProvider.user?.uid ?? '');
          final updatedByUserName = authProvider.appUser?.fullName ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Group Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_isEditing && isAdmin)
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(hintText: 'Enter group name'),
                )
              else
                Text(widget.chatRoom.name, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_isEditing && isAdmin)
                TextField(
                  controller: _groupDescriptionController,
                  decoration: const InputDecoration(hintText: 'Enter description'),
                )
              else
                Text(widget.chatRoom.description ?? 'No description'),
              if (_isEditing && isAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await context.read<ChatProvider>().updateGroupInfo(
                        widget.chatRoom.id,
                        _groupNameController.text.trim(),
                        _groupDescriptionController.text.trim(),
                        null, // No image update here
                        updatedByUserName,
                      );
                      if (success) {
                        setState(() {
                          _isEditing = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembersSection() {
    return Consumer3<AuthProvider, UserProvider, ChatProvider>(
      builder: (context, authProvider, userProvider, chatProvider, child) {
        final isAdmin = widget.chatRoom.isUserAdmin(authProvider.user?.uid ?? '');
        final members = widget.chatRoom.participants;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Members (${members.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final uid = members[index];
                final user = userProvider.getUserById(uid); // Assuming AppUser with fullName, email
                final userName = user?.fullName ?? 'Unknown';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(userName),
                  subtitle: Text(user?.email ?? ''),
                  trailing: (isAdmin && uid != authProvider.user?.uid)
                      ? IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () async {
                      final removedById = authProvider.user?.uid ?? '';
                      final removedByName = authProvider.appUser?.fullName ?? '';
                      await chatProvider.removeParticipantFromGroup(
                        widget.chatRoom.id,
                        uid,
                        removedById,
                        removedByName,
                        userName,
                      );
                    },
                  )
                      : null,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupActions() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAdmin = widget.chatRoom.isUserAdmin(authProvider.user?.uid ?? '');
        final userId = authProvider.user?.uid ?? '';
        final userName = authProvider.appUser?.fullName ?? '';
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.green),
                  title: const Text('Add Member'),
                  onTap: () {
                    _showAddMemberDialog(context, authProvider);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text('Exit Group'),
                onTap: () async {
                  final success = await context.read<ChatProvider>().leaveGroup(
                    widget.chatRoom.id,
                    userId,
                    userName,
                  );
                  if (success) {
                    Navigator.pop(context);
                  }
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Group'),
                  onTap: () {
                    // TODO: Implement delete group logic if added to ChatProvider
                    // For now, perhaps show confirmation and delete if last admin or something
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Filter out users who are already members
          final eligibleUsers = userProvider.users.where((user) {
            return !widget.chatRoom.participants.contains(user.uid);
          }).toList();

          List<String> selectedUserIds = [];

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Add Members'),
              content: SizedBox(
                width: double.maxFinite,
                child: eligibleUsers.isEmpty
                    ? const Center(child: Text('No new users to add.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: eligibleUsers.length,
                        itemBuilder: (context, index) {
                          final user = eligibleUsers[index];
                          final isSelected = selectedUserIds.contains(user.uid);

                          return CheckboxListTile(
                            title: Text(user.fullName),
                            subtitle: Text(user.role.value),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedUserIds.add(user.uid);
                                } else {
                                  selectedUserIds.remove(user.uid);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedUserIds.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final success = await context
                              .read<ChatProvider>()
                              .addParticipantsToGroup(
                                widget.chatRoom.id,
                                selectedUserIds,
                                authProvider.user!.uid,
                                authProvider.appUser!.fullName,
                              );

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Members added successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUpdateGroupImageDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Group Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter image URL (e.g., specific link)'),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/image.png',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isEmpty) return;

              Navigator.pop(context);
              
              final authProvider = context.read<AuthProvider>();
              final updatedByUserName = authProvider.appUser?.fullName ?? 'Admin';

              final success = await context.read<ChatProvider>().updateGroupInfo(
                widget.chatRoom.id,
                null, 
                null,
                url,
                updatedByUserName,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group image updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}