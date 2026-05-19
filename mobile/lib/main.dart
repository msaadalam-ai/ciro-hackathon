import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CIROApp());
}

class CiroApiService {
  // Use localhost for web/desktop. If running on Android Emulator, this might need to be 10.0.2.2.
  static const String baseUrl = 'http://localhost:5001/ciro-hackathon-2026-c6cf3/us-central1/';

  static Future<Map<String, dynamic>> runPipeline() async {
    // 1. SignalFusionAgent
    final fusionRes = await http.post(
      Uri.parse('${baseUrl}SignalFusionAgent'), 
      headers: {'Content-Type': 'application/json'}, 
      body: '{}'
    );
    final fusionData = jsonDecode(fusionRes.body);

    // 2. CrisisClassifierAgent
    final classifierRes = await http.post(
      Uri.parse('${baseUrl}CrisisClassifierAgent'), 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode(fusionData)
    );
    final classifierData = jsonDecode(classifierRes.body);

    // 3. ResourceAllocatorAgent
    final allocatorRes = await http.post(
      Uri.parse('${baseUrl}ResourceAllocatorAgent'), 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode(classifierData)
    );
    final allocatorData = jsonDecode(allocatorRes.body);

    // 4. ResponseCoordinatorAgent
    final coordinatorRes = await http.post(
      Uri.parse('${baseUrl}ResponseCoordinatorAgent'), 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode(allocatorData)
    );
    final coordinatorData = jsonDecode(coordinatorRes.body);

    return {
      'classifierData': classifierData,
      'allocatorData': allocatorData,
      'coordinatorData': coordinatorData,
    };
  }

  static Future<String> askAssistant(String question) async {
    try {
      final res = await http.post(
        Uri.parse('${baseUrl}CiroAssistantAgent'), 
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode({'question': question})
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['response'] ?? 'No response';
      }
      return 'Error: Could not reach CIRO Assistant (Status: ${res.statusCode})';
    } catch (e) {
      return 'Error: Connection failed ($e)';
    }
  }
}


class CiroState extends ChangeNotifier {
  bool isLive = false;
  bool isLoading = false;
  Map<String, dynamic>? data;

  Future<void> runPipeline() async {
    isLoading = true;
    notifyListeners();
    try {
      data = await CiroApiService.runPipeline();
      isLive = true;
    } catch (e) {
      print("Error running pipeline: $e");
      // Revert to mock on failure
      isLive = false;
    }
    isLoading = false;
    notifyListeners();
  }
}

final ciroState = CiroState();

class CIROApp extends StatelessWidget {
  const CIROApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CIRO Orchestrator',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        primaryColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E293B),
          selectedItemColor: Color(0xFF2563EB),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 80, color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              const Text(
                'CIRO',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              Text(
                'Crisis Intelligence &\nResponse Orchestrator',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const IncidentsScreen(),
    const ResourcesScreen(),
    const AlertsScreen(),
    const ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ciroState,
      builder: (context, child) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: AppBar(
                title: Row(
                  children: [
                    const Icon(Icons.shield, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    const Text('CIRO Command', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), activeIcon: Icon(Icons.warning), label: 'Incidents'),
              BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: 'Resources'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications_active), label: 'Alerts'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Assistant'),
            ],
          ),
        );
      }
    );
  }
}

