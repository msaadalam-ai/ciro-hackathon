import 'package:flutter/material.dart';

void main() {
  runApp(const CIROApp());
}

class CIROApp extends StatelessWidget {
  const CIROApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CIRO Orchestrator',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CIRO Command Center'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Incidents'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Resources'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Alerts'),
        ],
      ),
    );
  }
}

// 1. Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatCard('Active Crises', '2', Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Deployed Resources', '9', Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Response', '8 sec', Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Stakeholders Notified', '5', Colors.purple)),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Recent System Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Retraction: Flood Alert in G-10'),
                  subtitle: Text('Changed to Water Main Burst'),
                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.blue),
                  title: Text('Resources Dispatched'),
                  subtitle: Text('Ambulances to Saddar (Heatwave)'),
                ),
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('New Incident Detected'),
                  subtitle: Text('G-10 Islamabad - Water emergency'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// 2. Incidents Screen
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIncidentCard(
          'Water Main Burst',
          'G-10, Islamabad',
          'Severity: 8',
          'Social posts report flooding, but field reports confirmed a massive water main burst. Traffic rerouted.',
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildIncidentCard(
          'Extreme Heatwave',
          'Saddar, Rawalpindi',
          'Severity: 7',
          'Temperature hit 47°C. High risk to vulnerable population. Cooling centers activated.',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildIncidentCard(String title, String location, String severity, String desc, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Chip(label: Text(severity), backgroundColor: color.withOpacity(0.2)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(desc),
          ],
        ),
      ),
    );
  }
}

// 3. Resources Screen
class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Active Allocations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildResourceItem('Ambulances (2)', 'Saddar, Rawalpindi', 'Heatstroke Transport'),
        _buildResourceItem('Police Units (3)', 'G-10, Islamabad', 'Traffic Management / Blockade'),
        _buildResourceItem('Water Tankers (2)', 'G-10, Islamabad', 'Backup clean water (Main Burst)'),
        _buildResourceItem('Medical Outreach (1)', 'Saddar, Rawalpindi', 'Cooling Stations'),
        const Divider(height: 40),
        const Text('Standby Resources', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildResourceItem('Rescue Teams (1)', 'Headquarters', 'Pending field verification updates'),
        _buildResourceItem('Ambulances (1)', 'G-10, Islamabad', 'Standby for water incident'),
      ],
    );
  }

  Widget _buildResourceItem(String resource, String location, String task) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: const Icon(Icons.local_shipping, color: Colors.blue),
      ),
      title: Text(resource, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To: $location'),
          Text('Task: $task', style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
      isThreeLine: true,
    );
  }
}

// 4. Alerts Screen
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Public Alerts Generated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          color: Colors.red.shade50,
          child: const ListTile(
            leading: Icon(Icons.campaign, color: Colors.red),
            title: Text('G-10 Water Emergency (Urdu)'),
            subtitle: Text('G-10 mein paani bhar gaya hai — is area se guzarna avoid karein'),
          ),
        ),
        Card(
          color: Colors.red.shade50,
          child: const ListTile(
            leading: Icon(Icons.campaign, color: Colors.red),
            title: Text('Saddar Heatwave (English)'),
            subtitle: Text('Extreme heatwave alert. Stay indoors and hydrate. Cooling centers active.'),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Stakeholder Messages Sent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildStakeholderMessage('PIMS Hospital', 'Prepare for potential casualties from G-10.'),
        _buildStakeholderMessage('Islamabad Police', 'Traffic management: Block flooded roads around G-10.'),
        _buildStakeholderMessage('WASA Water Authority', 'Investigate water main on Street 12 G-10 immediately.'),
      ],
    );
  }

  Widget _buildStakeholderMessage(String stakeholder, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.send, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: '$stakeholder: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
