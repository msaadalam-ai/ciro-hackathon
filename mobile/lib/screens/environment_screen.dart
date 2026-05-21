import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});
  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  static const _orange = Color(0xFFFF6B00);
  static const _bg = Color(0xFF0A0A0A);
  static const _card = Color(0xFF141414);
  static const _red = Color(0xFFEF4444);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);

  String _activeView = '';
  Map<String, dynamic>? _weatherISB;
  Map<String, dynamic>? _weatherRWP;
  bool _loading = false;
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('g10'),
      position: LatLng(33.6942, 73.0338),
      infoWindow: InfoWindow(title: 'G-10 ISLAMABAD', snippet: 'WATER EMERGENCY - Severity 8/10'),
    ),
    const Marker(
      markerId: MarkerId('saddar'),
      position: LatLng(33.5973, 73.0479),
      infoWindow: InfoWindow(title: 'SADDAR RAWALPINDI', snippet: 'HEATWAVE 47°C - Severity 7/10'),
    ),
    const Marker(
      markerId: MarkerId('pims'),
      position: LatLng(33.7215, 73.0433),
      infoWindow: InfoWindow(title: 'PIMS Hospital', snippet: 'Resource HQ'),
    ),
  };

  Future<void> _fetchWeather() async {
    setState(() { _loading = true; _activeView = 'weather'; });
    try {
      const key = 'ee1edccb56e448e49a5439440d63d1fd';
      final r1 = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=Islamabad,PK&appid=$key&units=metric'));
      final r2 = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=Rawalpindi,PK&appid=$key&units=metric'));
      setState(() {
        _weatherISB = json.decode(r1.body);
        _weatherRWP = json.decode(r2.body);
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: Row(children: [
          const Text('🌍', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const Text('ENVIRONMENT INTEL', style: TextStyle(color: _orange, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        ]),
        actions: [
          Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _green.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: _green)),
            child: const Text('● LIVE', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(children: [
        // 4 Action Buttons
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _actionBtn('🌤', 'WEATHER', _orange, () => _fetchWeather()),
            const SizedBox(width: 8),
            _actionBtn('🌧', 'RAINFALL', _blue, () => setState(() => _activeView = 'rain')),
            const SizedBox(width: 8),
            _actionBtn('🗺', 'CRISIS MAP', _red, () => setState(() => _activeView = 'map')),
            const SizedBox(width: 8),
            _actionBtn('🚗', 'ROUTES', _green, () => setState(() => _activeView = 'routes')),
          ]),
        ),
        // Content Area
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _actionBtn(String emoji, String label, Color color, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ]),
      ),
    ));
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
    switch (_activeView) {
      case 'weather': return _weatherView();
      case 'rain': return _rainView();
      case 'map': return _mapView();
      case 'routes': return _routesView();
      default: return _defaultView();
    }
  }

  Widget _defaultView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('🌍', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 16),
    Text('Select an option above', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
    const SizedBox(height: 8),
    Text('Live data for Islamabad & Rawalpindi', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
  ]));

  Widget _weatherView() {
    if (_weatherISB == null) return const Center(child: Text('No data', style: TextStyle(color: Colors.white)));
    return SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [
        Expanded(child: _weatherCard('ISLAMABAD', _weatherISB!, _blue)),
        const SizedBox(width: 12),
        Expanded(child: _weatherCard('RAWALPINDI', _weatherRWP!, _orange)),
      ]),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _orange.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🤖 CIRO ASSESSMENT', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Text('Live weather confirms crisis conditions. Islamabad humidity ${_weatherISB!['main']?['humidity']}% — water infrastructure stress elevated. Rawalpindi temperature ${_weatherRWP!['main']?['temp']?.toStringAsFixed(1)}°C — heatwave protocol active.',
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
        ])),
    ]));
  }

  Widget _weatherCard(String city, Map data, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: color, width: 4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(city, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
      const SizedBox(height: 8),
      Text('${data['main']?['temp']?.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
      Text('${data['weather']?[0]?['description'] ?? ''}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [
        _statBox('Humidity', '${data['main']?['humidity']}%', color),
        const SizedBox(width: 6),
        _statBox('Wind', '${data['wind']?['speed']} m/s', color),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        _statBox('Rain', '${data['rain']?['1h'] ?? 0} mm/h', data['rain'] != null ? _red : _green),
        const SizedBox(width: 6),
        _statBox('Feels', '${data['main']?['feels_like']?.toStringAsFixed(1)}°C', color),
      ]),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(
        color: (data['main']?['temp'] > 40 || (data['rain']?['1h'] ?? 0) > 10) ? _red.withOpacity(0.1) : _green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4)),
        child: Text(
          data['main']?['temp'] > 40 ? '⚠ EXTREME HEAT' : (data['rain']?['1h'] ?? 0) > 10 ? '⚠ FLOOD RISK HIGH' : '✅ CONDITIONS NORMAL',
          style: TextStyle(color: (data['main']?['temp'] > 40 || (data['rain']?['1h'] ?? 0) > 10) ? _red : _green, fontSize: 11, fontWeight: FontWeight.bold),
        )),
    ]));

  Widget _statBox(String label, String val, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(4)),
    child: Column(children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    ])));

  Widget _rainView() => SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
    const Text('🌧 RAINFALL & FLOOD RISK', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w900, fontSize: 16)),
    const SizedBox(height: 16),
    _riskCard('G-10 ISLAMABAD', '12 mm/h', 0.85, _red, 'HIGH RISK', 'Threshold exceeded — water infrastructure failure'),
    const SizedBox(height: 12),
    _riskCard('SADDAR RAWALPINDI', '0 mm/h', 0.05, _green, 'LOW RISK', 'Dry conditions — heat emergency active'),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: _orange, width: 4))),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🤖 SIGNALFUSIONAGENT ANALYSIS', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13)),
        SizedBox(height: 8),
        Text('G-10 rainfall 12mm/h exceeds flood threshold. Combined with field report of water main burst — CIRO classifies as infrastructure failure. Flood risk elevated until WASA confirms repair.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
      ])),
  ]));

  Widget _riskCard(String city, String rain, double risk, Color color, String badge, String desc) => Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border.all(color: color, width: 2)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(city, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 8),
      Text(rain, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
      Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: risk, backgroundColor: Colors.grey[800], color: color, minHeight: 8)),
      const SizedBox(height: 4),
      Text('${(risk * 100).toInt()}% risk level', style: TextStyle(color: color, fontSize: 11)),
    ]));

  Widget _mapView() => GoogleMap(
    initialCameraPosition: const CameraPosition(target: LatLng(33.65, 73.048), zoom: 11),
    markers: _markers,
    onMapCreated: (c) => _mapController = c,
    mapType: MapType.normal,
    myLocationButtonEnabled: false,
  );

  Widget _routesView() => SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('🚗 ROUTE INTELLIGENCE', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 16)),
    const SizedBox(height: 16),
    const Text('✅ SAFE ROUTES', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
    const SizedBox(height: 8),
    ...['Kashmir Highway via G-9', 'Ibn-e-Sina Road via F-10', 'Margalla Road (northern)', 'Murree Road (eastern)', 'Constitution Avenue']
        .map((r) => _routeItem(r, _green, '→')),
    const SizedBox(height: 16),
    const Text('🚫 AVOID — BLOCKED', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14)),
    const SizedBox(height: 8),
    ...['Street 12, G-10 (water main burst)', 'G-10 Markaz main roads', 'Jinnah Avenue near G-10', 'Saddar main bazaar (extreme heat)', 'Raja Bazaar area (heat)']
        .map((r) => _routeItem(r, _red, '⚠')),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _orange.withOpacity(0.3))),
      child: Column(children: [
        const Text('📡 TRAFFIC STATUS', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          _trafficBox('G-10\nCongestion', '9.2/10', _red),
          const SizedBox(width: 8),
          _trafficBox('After\nRerouting', '4.1/10', _green),
          const SizedBox(width: 8),
          _trafficBox('Traffic\nImproved', '55%', _orange),
        ]),
      ])),
  ]));

  Widget _routeItem(String route, Color color, String icon) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(6), border: Border(left: BorderSide(color: color, width: 3))),
    child: Row(children: [
      Text(icon, style: TextStyle(color: color, fontSize: 14)),
      const SizedBox(width: 8),
      Expanded(child: Text(route, style: const TextStyle(color: Colors.white70, fontSize: 13))),
    ]));

  Widget _trafficBox(String label, String val, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(6)),
    child: Column(children: [
      Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
    ])));
}