// 1. Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int activeCrises = 2;
    int deployedResources = 9;
    
    if (ciroState.isLive && ciroState.data != null) {
      activeCrises = (ciroState.data!['classifierData']['crises'] as List).length;
      deployedResources = (ciroState.data!['allocatorData']['allocations'] as List).fold(0, (sum, item) => sum + (item['quantityAllocated'] as int));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('System Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ciroState.isLive ? const Color(0xFF22C55E).withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ciroState.isLive ? const Color(0xFF22C55E) : Colors.orange),
                ),
                child: Text(
                  ciroState.isLive ? 'LIVE DATA' : 'MOCK DATA',
                  style: TextStyle(
                    color: ciroState.isLive ? const Color(0xFF22C55E) : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (ciroState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2563EB)),
                    SizedBox(height: 16),
                    Text('Running Agent Pipeline...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => ciroState.runPipeline(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run CIRO Pipeline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatCard('Active Crises', '$activeCrises', const Color(0xFFEF4444))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Deployed Resources', '$deployedResources', const Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Response', ciroState.isLive ? '<2 sec' : '8 sec', const Color(0xFF22C55E))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Stakeholders', '5', const Color(0xFFF97316))),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Recent System Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                _buildLogItem(Icons.check_circle, const Color(0xFF22C55E), 'Pipeline Complete', 'All 4 agents executed successfully'),
                if (!ciroState.isLive) _buildLogItem(Icons.info, const Color(0xFF2563EB), 'Resources Dispatched', 'Ambulances to Saddar (Heatwave)'),
                if (!ciroState.isLive) _buildLogItem(Icons.warning, const Color(0xFFEF4444), 'New Incident Detected', 'G-10 Islamabad - Water emergency'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color topColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: topColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLogItem(IconData icon, Color iconColor, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ),
    );
  }
}

