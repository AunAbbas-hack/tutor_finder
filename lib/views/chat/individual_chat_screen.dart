// lib/views/chat/individual_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../viewmodels/individual_chat_vm.dart';
import '../../data/models/message_model.dart';
import '../../data/models/chat_model.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/user_services.dart';
import '../../parent_viewmodels/chat_vm.dart';
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
                _buildMessageBubble(message, isSent, vm, context),
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
    BuildContext context,
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
          // Message Bubble with Long Press Menu
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, message, vm, isSent),
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
          GestureDetector(
            onTap: () => _showFullScreenImage(message.imageUrl!),
            child: ClipRRect(
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
    return Consumer<IndividualChatViewModel>(
      builder: (context, vm, _) {
        final isDownloading = vm.isLoading;
        
        return GestureDetector(
          onTap: () {
            // Open file when user taps on document (not on download button)
            if (message.imageUrl != null && message.fileName != null) {
              _openFile(vm, message);
            }
          },
          child: Container(
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
                  GestureDetector(
                    // Stop tap from propagating to parent
                    onTap: () {
                      if (!isDownloading) {
                        _downloadFile(vm, message);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: isDownloading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isSent ? Colors.white : AppColors.primary,
                              ),
                            )
                          : Icon(
                              Icons.download,
                              color: isSent ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

  // ---------- Download File ----------
  Future<void> _downloadFile(
    IndividualChatViewModel vm,
    MessageModel message,
  ) async {
    if (message.imageUrl == null || message.fileName == null) {
      Get.snackbar(
        'Error',
        'File URL or filename not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      final success = await vm.downloadFile(
        fileUrl: message.imageUrl!,
        fileName: message.fileName!,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'File downloaded successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          vm.errorMessage ?? 'Failed to download file',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ---------- Open File ----------
  Future<void> _openFile(
    IndividualChatViewModel vm,
    MessageModel message,
  ) async {
    if (message.imageUrl == null || message.fileName == null) {
      Get.snackbar(
        'Error',
        'File URL or filename not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      final success = await vm.openFile(
        fileUrl: message.imageUrl!,
        fileName: message.fileName!,
      );

      if (!success) {
        Get.snackbar(
          'Error',
          vm.errorMessage ?? 'Failed to open file. Please make sure you have an app installed to open this file type.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
      // If success, file opens automatically, no need to show snackbar
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ---------- Full Screen Image Viewer ----------
  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
        fullscreenDialog: true,
      ),
    );
  }

  // ---------- Message Options Menu ----------
  void _showMessageOptions(
    BuildContext context,
    MessageModel message,
    IndividualChatViewModel vm,
    bool isSent,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Options
              ListTile(
                leading: const Icon(Icons.forward, color: AppColors.primary),
                title: const AppText(
                  'Forward',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showForwardDialog(context, message, vm);
                },
              ),
              if (isSent) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const AppText(
                    'Delete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, message, vm);
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Delete Confirmation ----------
  void _showDeleteConfirmation(
    BuildContext context,
    MessageModel message,
    IndividualChatViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const AppText(
          'Delete Message',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: const AppText(
          'Are you sure you want to delete this message?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGrey,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await vm.deleteMessage(message.messageId);
              if (success) {
                Get.snackbar(
                  'Success',
                  'Message deleted',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'Error',
                  vm.errorMessage ?? 'Failed to delete message',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: const AppText(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Forward Dialog ----------
  void _showForwardDialog(
    BuildContext context,
    MessageModel message,
    IndividualChatViewModel vm,
  ) {
    // Get conversations list for forwarding
    showDialog(
      context: context,
      builder: (context) => _ForwardDialog(
        message: message,
        currentUserId: vm.currentUserId ?? '',
        otherUserId: widget.otherUserId,
      ),
    );
  }
}

// Forward Dialog Widget
class _ForwardDialog extends StatefulWidget {
  final MessageModel message;
  final String currentUserId;
  final String otherUserId;

  const _ForwardDialog({
    required this.message,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<_ForwardDialog> createState() => _ForwardDialogState();
}

class _ForwardDialogState extends State<_ForwardDialog> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  List<ConversationItem> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get conversations stream
      final stream = _chatService.getConversationsStream();
      await for (final chats in stream) {
        if (!mounted) return;
        
        final List<ConversationItem> items = [];
        
        for (var chat in chats) {
          try {
            // Get other participant's ID
            final otherParticipantId = chat.participant1Id == widget.currentUserId
                ? chat.participant2Id
                : chat.participant1Id;
            
            // Skip if it's the same conversation
            if (otherParticipantId == widget.otherUserId) {
              continue;
            }
            
            // Get user data
            final otherUser = await _userService.getUserById(otherParticipantId);
            
            // Get unread count
            final unreadCount = chat.unreadCount?[widget.currentUserId] ?? 0;
            
            items.add(ConversationItem(
              chat: chat,
              otherUser: otherUser,
              unreadCount: unreadCount,
              lastMessagePreview: chat.lastMessage,
              lastMessageTime: chat.lastMessageTime != null
                  ? DateTime.fromMillisecondsSinceEpoch(chat.lastMessageTime!)
                  : null,
            ));
          } catch (e) {
            continue;
          }
        }
        
        if (mounted) {
          setState(() {
            _conversations = items;
            _isLoading = false;
          });
        }
        
        // Only take first emission
        break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load conversations: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _forwardToUser(String receiverId) async {
    try {
      await _chatService.forwardMessage(
        originalMessage: widget.message,
        receiverId: receiverId,
      );
      
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'Success',
          'Message forwarded',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to forward message: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const AppText(
                    'Forward to',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: AppText(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _conversations.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: const AppText(
                                  'No conversations available',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                final conversation = _conversations[index];
                                final otherUser = conversation.otherUser;
                                final userName = otherUser?.name ?? 'Unknown User';
                                final userImageUrl = otherUser?.imageUrl;

                                return ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.lightBackground,
                                      image: userImageUrl != null &&
                                              userImageUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(userImageUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: userImageUrl == null ||
                                            userImageUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: AppColors.iconGrey,
                                          )
                                        : null,
                                  ),
                                  title: AppText(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  onTap: () {
                                    if (otherUser != null) {
                                      _forwardToUser(otherUser.userId);
                                    }
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full Screen Image Viewer Widget
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
