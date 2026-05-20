import 'package:flutter/material.dart';
import '../constants.dart';
import '../painters.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgDark,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    _buildSectionHeader('ACTIVE DEPLOYMENTS', kSuccessGreen),
                    const SizedBox(height: 12),
                    _buildResourceCard(
                      icon: Icons.local_hospital,
                      iconBg: kCriticalRed,
                      title: 'AMBULANCES (2)',
                      destination: 'Saddar, Rawalpindi',
                      task: 'Heatstroke Transport',
                      eta: '25',
                      status: 'EN ROUTE',
                      statusColor: kCriticalRed,
                      borderColor: kCriticalRed,
                      routeColor: kCriticalRed,
                    ),
                    const SizedBox(height: 10),
                    _buildResourceCard(
                      icon: Icons.local_police,
                      iconBg: kPrimaryBlue,
                      title: 'POLICE UNITS (3)',
                      destination: 'G-10, Islamabad',
                      task: 'Traffic Blockade & Management',
                      eta: '8',
                      status: 'DEPLOYED',
                      statusColor: kPrimaryBlue,
                      borderColor: kPrimaryBlue,
                      routeColor: kPrimaryBlue,
                    ),
                    const SizedBox(height: 10),
                    _buildResourceCard(
                      icon: Icons.local_shipping,
                      iconBg: kPrimaryBlue,
                      title: 'WATER TANKERS (2)',
                      destination: 'G-10, Islamabad',
                      task: 'Backup Clean Water Supply',
                      eta: '15',
                      status: 'EN ROUTE',
                      statusColor: kPrimaryBlue,
                      borderColor: kPrimaryBlue,
                      routeColor: kPrimaryBlue,
                    ),
                    const SizedBox(height: 10),
                    _buildResourceCard(
                      icon: Icons.medical_services,
                      iconBg: kSuccessGreen,
                      title: 'MEDICAL OUTREACH (1)',
                      destination: 'Saddar, Rawalpindi',
                      task: 'Mobile Cooling Stations',
                      eta: '22',
                      status: 'DEPLOYING',
                      statusColor: kSuccessGreen,
                      borderColor: kSuccessGreen,
                      routeColor: kSuccessGreen,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('STANDBY RESOURCES', Colors.grey),
                    const SizedBox(height: 12),
                    _buildResourceCard(
                      icon: Icons.support,
                      iconBg: Colors.grey,
                      title: 'RESCUE TEAMS (1)',
                      destination: 'Headquarters',
                      task: 'Pending G-10 field verification',
                      eta: null,
                      status: 'ON STANDBY',
                      statusColor: Colors.grey,
                      borderColor: Colors.grey.shade700,
                      routeColor: Colors.grey,
                      isDashed: true,
                    ),
                    const SizedBox(height: 16),
                    _buildWarningCard(),
                  ],
                ),
              ),
            ),
            _buildBottomStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          const Text('RESOURCES', style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
            letterSpacing: 1,
          )),
          const Spacer(),
          Icon(Icons.nightlight_round, color: Colors.white.withOpacity(0.06), size: 28),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSuccessGreen.withOpacity(0.5)),
              color: kSuccessGreen.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kSuccessGreen)),
                const SizedBox(width: 6),
                const Text('LIVE ALLOCATION', style: TextStyle(
                  color: kSuccessGreen, fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: color, size: 8),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700,
                letterSpacing: 1,
              )),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: color.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String destination,
    required String task,
    required String? eta,
    required String status,
    required Color statusColor,
    required Color borderColor,
    required Color routeColor,
    bool isDashed = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconBg.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: iconBg, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(title, style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 2),
                      Text('→ ', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(destination, style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12,
                      )),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text('Task: $task', style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11,
                    )),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (eta != null) ...[
                        Text('ETA: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        Text('$eta min', style: TextStyle(
                          color: statusColor, fontSize: 12, fontWeight: FontWeight.w700,
                        )),
                        const SizedBox(width: 16),
                      ],
                      Text('Status: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      Text(status, style: TextStyle(
                        color: statusColor, fontSize: 12, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Mini route map
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 90, height: 80,
                child: CustomPaint(
                  painter: RouteMapPainter(routeColor: routeColor, isDashed: isDashed),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [kWarningOrange.withOpacity(0.15), kWarningOrange.withOpacity(0.05)],
        ),
        border: Border.all(color: kWarningOrange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kWarningOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: kWarningOrange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RESOURCE CONSTRAINT DETECTED', style: TextStyle(
                  color: kWarningOrange, fontSize: 13, fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 4),
                Text(
                  'Saddar receives no rescue teams —\nG-10 field verification takes priority.\nRequesting Punjab Emergency mutual aid.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: kBorderSubtle.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(Icons.local_shipping, 'TOTAL DEPLOYED', '9', kCriticalRed),
          _buildStat(Icons.access_time, 'RESPONSE TIME', '8', kSuccessGreen, suffix: 'sec'),
          _buildStat(Icons.map, 'COVERAGE', '2', kPrimaryBlue, suffix: 'zones'),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color, {String? suffix}) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 18),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          color: Colors.grey.shade600, fontSize: 8, fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        )),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(
              color: color, fontSize: 20, fontWeight: FontWeight.w800,
            )),
            if (suffix != null) Text(' $suffix', style: TextStyle(
              color: color.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ],
    );
  }
}
