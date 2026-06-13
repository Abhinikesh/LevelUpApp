import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/providers/auth_provider.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});
  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;
  final List<_ChatMessage> _messages = [];
  // Parallel message history for API
  final List<Map<String, dynamic>> _apiMessages = [];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _messages.add(_ChatMessage(
      text:
          "Hey ${user?.name.split(' ').first ?? 'there'}! 👋 I'm ARIA, your AI study coach.\n\nI can see you're working on DSA Roadmap. Need help? Just ask anything!",
      isUser: false,
      suggestions: [
        'Explain Binary Search',
        'Practice Problem',
        'Simplify This',
      ],
    ));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preText]) async {
    final text = (preText ?? _textCtrl.text).trim();
    if (text.isEmpty || _isTyping) return;
    _textCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, suggestions: []));
      _isTyping = true;
    });
    _apiMessages.add({'role': 'user', 'content': text});
    _scrollDown();

    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('no_token');

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ));

      // Keep last 20 messages to avoid token overflow
      final trimmedMsgs = _apiMessages.length > 20
          ? _apiMessages.sublist(_apiMessages.length - 20)
          : List<Map<String, dynamic>>.from(_apiMessages);

      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.coachChat}',
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        ),
        data: {'messages': trimmedMsgs},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final reply = data['reply'] as String? ?? 'I had trouble responding. Try again!';
        final suggestions = (data['suggestedActions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .take(3)
            .toList() ?? [];

        // Add AI response to API history
        _apiMessages.add({'role': 'assistant', 'content': reply});

        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(text: reply, isUser: false, suggestions: suggestions));
        });
        _scrollDown();
        return;
      }
      throw Exception('Backend error: ${data['message']}');
    } catch (_) {
      // Fallback: local mock response
      await Future.delayed(const Duration(milliseconds: 800));
      final response = _generateAriaResponse(text);
      final suggestions = _suggestionsFor(text);
      _apiMessages.add({'role': 'assistant', 'content': response});
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response, isUser: false, suggestions: suggestions));
      });
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(100.ms, () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateAriaResponse(String q) {
    final lower = q.toLowerCase();
    if (lower.contains('binary search')) {
      return 'Binary Search works by repeatedly halving the search space.\n\n**Key idea:** Compare target with middle element:\n• If equal → found ✅\n• If smaller → search left half\n• If larger → search right half\n\n**Time complexity:** O(log n)\n**Space complexity:** O(1) iterative\n\nWant me to walk through an example?';
    } else if (lower.contains('practice') || lower.contains('problem')) {
      return 'Great! Here\'s a practice problem 🧩\n\n**Problem:** Given a sorted array, find if target 42 exists.\n`arr = [2, 8, 15, 27, 42, 61]`\n\nTry solving it with binary search. What\'s your approach?';
    } else if (lower.contains('simplify') || lower.contains('explain')) {
      return 'Sure! Let me break it down simply 😊\n\nThink of it like finding a word in a dictionary:\n1. Open to the middle page\n2. Is your word before or after?\n3. Repeat with the correct half\n\nThat\'s exactly how Binary Search works! Each step eliminates half the possibilities.';
    } else if (lower.contains('help')) {
      return 'Of course! I\'m here to help 🤖\n\nI can assist with:\n• **Concept explanations** — any topic in your roadmap\n• **Practice problems** — I\'ll create custom ones\n• **Hints** — when you\'re stuck\n• **Study strategies** — how to retain more\n\nWhat would you like to work on?';
    } else {
      return 'Great question! Let me think about that... 🤔\n\nFor "${q}", the key insight is to break it down step by step. Start with the simplest case, understand the pattern, then generalize.\n\nWould you like me to create a practice problem around this concept?';
    }
  }

  List<String> _suggestionsFor(String q) {
    final lower = q.toLowerCase();
    if (lower.contains('binary')) {
      return ['Show Example', 'Time Complexity', 'Practice Problem'];
    } else if (lower.contains('practice')) {
      return ['Give Hint', 'Show Solution', 'Another Problem'];
    }
    return ['Explain More', 'Practice Problem', 'Ask Another'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────
          _ARIAHeader(),

          // ── Messages ───────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[i];
                return _MessageBubble(
                  message: msg,
                  onSuggestionTap: _send,
                );
              },
            ),
          ),

          // ── Input bar ──────────────────────────────────
          _InputBar(
            ctrl: _textCtrl,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String> suggestions;
  const _ChatMessage(
      {required this.text,
      required this.isUser,
      required this.suggestions});
}

// ─── ARIA Header ───────────────────────────────────────────────
class _ARIAHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 14),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.4),
                  blurRadius: 12)],
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 24),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ARIA',
                    style: GoogleFonts.syne(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text('Your AI Study Coach',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Online indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Online',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.green,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final void Function(String) onSuggestionTap;

  const _MessageBubble(
      {required this.message, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                Container(
                  width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_outlined,
                      color: Colors.white, size: 14),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.brand : AppColors.bgCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.white, height: 1.5),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1),

          // Suggestions
          if (message.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: message.suggestions.map((s) => GestureDetector(
                  onTap: () => onSuggestionTap(s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.brand),
                    ),
                    child: Text(s,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.brand,
                            fontWeight: FontWeight.w500)),
                  ),
                )).toList(),
              ),
            ).animate().fadeIn(delay: 100.ms),
          ],
        ],
      ),
    );
  }
}

// ─── Typing Indicator ──────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: List.generate(3, (i) => Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.brand, shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: 0,
                      end: -6,
                      delay: Duration(milliseconds: i * 200),
                      duration: 400.ms)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ─────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController ctrl;
  final void Function([String?]) onSend;
  const _InputBar({required this.ctrl, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() {
      final has = widget.ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: widget.ctrl,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Ask ARIA anything...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _hasText ? () => widget.onSend() : null,
            child: AnimatedOpacity(
              opacity: _hasText ? 1.0 : 0.4,
              duration: 200.ms,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? [BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.4),
                          blurRadius: 12)]
                      : null,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
