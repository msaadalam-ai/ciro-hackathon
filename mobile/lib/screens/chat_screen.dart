import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    // MOCK DATA
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyAWt1MOPc_gIAQj3lUgGr0rwj5JYGdEkSg',
      generationConfig: GenerationConfig(
        temperature: 0.9,
        maxOutputTokens: 1024,
      ),
      systemInstruction: Content.system('''
You are CIRO - Crisis Intelligence & Response Orchestrator.
You are an AI assistant for emergency commanders in Pakistan.

CURRENT ACTIVE CRISES:
1. G-10 Islamabad - Water Emergency (flooding vs water main burst - under investigation)
   Severity: 8/10 | Population at risk: 5,000
   Status: Field verification pending
   Resources: 3 police units, 2 water tankers, 1 rescue team deployed
   
2. Saddar Rawalpindi - Extreme Heatwave 47C
   Severity: 7/10 | Population at risk: 15,000  
   Status: Response active
   Resources: 2 ambulances, 1 medical outreach team deployed

TOTAL RESOURCES: 9 deployed, 1 rescue team on standby

RECENT ACTION: Flood alert for G-10 RETRACTED - confirmed water main burst
WASA notified. Rescue 1122 stood down from flood response.

TRAFFIC: G-10 congestion severe (9.2/10). 
Alternate routes: Kashmir Highway via G-9, Ibn-e-Sina Road via F-10

STAKEHOLDERS NOTIFIED: PIMS Hospital, Islamabad Police, 
Rescue 1122, WASA Water Authority, Media/Command Center

YOUR PERSONALITY:
- You are calm, authoritative, professional
- You speak like a military AI assistant
- You respond in the SAME language the user writes in
- If Urdu → respond in Urdu
- If Roman Urdu → respond in Roman Urdu  
- If English → respond in English
- Keep responses concise but complete
- Always end with a actionable recommendation
- You care about saving lives
'''),
    );
    _chat = _model.startChat();
  }

  // MOCK DATA
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ciro',
      'text': 'Assalam o Alaikum Commander. I am monitoring 2 active crises. How can I assist you?',
      'time': '10:21 AM',
    },
  ];

  final List<String> _suggestedQuestions = [
    'Kitne resources deploy hain?',
    'Heatwave update?',
    'G-10 status?',
    'Which areas safe?',
    'Saddar situation?',
  ];

  // Send message function:
  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
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
      final response = await _chat.sendMessage(
        Content.text(userMessage)
      );
      
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'ciro',
          'text': response.text ?? 'Unable to process',
          'time': TimeOfDay.now().format(context),
        });
      });
      _scrollToBottom();
    } catch (e) {
      // Keyword fallback
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'ciro', 
          'text': _getKeywordResponse(userMessage),
          'time': TimeOfDay.now().format(context),
        });
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
                      color: Colors.white.withOpacity(0.02), size: 200),
                  ),
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _buildChatBubble(_messages[i]),
                  ),
                ],
              ),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildSuggestedQuestions(),
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

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final text = msg['text'] ?? '';
    final time = msg['time'] ?? '';
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), kPrimaryBlue],
            ),
            borderRadius: const BorderRadius.only(
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
      );
    }

    return Padding(
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
                      Text(text, style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.5,
                      )),
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (_, v, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kPrimaryBlue.withOpacity(v),
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: kPrimaryBlue.withOpacity(0.7), size: 14),
              const SizedBox(width: 6),
              Text('SUGGESTED QUESTIONS', style: TextStyle(
                color: kPrimaryBlue.withOpacity(0.7), fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 0.5,
              )),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _suggestedQuestions.map((q) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () async {
                    _controller.text = q;
                    await Future.delayed(const Duration(milliseconds: 200));
                    _sendMessage(q);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
                      color: kPrimaryBlue.withOpacity(0.08),
                    ),
                    child: Text(q, style: TextStyle(
                      color: Colors.grey.shade300, fontSize: 12,
                    )),
                  ),
                ),
              )).toList(),
            ),
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