// 2. Incidents Screen
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ciroState.isLive && ciroState.data != null) {
      final crises = ciroState.data!['classifierData']['crises'] as List;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: crises.map((c) {
          final title = (c['classification'] as List).join(' / ');
          final severity = c['severityScore'] ?? 0;
          final color = severity > 7 ? const Color(0xFFEF4444) : const Color(0xFFF97316);
          return Column(
            children: [
              _buildIncidentCard(
                title.replaceAll('_', ' ').toUpperCase(),
                c['location'] ?? 'Unknown',
                'Severity: $severity',
                c['severityExplanation'] ?? '',
                color,
              ),
              const SizedBox(height: 16),
            ]
          );
        }).toList(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIncidentCard(
          'Water Main Burst',
          'G-10, Islamabad',
          'Severity: 8',
          'Social posts report flooding, but field reports confirmed a massive water main burst. Traffic rerouted.',
          const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),
        _buildIncidentCard(
          'Extreme Heatwave',
          'Saddar, Rawalpindi',
          'Severity: 7',
          'Temperature hit 47°C. High risk to vulnerable population. Cooling centers activated.',
          const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget _buildIncidentCard(String title, String location, String severity, String desc, Color leftColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: leftColor, width: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: leftColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(severity, style: TextStyle(color: leftColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(location, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(desc, style: const TextStyle(color: Colors.white70, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// 3. Resources Screen
class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  IconData _getIconForResource(String type) {
    if (type.toLowerCase().contains('ambulance') || type.toLowerCase().contains('medical')) return Icons.medical_services;
    if (type.toLowerCase().contains('police')) return Icons.local_police;
    if (type.toLowerCase().contains('water')) return Icons.water_drop;
    return Icons.support;
  }

  @override
  Widget build(BuildContext context) {
    if (ciroState.isLive && ciroState.data != null) {
      final allocations = ciroState.data!['allocatorData']['allocations'] as List;
      final standbys = ciroState.data!['allocatorData']['standbyResources'] as List;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Active Allocations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...allocations.map((a) {
            String rType = a['resourceType'] ?? 'Resource';
            return _buildResourceItem(
              '${rType.toUpperCase()} (${a['quantityAllocated']})',
              a['destination'] ?? 'Unknown',
              a['allocationReasoning'] ?? '',
              _getIconForResource(rType),
              const Color(0xFF2563EB),
            );
          }).toList(),
          const Divider(height: 40, color: Colors.grey),
          const Text('Standby Resources', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...standbys.map((s) {
            String rType = s['resourceType'] ?? 'Resource';
            return _buildResourceItem(
              '${rType.toUpperCase()} (${s['quantity']})',
              'Headquarters / On Call',
              s['standbyReason'] ?? '',
              _getIconForResource(rType),
              Colors.grey,
            );
          }).toList(),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Active Allocations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildResourceItem('Ambulances (2)', 'Saddar, Rawalpindi', 'Heatstroke Transport', Icons.medical_services, const Color(0xFFEF4444)),
        _buildResourceItem('Police Units (3)', 'G-10, Islamabad', 'Traffic Management', Icons.local_police, const Color(0xFF2563EB)),
        _buildResourceItem('Water Tankers (2)', 'G-10, Islamabad', 'Backup clean water', Icons.water_drop, const Color(0xFF2563EB)),
        _buildResourceItem('Medical Outreach (1)', 'Saddar, Rawalpindi', 'Cooling Stations', Icons.healing, const Color(0xFFF97316)),
        const Divider(height: 40, color: Colors.grey),
        const Text('Standby Resources', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildResourceItem('Rescue Teams (1)', 'Headquarters', 'Pending field updates', Icons.support, Colors.grey),
        _buildResourceItem('Ambulances (1)', 'G-10, Islamabad', 'Standby for incident', Icons.medical_services, Colors.grey),
      ],
    );
  }

  Widget _buildResourceItem(String resource, String location, String task, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(resource, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To: $location', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              const SizedBox(height: 2),
              Text('Task: $task', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. Alerts Screen
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ciroState.isLive && ciroState.data != null) {
      final coordinator = ciroState.data!['coordinatorData'];
      final alerts = coordinator['publicAlerts'] as List? ?? [];
      final heatwave = coordinator['heatwaveResponse'];
      final heatwaveAlerts = (heatwave != null && heatwave['publicAlerts'] != null) ? heatwave['publicAlerts'] as List : [];
      
      final stakeholders = coordinator['stakeholderMessages'] as List? ?? [];

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Public Alerts Generated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...alerts.map((a) => _buildPublicAlertCard('Alert (${a['language']})', a['message'] ?? '', const Color(0xFFEF4444))),
          ...heatwaveAlerts.map((a) => _buildPublicAlertCard('Heatwave Alert (${a['language']})', a['message'] ?? '', const Color(0xFFF97316))),
          const SizedBox(height: 24),
          const Text('Stakeholder Messages Sent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...stakeholders.map((s) => _buildStakeholderMessage(s['stakeholder'] ?? 'Unknown', s['message'] ?? '')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Public Alerts Generated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildPublicAlertCard('G-10 Water Emergency (Urdu)', 'G-10 mein paani bhar gaya hai — is area se guzarna avoid karein', const Color(0xFFEF4444)),
        _buildPublicAlertCard('Saddar Heatwave (English)', 'Extreme heatwave alert. Stay indoors and hydrate. Cooling centers active.', const Color(0xFFF97316)),
        const SizedBox(height: 24),
        const Text('Stakeholder Messages Sent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildStakeholderMessage('PIMS Hospital', 'Prepare for potential casualties from G-10.'),
        _buildStakeholderMessage('Islamabad Police', 'Traffic management: Block flooded roads around G-10.'),
        _buildStakeholderMessage('WASA Water Authority', 'Investigate water main on Street 12 G-10 immediately.'),
      ],
    );
  }

  Widget _buildPublicAlertCard(String title, String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.campaign, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
        ),
      ),
    );
  }

  Widget _buildStakeholderMessage(String stakeholder, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Color(0xFF22C55E), width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.send, size: 16, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
                children: [
                  TextSpan(text: '$stakeholder:\n', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(text: 'Hello, Commander. I am CIRO. How can I assist you with the current crisis?', isUser: false),
  ];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedQuestions = [
    "What is the status of G-10?",
    "G-10 mein kya ho raha hai?",
    "Which areas to avoid?",
    "How many resources deployed?",
    "What happens if flooding is confirmed?"
  ];

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await CiroApiService.askAssistant(text);
    
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: response, isUser: false));
    });
    _scrollToBottom();
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smart_toy, color: Color(0xFF2563EB), size: 24),
              const SizedBox(width: 8),
              const Text('CIRO AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildChatBubble(msg);
            },
          ),
        ),
        if (_isTyping)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("CIRO is thinking...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _suggestedQuestions.map((q) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                label: Text(q, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                onPressed: () => _sendMessage(q),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask CIRO...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
        ),
      ),
    );
  }
}
