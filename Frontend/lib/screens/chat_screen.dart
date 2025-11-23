import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../widgets/neon_appbar.dart';
import '../services/api_service.dart';
import '../models/status_item.dart' as models;

class ChatScreen extends StatefulWidget {
  final String? userId;
  final String? username;

  const ChatScreen({super.key, this.userId, this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<ChatMessage> _messages = [];
  final List<ChatStatusItem> _statuses = [];
  final List<Map<String, dynamic>> _chats = [];
  String? _currentChatId;
  String? _currentChatUserId;
  String? _currentChatUsername;
  String? _currentUserUsername;
  bool _isTyping = false;
  bool _isLoading = true;
  bool _isLoadingChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    // Get current user's username
    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _currentUserUsername = profile.username;
        });
      }
    } catch (e) {
      debugPrint('Error loading current user profile: $e');
    }

    // If userId is provided, create/get chat with that user
    if (widget.userId != null) {
      await _loadOrCreateChat(widget.userId!, widget.username);
    } else {
      // Otherwise, load chat list
      await _loadChats();
    }

    // Load statuses
    await _loadStatuses();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadOrCreateChat(String userId, String? username) async {
    setState(() {
      _isLoadingChat = true;
    });
    try {
      final chatData = await _apiService.getOrCreateChat(userId);
      if (chatData != null && mounted) {
        setState(() {
          _currentChatId = chatData['id'] as String?;
          _currentChatUserId = userId;
          _currentChatUsername = username ?? (chatData['participants_data'] as List?)?.first?['username'] as String?;
        });
        await _loadChatMessages();
        await _loadChats(); // Refresh chat list
      }
    } catch (e) {
      debugPrint('Error loading/creating chat: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChat = false;
        });
      }
    }
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _apiService.getChats();
      if (mounted) {
        setState(() {
          _chats.clear();
          _chats.addAll(chats);
        });
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
    }
  }

  Future<void> _loadChatMessages() async {
    if (_currentChatId == null) return;
    
    try {
      final messages = await _apiService.getChatMessages(_currentChatId!);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages.map((m) => ChatMessage(
            id: m['id'] as String? ?? '',
            senderName: m['senderName'] as String? ?? 'Unknown',
            message: m['message'] as String? ?? '',
            timestamp: m['createdAt'] != null 
                ? DateTime.parse(m['createdAt'] as String)
                : DateTime.now(),
            isRead: m['isRead'] as bool? ?? false,
          )));
        });
        // Mark chat as read
        await _apiService.markChatAsRead(_currentChatId!);
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _apiService.getStatuses();
      if (mounted) {
        setState(() {
          _statuses.clear();
          _statuses.addAll(statuses.map((s) => ChatStatusItem(
            id: s.id,
            userName: 'User ${s.userId}',
            profileImageUrl: s.imageUrl,
            timestamp: s.createdAt,
            isViewed: s.viewsCount > 0,
          )));
        });
      }
    } catch (e) {
      debugPrint('Error loading statuses: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_currentChatId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isTyping = false;
    });

    try {
      final sentMessage = await _apiService.sendMessage(_currentChatId!, messageText);
      if (sentMessage != null && mounted) {
        // Reload messages to get the server response
        await _loadChatMessages();
        await _loadChats(); // Refresh chat list to update last message
      }
      await _playMessageSound();
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playMessageSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      try {
        await _audioPlayer.setAsset('assets/sounds/telegram_message.mp3');
        await _audioPlayer.play();
      } catch (e2) {
        // Both methods failed, continue without sound
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      body: Column(
        children: [
          // Enhanced Header with gradient and better styling
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VyRaTheme.primaryBlack,
                  VyRaTheme.darkGrey,
                  VyRaTheme.primaryBlack,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: VyRaTheme.primaryCyan.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    // Animated title with glow effect
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            VyRaTheme.primaryCyan.withOpacity(0.2),
                            VyRaTheme.primaryCyan.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: VyRaTheme.primaryCyan.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.message_rounded,
                            color: VyRaTheme.primaryCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Messages',
                            style: TextStyle(
                              color: VyRaTheme.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
                    const Spacer(),
                    // Enhanced action buttons with animations
                    Container(
                      decoration: BoxDecoration(
                        color: VyRaTheme.darkGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: VyRaTheme.primaryCyan.withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: VyRaTheme.primaryCyan.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.search,
                                color: VyRaTheme.primaryCyan,
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/find-friends');
                            },
                            tooltip: 'Find Friends',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: VyRaTheme.primaryCyan.withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: VyRaTheme.primaryCyan.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_outlined,
                                color: VyRaTheme.primaryCyan,
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/find-friends');
                            },
                            tooltip: 'New Chat',
                          ),
                        ],
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
          // Enhanced TabBar with better styling
          Container(
            decoration: BoxDecoration(
              color: VyRaTheme.darkGrey,
              border: Border(
                bottom: BorderSide(
                  color: VyRaTheme.primaryCyan.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: VyRaTheme.primaryCyan,
              indicatorWeight: 3,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(
                  color: VyRaTheme.primaryCyan,
                  width: 3,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 40),
              ),
              labelColor: VyRaTheme.primaryCyan,
              unselectedLabelColor: VyRaTheme.textGrey,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Chats'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Status'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatsTab(),
                _buildStatusTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    // If we have a current chat, show the chat interface
    if (_currentChatId != null) {
      return _buildChatInterface();
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VyRaTheme.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: VyRaTheme.primaryCyan,
                strokeWidth: 3,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 20),
            Text(
              'Loading conversations...',
              style: const TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      );
    }
    
    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.1),
                    VyRaTheme.primaryCyan.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 80,
                color: VyRaTheme.primaryCyan,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'No messages yet',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation with your friends!',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 14,
              ),
            ).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/find-friends');
              },
              icon: const Icon(Icons.person_search),
              label: const Text('Find Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VyRaTheme.primaryCyan,
                foregroundColor: VyRaTheme.primaryBlack,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                shadowColor: VyRaTheme.primaryCyan.withOpacity(0.5),
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
          ],
        ),
      );
    }
    
    // Show chat list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        return _buildChatListItem(_chats[index], index);
      },
    );
  }

  Widget _buildChatInterface() {
    if (_isLoadingChat) {
      return const Center(
        child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
      );
    }

    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VyRaTheme.darkGrey,
            border: Border(
              bottom: BorderSide(
                color: VyRaTheme.primaryCyan.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: VyRaTheme.textWhite),
                onPressed: () {
                  setState(() {
                    _currentChatId = null;
                    _currentChatUserId = null;
                    _currentChatUsername = null;
                    _messages.clear();
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '@${_currentChatUsername ?? 'User'}',
                  style: const TextStyle(
                    color: VyRaTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(
                      color: VyRaTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final senderName = message.senderName;
                    final isMe = senderName == _currentUserUsername || senderName == 'You';
                    return _buildMessageBubble(message, isMe);
                  },
                ),
        ),
        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VyRaTheme.darkGrey,
            border: Border(
              top: BorderSide(
                color: VyRaTheme.primaryCyan.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: VyRaTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: VyRaTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: VyRaTheme.textGrey.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isTyping = value.isNotEmpty;
                      });
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isTyping
                        ? [VyRaTheme.primaryCyan, VyRaTheme.primaryCyan.withOpacity(0.8)]
                        : [VyRaTheme.mediumGrey, VyRaTheme.mediumGrey],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: VyRaTheme.primaryBlack,
                  ),
                  onPressed: _isTyping ? _sendMessage : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan,
                    VyRaTheme.primaryCyan.withOpacity(0.8),
                  ],
                )
              : null,
          color: isMe ? null : VyRaTheme.mediumGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? VyRaTheme.primaryBlack : VyRaTheme.textWhite,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe
                    ? VyRaTheme.primaryBlack.withOpacity(0.7)
                    : VyRaTheme.textGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> chat, int index) {
    final participants = chat['participants_data'] as List? ?? [];
    final otherUser = participants.isNotEmpty ? participants[0] : null;
    final lastMessage = chat['last_message'] as Map<String, dynamic>?;
    final unreadCount = chat['unread_count'] as int? ?? 0;
    final updatedAt = chat['updatedAt'] != null
        ? DateTime.parse(chat['updatedAt'] as String)
        : DateTime.now();

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentChatId = chat['id'] as String?;
          _currentChatUserId = otherUser?['id'] as String?;
          _currentChatUsername = otherUser?['username'] as String?;
        });
        _loadChatMessages();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: unreadCount > 0
              ? LinearGradient(
                  colors: [
                    VyRaTheme.darkGrey,
                    VyRaTheme.primaryCyan.withOpacity(0.05),
                  ],
                )
              : null,
          color: unreadCount == 0 ? VyRaTheme.darkGrey : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unreadCount > 0
                ? VyRaTheme.primaryCyan.withOpacity(0.5)
                : VyRaTheme.lightGrey.withOpacity(0.2),
            width: unreadCount > 0 ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unreadCount > 0
                    ? LinearGradient(
                        colors: [
                          VyRaTheme.primaryCyan,
                          VyRaTheme.primaryCyan.withOpacity(0.5),
                        ],
                      )
                    : null,
                color: unreadCount == 0 ? VyRaTheme.mediumGrey : null,
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VyRaTheme.mediumGrey,
                ),
                child: const Icon(
                  Icons.person,
                  color: VyRaTheme.textWhite,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '@${otherUser?['username'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: VyRaTheme.textWhite,
                            fontSize: 17,
                            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(updatedAt),
                        style: TextStyle(
                          color: unreadCount > 0 ? VyRaTheme.primaryCyan : VyRaTheme.textGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage?['message'] as String? ?? 'No messages yet',
                    style: TextStyle(
                      color: unreadCount > 0
                          ? VyRaTheme.textWhite.withOpacity(0.9)
                          : VyRaTheme.textGrey,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: VyRaTheme.primaryCyan,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: VyRaTheme.primaryBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatMessage message, int index) {
    // This method is deprecated - using _buildChatListItem instead
    // Keeping for backward compatibility
    return const SizedBox.shrink();
  }

  Widget _buildChatItemOld(ChatMessage message, int index) {
    return GestureDetector(
      onTap: () {
        _openChat(message);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: !message.isRead
              ? LinearGradient(
                  colors: [
                    VyRaTheme.darkGrey,
                    VyRaTheme.primaryCyan.withOpacity(0.05),
                  ],
                )
              : null,
          color: message.isRead ? VyRaTheme.darkGrey : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !message.isRead
                ? VyRaTheme.primaryCyan.withOpacity(0.5)
                : VyRaTheme.lightGrey.withOpacity(0.2),
            width: !message.isRead ? 2 : 1,
          ),
          boxShadow: !message.isRead
              ? [
                  BoxShadow(
                    color: VyRaTheme.primaryCyan.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Enhanced profile picture with gradient border
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !message.isRead
                    ? LinearGradient(
                        colors: [
                          VyRaTheme.primaryCyan,
                          VyRaTheme.primaryCyan.withOpacity(0.5),
                        ],
                      )
                    : null,
                color: message.isRead ? VyRaTheme.mediumGrey : null,
                boxShadow: !message.isRead
                    ? [
                        BoxShadow(
                          color: VyRaTheme.primaryCyan.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VyRaTheme.mediumGrey,
                ),
                child: const Icon(
                  Icons.person,
                  color: VyRaTheme.textWhite,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            color: VyRaTheme.textWhite,
                            fontSize: 17,
                            fontWeight: !message.isRead ? FontWeight.w700 : FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: !message.isRead
                              ? VyRaTheme.primaryCyan.withOpacity(0.2)
                              : VyRaTheme.mediumGrey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: !message.isRead ? VyRaTheme.primaryCyan : VyRaTheme.textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: !message.isRead ? VyRaTheme.textWhite.withOpacity(0.9) : VyRaTheme.textGrey,
                      fontSize: 14,
                      fontWeight: !message.isRead ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!message.isRead) ...[
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: VyRaTheme.primaryCyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: VyRaTheme.primaryCyan,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 800.ms),
            ],
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
    );
  }

  Widget _buildStatusTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VyRaTheme.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: VyRaTheme.primaryCyan,
                strokeWidth: 3,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 20),
            Text(
              'Loading status updates...',
              style: const TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      );
    }
    
    if (_statuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.1),
                    VyRaTheme.primaryCyan.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.circle_outlined,
                size: 80,
                color: VyRaTheme.primaryCyan,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'No status updates',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 8),
            const Text(
              'Check back later for new updates',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 14,
              ),
            ).animate(delay: 300.ms).fadeIn(),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _statuses.length,
      itemBuilder: (context, index) {
        final status = _statuses[index];
        return _buildStatusItem(status, index);
      },
    );
  }

  Widget _buildStatusItem(ChatStatusItem status, int index) {
    return GestureDetector(
      onTap: () {
        _viewStatus(status);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: !status.isViewed
              ? LinearGradient(
                  colors: [
                    VyRaTheme.darkGrey,
                    VyRaTheme.primaryCyan.withOpacity(0.05),
                  ],
                )
              : null,
          color: status.isViewed ? VyRaTheme.darkGrey : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !status.isViewed
                ? VyRaTheme.primaryCyan.withOpacity(0.5)
                : VyRaTheme.lightGrey.withOpacity(0.2),
            width: !status.isViewed ? 2 : 1,
          ),
          boxShadow: !status.isViewed
              ? [
                  BoxShadow(
                    color: VyRaTheme.primaryCyan.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !status.isViewed
                    ? LinearGradient(
                        colors: [
                          VyRaTheme.primaryCyan,
                          VyRaTheme.primaryCyan.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: status.isViewed ? VyRaTheme.mediumGrey : null,
                boxShadow: !status.isViewed
                    ? [
                        BoxShadow(
                          color: VyRaTheme.primaryCyan.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VyRaTheme.mediumGrey,
                  image: status.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(status.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: status.profileImageUrl == null
                    ? const Icon(
                        Icons.person,
                        color: VyRaTheme.textWhite,
                        size: 32,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.userName,
                    style: TextStyle(
                      color: VyRaTheme.textWhite,
                      fontSize: 17,
                      fontWeight: !status.isViewed ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: !status.isViewed
                          ? VyRaTheme.primaryCyan.withOpacity(0.2)
                          : VyRaTheme.mediumGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatTime(status.timestamp),
                      style: TextStyle(
                        color: !status.isViewed ? VyRaTheme.primaryCyan : VyRaTheme.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!status.isViewed) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VyRaTheme.primaryCyan.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: VyRaTheme.primaryCyan,
                  size: 20,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms),
            ],
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }

  void _openChat(ChatMessage message) async {
    // This method is deprecated - chats are now opened via _buildChatListItem
    // Keeping for backward compatibility
  }

  void _openChatOld(ChatMessage message) {
    // Old modal implementation - keeping for reference
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VyRaTheme.darkGrey,
              VyRaTheme.mediumGrey,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: VyRaTheme.primaryCyan.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: VyRaTheme.textGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          VyRaTheme.primaryCyan,
                          VyRaTheme.primaryCyan.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VyRaTheme.mediumGrey,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: VyRaTheme.textWhite,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            color: VyRaTheme.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Active now',
                          style: TextStyle(
                            color: VyRaTheme.primaryCyan,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VyRaTheme.primaryBlack.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: VyRaTheme.textWhite, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: VyRaTheme.primaryCyan.withOpacity(0.2), thickness: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: VyRaTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: VyRaTheme.primaryCyan.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: VyRaTheme.textWhite),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: VyRaTheme.textGrey.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isTyping = value.isNotEmpty;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isTyping
                            ? [VyRaTheme.primaryCyan, VyRaTheme.primaryCyan.withOpacity(0.8)]
                            : [VyRaTheme.mediumGrey, VyRaTheme.mediumGrey],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: _isTyping
                          ? [
                              BoxShadow(
                                color: VyRaTheme.primaryCyan.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: VyRaTheme.primaryBlack,
                      ),
                      onPressed: _isTyping ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: VyRaTheme.primaryCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: VyRaTheme.primaryCyan.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: VyRaTheme.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                              .fadeOut(duration: 600.ms)
                              .then()
                              .fadeIn(duration: 600.ms),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: VyRaTheme.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                              .fadeOut(duration: 600.ms, delay: 200.ms)
                              .then()
                              .fadeIn(duration: 600.ms),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: VyRaTheme.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                              .fadeOut(duration: 600.ms, delay: 400.ms)
                              .then()
                              .fadeIn(duration: 600.ms),
                          const SizedBox(width: 8),
                          const Text(
                            'Typing...',
                            style: TextStyle(
                              color: VyRaTheme.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _viewStatus(ChatStatusItem status) async {
    try {
      await _apiService.viewStatus(status.id);
      setState(() {
        final index = _statuses.indexWhere((s) => s.id == status.id);
        if (index != -1) {
          _statuses[index] = ChatStatusItem(
            id: status.id,
            userName: status.userName,
            profileImageUrl: status.profileImageUrl,
            timestamp: status.timestamp,
            isViewed: true,
          );
        }
      });
    } catch (e) {
      // Error viewing status
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class ChatMessage {
  final String id;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class ChatStatusItem {
  final String id;
  final String userName;
  final String? profileImageUrl;
  final DateTime timestamp;
  final bool isViewed;

  ChatStatusItem({
    required this.id,
    required this.userName,
    this.profileImageUrl,
    required this.timestamp,
    this.isViewed = false,
  });
}