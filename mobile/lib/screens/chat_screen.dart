import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _animController;
  
  bool _isTyping = false;
  bool _showError = false;
  String? _lastUserMessage;

  late final GenerativeModel _model;
  late final ChatSession _chat;

  // MOCK DATA
  final List<Map<String, dynamic>> _messages = [];

  final List<String> _suggestedQuestions = [
    'What is G-10 status?',
    'G-10 mein kya ho raha hai?',
    'Kitne resources deploy hain?',
    'Which areas to avoid?',
    'Saddar heatwave update?',
    'False alarm kya tha?',
  ];

  @override
  void initState() {
    super.initState();
    // MOCK DATA
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyAZRb7QquhGPF8_W1Csvh3xFnVhdNFE7xo',
      generationConfig: GenerationConfig(
        temperature: 0.9,
        maxOutputTokens: 1024,
      ),
      systemInstruction: Content.system('''
You are CIRO - Crisis Intelligence & Response Orchestrator.
AI assistant for emergency commanders in Pakistan.

LIVE CRISIS CONTEXT:
- G-10 Islamabad: Water emergency (flooding vs water main 
  burst under investigation). Severity 8/10. 5,000 at risk.
  Resources: 3 police, 2 water tankers, 1 rescue team.
- Saddar Rawalpindi: Extreme Heatwave 47C. Severity 7/10. 
  15,000 at risk. Resources: 2 ambulances, 1 medical team.
- Total deployed: 9 resources across 2 crises.
- RETRACTION: Flood alert retracted - water main confirmed.
  WASA notified. Rescue 1122 stood down.

PERSONALITY:
- Calm, authoritative, military AI assistant
- Respond in SAME language user writes in
- Urdu → Urdu, Roman Urdu → Roman Urdu, English → English
- Concise but complete answers
- Always end with actionable recommendation
- You save lives - take that seriously
'''),
    );
    _chat = _model.startChat();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send message function:
  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    _lastUserMessage = userMessage;

    setState(() {
      _showError = false;
      _messages.add({
        'role': 'user',
        'text': userMessage,
        'time': TimeOfDay.now().format(context),
      });
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();
    
    try {
      final responseStream = _chat.sendMessageStream(
        Content.text(userMessage)
      );
      
      bool isFirstChunk = true;
      int? streamMessageIndex;
      
      await for (final chunk in responseStream) {
        final chunkText = chunk.text ?? '';
        if (chunkText.isNotEmpty) {
          if (isFirstChunk) {
            setState(() {
              _isTyping = false;
              _messages.add({
                'role': 'ciro',
                'text': chunkText,
                'time': TimeOfDay.now().format(context),
                'isStreaming': true,
              });
              streamMessageIndex = _messages.length - 1;
              isFirstChunk = false;
            });
          } else {
            setState(() {
              if (streamMessageIndex != null) {
                _messages[streamMessageIndex!]['text'] = 
                    (_messages[streamMessageIndex!]['text'] as String) + chunkText;
              }
            });
          }
          _scrollToBottom();
        }
      }
      
      if (streamMessageIndex != null) {
        setState(() {
          _messages[streamMessageIndex!]['isStreaming'] = false;
        });
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _showError = true;
      });
      _scrollToBottom();
    }
  }

  String _getKeywordResponse(String msg) {
    // MOCK DATA
    msg = msg.toLowerCase();
    if (msg.contains('g-10') || msg.contains('pani') || msg.contains('flood')) {
      return 'G-10 mein water main burst confirm hua hai. WASA team dispatch ho gayi. 3 police units area block kar rahi hain. Is area se guzarna avoid karein.';
    }
    if (msg.contains('heat') || msg.contains('garmi') || msg.contains('saddar')) {
      return 'Saddar mein 47C extreme heatwave hai. 2 ambulances aur medical team deploy hain. Cooling centers: Saddar Community Hall, RGH Lobby. Ghar mein rahein.';
    }
    if (msg.contains('resource') || msg.contains('kitne')) {
      return '9 resources deployed: G-10 mein 3 police, 2 water tankers, 1 rescue team. Saddar mein 2 ambulances, 1 medical outreach. 1 rescue team HQ standby.';
    }
    if (msg.contains('avoid') || msg.contains('safe') || msg.contains('route')) {
      return 'Avoid: G-10 Markaz, Saddar Rawalpindi. Safe routes: Kashmir Highway via G-9, Ibn-e-Sina Road via F-10.';
    }
    return 'CIRO monitoring 2 active crises. G-10 water emergency aur Saddar heatwave. Koi specific sawaal poochein — main help karunga.';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgDark,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSubtitle(),
            Expanded(
              child: Stack(
                children: [
                  // Watermark
                  Center(
                    child: Icon(Icons.nightlight_round,
                      color: Colors.white.withOpacity(0.015), size: 200),
                  ),
                  _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: _messages.length + (_showError ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i < _messages.length) {
                              return _buildChatBubble(_messages[i]);
                            } else {
                              return _buildErrorState();
                            }
                          },
                        ),
                ],
              ),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildInputBar(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(bottom: BorderSide(color: kBorderSubtle.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          // Robot avatar
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryBlue.withOpacity(0.3), kCardBg],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: kPrimaryBlue.withOpacity(0.5), width: 1.5),
            ),
            child: const Icon(Icons.smart_toy, color: kPrimaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('CIRO AI ASSISTANT', style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
              letterSpacing: 1,
            )),
          ),
          // Powered by Gemini badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryBlue.withOpacity(0.5)),
              color: kPrimaryBlue.withOpacity(0.1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: kPrimaryBlue, size: 12),
                SizedBox(width: 4),
                Text('POWERED BY GEMINI', style: TextStyle(
                  color: kPrimaryBlue, fontSize: 8, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: kSuccessGreen.withOpacity(0.7), size: 14),
          const SizedBox(width: 6),
          Text('SECURE  •  RELIABLE  •  ALWAYS ON', style: TextStyle(
            color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          // Glowing avatar container
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryBlue.withOpacity(0.4), kCardBgLighter],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.2),
                  blurRadius: 20, spreadRadius: 2,
                ),
              ],
              border: Border.all(color: kPrimaryBlue.withOpacity(0.6), width: 1.5),
            ),
            child: const Icon(Icons.smart_toy, color: kPrimaryBlue, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Assalam o Alaikum Commander',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Main 2 active crises monitor kar raha hun. Emergency response queries ke liye tayyar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: kPrimaryBlue.withOpacity(0.8), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'SUGGESTED PROMPTS',
                    style: TextStyle(
                      color: kPrimaryBlue.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _suggestedQuestions.map((q) => GestureDetector(
              onTap: () => _sendMessage(q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorderSubtle.withOpacity(0.8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: kPrimaryBlue, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      q,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final text = msg['text'] ?? '';
    final time = msg['time'] ?? '';
    final isStreaming = msg['isStreaming'] == true;

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message copied to clipboard', style: TextStyle(color: Colors.white)),
            backgroundColor: kCardBgLighter,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: isUser
          ? Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12, left: 60),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), kPrimaryBlue],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16), topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(text, style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.4,
                    )),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(time, style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 10,
                        )),
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, color: Colors.white.withOpacity(0.7), size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCardBg,
                      border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.smart_toy, color: kPrimaryBlue, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CIRO AI', style: TextStyle(
                          color: kPrimaryBlue, fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        )),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4), topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                            ),
                            border: Border.all(color: kBorderSubtle.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text + (isStreaming ? ' █' : ''),
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 14, height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(time, style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 10,
                              )),
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

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: kCardBg,
                border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
              ),
              child: const Icon(Icons.smart_toy, color: kPrimaryBlue, size: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorderSubtle.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(0), const SizedBox(width: 4),
                  _dot(1), const SizedBox(width: 4),
                  _dot(2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double delay = index * 0.2;
        double value = _animController.value - delay;
        if (value < 0) value += 1.0;
        final double opacity = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(value * 2 * math.pi));
        
        return Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryBlue.withOpacity(opacity),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kCardBg,
                  border: Border.all(color: kCriticalRed.withOpacity(0.3)),
                ),
                child: const Icon(Icons.error_outline, color: kCriticalRed, size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4), topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: kCriticalRed.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connection issue. Retry karein.',
                        style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_lastUserMessage != null) {
                                setState(() {
                                  _showError = false;
                                });
                                _sendMessage(_lastUserMessage!);
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
                            label: const Text('Retry', style: TextStyle(fontSize: 12, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (_lastUserMessage != null) {
                                final fallbackText = _getKeywordResponse(_lastUserMessage!);
                                setState(() {
                                  _showError = false;
                                  _messages.add({
                                    'role': 'ciro',
                                    'text': fallbackText,
                                    'time': TimeOfDay.now().format(context),
                                  });
                                });
                                _scrollToBottom();
                              }
                            },
                            icon: const Icon(Icons.offline_bolt, size: 14, color: kWarningOrange),
                            label: const Text('Offline Fallback', style: TextStyle(fontSize: 12, color: kWarningOrange)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kWarningOrange),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: kBorderSubtle.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryBlue.withOpacity(0.1),
            ),
            child: Icon(Icons.mic, color: kPrimaryBlue.withOpacity(0.7), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask CIRO...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: kBgDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0284C7), kPrimaryBlue],
                ),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('CIRO AI is always listening', style: TextStyle(
                color: Colors.grey.shade600, fontSize: 10,
              )),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: Colors.grey.shade700, size: 10),
              const SizedBox(width: 4),
              Text('End-to-end encrypted', style: TextStyle(
                color: Colors.grey.shade700, fontSize: 9,
              )),
            ],
          ),
        ],
      ),
    );
  }
}
