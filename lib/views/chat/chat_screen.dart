// lib/views/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../parent_viewmodels/chat_vm.dart';
import 'individual_chat_screen.dart';

/// Conversations list screen (Messages screen)
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ChatViewModel();
        // Initialize after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Container(
        color: AppColors.lightBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              _buildAppBar(context),
              // Search Bar
              _buildSearchBar(context),
              // Conversations List
              Expanded(
                child: _buildConversationsList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- App Bar ----------
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          const Expanded(
            child: AppText(
              'Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Search Bar ----------
  Widget _buildSearchBar(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.lightBackground,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.iconGrey,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.iconGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        vm.clearSearch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.lightBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
            ),
            onChanged: (value) {
              vm.updateSearchQuery(value);
            },
          ),
        );
      },
    );
  }

  // ---------- Conversations List ----------
  Widget _buildConversationsList(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        final conversations = vm.filteredConversations;

        // Show loading only on initial load (first time, no data received yet)
        if (vm.isLoading && conversations.isEmpty && vm.errorMessage == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        // Show error if there's an error and no conversations
        if (vm.errorMessage != null && conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                AppText(
                  vm.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => vm.initialize(),
                  child: const AppText('Retry'),
                ),
              ],
            ),
          );
        }

        // Show "No conversations" when not loading and no conversations
        if (!vm.isLoading && conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppColors.iconGrey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const AppText(
                  'No conversations',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const AppText(
                  'Start a conversation',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vm.initialize(),
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: AppColors.border,
              indent: 80,
            ),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(context, vm, conversation);
            },
          ),
        );
      },
    );
  }

  // ---------- Conversation Tile ----------
  Widget _buildConversationTile(
    BuildContext context,
    ChatViewModel vm,
    ConversationItem conversation,
  ) {
    final otherUser = conversation.otherUser;
    final userName = otherUser?.name ?? 'Unknown User';
    final userImageUrl = otherUser?.imageUrl;
    final lastMessage = conversation.lastMessagePreview ?? '';
    final timestamp = vm.formatTimestamp(conversation.lastMessageTime);
    final unreadCount = conversation.unreadCount;
    final isOnline = vm.isUserOnline(otherUser?.userId ?? '');

    return InkWell(
      onTap: () {
        if (otherUser != null) {
          // Navigate to individual chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualChatScreen(
                otherUserId: otherUser.userId,
                otherUserName: userName,
                otherUserImageUrl: userImageUrl,
              ),
            ),
          ).then((_) {
            // Mark as read when returning
            if (otherUser.userId != null) {
              vm.markAsRead(otherUser.userId);
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.lightBackground,
        child: Row(
          children: [
            // Profile Picture with Online Status
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightBackground,
                    border: Border.all(
                      color: AppColors.border,
                      width: 2,
                    ),
                    image: userImageUrl != null && userImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(userImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: userImageUrl == null || userImageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.iconGrey,
                        )
                      : null,
                ),
                // Online Status Indicator
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        border: Border.all(
                          color: AppColors.lightBackground,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Name, Message, and Timestamp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        AppText(
                          timestamp,
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? AppColors.primary
                                : AppColors.textLight,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? AppColors.textDark
                                : AppColors.textGrey,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppText(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}

