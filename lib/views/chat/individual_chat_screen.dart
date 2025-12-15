// lib/views/chat/individual_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../viewmodels/individual_chat_vm.dart';
import '../../data/models/message_model.dart';
import '../../core/services/image_picker_service.dart';
import '../../core/services/file_picker_service.dart';

class IndividualChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImageUrl;

  const IndividualChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImageUrl,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final FilePickerService _filePickerService = FilePickerService();
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(IndividualChatViewModel vm) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    vm.setTyping(false);
    _isTyping = false;

    final success = await vm.sendMessage(text);
    if (success) {
      _scrollToBottom();
    } else {
      Get.snackbar(
        'Error',
        vm.errorMessage ?? 'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = IndividualChatViewModel(
          otherUserId: widget.otherUserId,
          otherUserName: widget.otherUserName,
          otherUserImageUrl: widget.otherUserImageUrl,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Consumer<IndividualChatViewModel>(
        builder: (context, vm, child) {
    return Scaffold(
        backgroundColor: AppColors.lightBackground,
            appBar: _buildAppBar(vm),
            body: Column(
              children: [
                Expanded(
                  child: _buildMessagesList(),
                ),
                _buildInputField(),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(IndividualChatViewModel vm) {
    final otherUser = vm.otherUser;
    final userName = otherUser?.name ?? widget.otherUserName;
    final userImageUrl = otherUser?.imageUrl ?? widget.otherUserImageUrl;
    final isOnline = vm.isOtherUserOnline;

    return AppBar(
          backgroundColor: AppColors.lightBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Get.back(),
          ),
          title: Row(
            children: [
              // Profile Picture with Online Status
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.lightBackground,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
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
                            size: 24,
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
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Name and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isOnline)
                      const AppText(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.phone, color: AppColors.textDark),
              onPressed: () {
                // TODO: Implement call functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textDark),
              onPressed: () {
                // TODO: Implement menu
              },
            ),
          ],
        );
  }

  Widget _buildMessagesList() {
    return Consumer<IndividualChatViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (vm.messages.isEmpty) {
          return Center(
            child: AppText(
              'No messages yet.\nStart the conversation!',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: vm.messagesWithDates.length + (vm.isOtherUserTyping ? 1 : 0),
          itemBuilder: (context, index) {
            // Show typing indicator at the end
            if (index == vm.messagesWithDates.length) {
              return _buildTypingIndicator();
            }

            final messageWithDate = vm.messagesWithDates[index];
            final message = messageWithDate.message;
            final isSent = message.senderId == vm.currentUserId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Separator
                if (messageWithDate.showDateSeparator)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
        child: AppText(
                          messageWithDate.dateLabel ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Message Bubble
                _buildMessageBubble(message, isSent, vm),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isSent,
    IndividualChatViewModel vm,
  ) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (only for received messages)
          if (!isSent) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightBackground,
                image: widget.otherUserImageUrl != null &&
                        widget.otherUserImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.otherUserImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.otherUserImageUrl == null ||
                      widget.otherUserImageUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.iconGrey,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSent ? AppColors.primary : AppColors.lightBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSent ? 16 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Text, Image, or File
                  if (message.type == MessageType.image)
                    _buildImageMessage(message, isSent)
                  else if (message.type == MessageType.file)
                    _buildFileAttachment(message, isSent)
                  else
                    AppText(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSent ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Timestamp
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        vm.formatBubbleTime(message),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSent
                              ? Colors.white70
                              : AppColors.textGrey,
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(MessageModel message, bool isSent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.imageUrl!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: AppColors.lightBackground,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: AppColors.lightBackground,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppColors.iconGrey,
                  ),
                );
              },
            ),
          ),
        if (message.text.isNotEmpty && message.text != 'Image')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppText(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isSent ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileAttachment(MessageModel message, bool isSent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSent
            ? Colors.white.withOpacity(0.2)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isSent ? Colors.white : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  message.fileName ?? 'File',
                  style: TextStyle(
                    color: isSent ? Colors.white : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.text.isNotEmpty)
                  AppText(
                    message.text,
                    style: TextStyle(
                      color: isSent ? Colors.white70 : AppColors.textGrey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (message.imageUrl != null)
            IconButton(
              icon: Icon(
                Icons.download,
                color: isSent ? Colors.white : AppColors.primary,
                size: 20,
              ),
              onPressed: () {
                // TODO: Implement file download
                Get.snackbar(
                  'Download',
                  'File download will be implemented',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.primary,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBackground,
              image: widget.otherUserImageUrl != null &&
                      widget.otherUserImageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.otherUserImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.otherUserImageUrl == null ||
                    widget.otherUserImageUrl!.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.iconGrey,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: const Radius.circular(4),
                bottomRight: const Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textGrey,
      ),
    );
  }

  Widget _buildInputField() {
    return Consumer<IndividualChatViewModel>(
      builder: (context, vm, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Add Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _showAttachmentOptions(context, vm),
                  ),
                ),
                const SizedBox(width: 12),
                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: AppColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onChanged: (text) {
                      final wasTyping = _isTyping;
                      _isTyping = text.trim().isNotEmpty;

                      if (_isTyping != wasTyping) {
                        vm.setTyping(_isTyping);
                      }
                    },
                    onSubmitted: (text) => _sendMessage(vm),
                  ),
                ),
                const SizedBox(width: 12),
                // Send Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(vm),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentOptions(BuildContext context, IndividualChatViewModel vm) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Options
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                ),
                title: const AppText(
                  'Photo from Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _pickImageFromGallery(vm);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                ),
                title: const AppText(
                  'Take Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _pickImageFromCamera(vm);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insert_drive_file,
                    color: AppColors.primary,
                  ),
                ),
                title: const AppText(
                  'Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _pickFile(vm);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _pickImageFromGallery(IndividualChatViewModel vm) async {
    try {
      final imageFile = await _imagePickerService.pickImageFromGallery();
      if (imageFile != null) {
        final success = await vm.sendImageMessage(imageFile, null);
        if (success) {
          _scrollToBottom();
        } else {
          Get.snackbar(
            'Error',
            vm.errorMessage ?? 'Failed to send image',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _pickImageFromCamera(IndividualChatViewModel vm) async {
    try {
      final imageFile = await _imagePickerService.pickImageFromCamera();
      if (imageFile != null) {
        final success = await vm.sendImageMessage(imageFile, null);
        if (success) {
          _scrollToBottom();
        } else {
          Get.snackbar(
            'Error',
            vm.errorMessage ?? 'Failed to send image',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to take photo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _pickFile(IndividualChatViewModel vm) async {
    try {
      final platformFile = await _filePickerService.pickDocument();
      if (platformFile != null && platformFile.path != null) {
        final file = File(platformFile.path!);
        final fileName = platformFile.name;
        
        final success = await vm.sendFileMessage(file, fileName);
        if (success) {
          _scrollToBottom();
        } else {
          Get.snackbar(
            'Error',
            vm.errorMessage ?? 'Failed to send file',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
