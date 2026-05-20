import 'package:flutter/material.dart';
import '../constants.dart';
import '../painters.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

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
                    _buildSectionHeader('PUBLIC ALERTS', kCriticalRed),
                    const SizedBox(height: 12),
                    _buildRetractedAlertCard(),
                    const SizedBox(height: 10),
                    _buildPreliminaryAlertCard(),
                    const SizedBox(height: 10),
                    _buildHeatwaveEmergencyCard(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('STAKEHOLDER MESSAGES', kPrimaryBlue),
                    const SizedBox(height: 12),
                    _buildStakeholdersList(),
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
          const Text('ALERTS', style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
            letterSpacing: 1,
          )),
          const Spacer(),
          // Subtle crescent watermark
          Icon(Icons.nightlight_round, color: Colors.white.withOpacity(0.06), size: 28),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kCriticalRed.withOpacity(0.5)),
              color: kCriticalRed.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kCriticalRed)),
                const SizedBox(width: 6),
                const Text('4 ACTIVE ALERTS', style: TextStyle(
                  color: kCriticalRed, fontSize: 10, fontWeight: FontWeight.w700,
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
              Icon(Icons.campaign, color: color, size: 14),
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

  Widget _buildRetractedAlertCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: kCriticalRed, width: 3)),
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
                        width: 8, height: 8,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: kCriticalRed),
                      ),
                      const SizedBox(width: 6),
                      const Text('RETRACTED ALERT — CORRECTED', style: TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800,
                      )),
                      const Spacer(),
                      // AI Verified Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: kSuccessGreen.withOpacity(0.1),
                          border: Border.all(color: kSuccessGreen.withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: kSuccessGreen, size: 10),
                            SizedBox(width: 2),
                            Text('AI VERIFIED', style: TextStyle(
                              color: kSuccessGreen, fontSize: 8, fontWeight: FontWeight.w700,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey.shade500, size: 12),
                      const SizedBox(width: 4),
                      Text('Location: G-10, Islamabad', style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 11,
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Previous: ',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const TextSpan(
                          text: '"Urban Flooding Emergency"',
                          style: TextStyle(
                            color: kWarningOrange,
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Updated to: ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: '"Water Main Burst Confirmed"',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: kSuccessGreen, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'WASA notified • Rescue 1122 stood down',
                          style: TextStyle(color: kSuccessGreen.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey.shade600, size: 11),
                      const SizedBox(width: 4),
                      Text('14:45 PKT', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Map / Icon preview
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 90, height: 90,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: AlertMapPainter(color: kCriticalRed),
                      size: Size.infinite,
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kBgDark.withOpacity(0.7),
                          border: Border.all(color: kCriticalRed.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.opacity, color: kCriticalRed, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreliminaryAlertCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: kWarningOrange, width: 3)),
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
                  const Text('PRELIMINARY ALERT', style: TextStyle(
                    color: kWarningOrange, fontSize: 13, fontWeight: FontWeight.w800,
                  )),
                  const SizedBox(height: 6),
                  const Text(
                    'G-10 mein paani bhar gaya hai —\nis area se guzarna avoid karein',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Water emergency G-10 — avoid the area',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Status: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      const Text('PRELIMINARY', style: TextStyle(
                        color: kWarningOrange, fontSize: 11, fontWeight: FontWeight.w800,
                      )),
                      Text(' — field verification pending', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLangBadge('🇵🇰 Urdu'),
                      const SizedBox(width: 8),
                      _buildLangBadge('🇬🇧 English'),
                      const Spacer(),
                      Icon(Icons.access_time, color: Colors.grey.shade600, size: 11),
                      const SizedBox(width: 4),
                      Text('14:30 PKT', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Map thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 90, height: 95,
                child: CustomPaint(
                  painter: AlertMapPainter(color: kWarningOrange),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatwaveEmergencyCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: kWarningOrange, width: 3)),
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
                      const Icon(Icons.thermostat, color: kWarningOrange, size: 16),
                      const SizedBox(width: 4),
                      const Text('HEATWAVE EMERGENCY', style: TextStyle(
                        color: kWarningOrange, fontSize: 13, fontWeight: FontWeight.w800,
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey.shade500, size: 12),
                      const SizedBox(width: 4),
                      Text('Location: Saddar, Rawalpindi', style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 11,
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Shadeed garmi ki leher — bahar na niklen',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Extreme heatwave — stay indoors, hydrate',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 11),
                      children: [
                        TextSpan(
                          text: 'Cooling Centers: ',
                          style: TextStyle(color: kWarningOrange, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: 'Saddar Community Hall, RGH Lobby',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Status: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      const Text('ACTIVE  •  BROADCASTING', style: TextStyle(
                        color: kWarningOrange, fontSize: 11, fontWeight: FontWeight.w800,
                      )),
                      const Spacer(),
                      Icon(Icons.access_time, color: Colors.grey.shade600, size: 11),
                      const SizedBox(width: 4),
                      Text('14:20 PKT', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Map thumbnail with sun
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 90, height: 115,
                child: CustomPaint(
                  painter: AlertMapPainter(color: kWarningOrange, showSun: true),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kBgDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kBorderSubtle),
      ),
      child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStakeholdersList() {
    final list = [
      _StakeholderItem(Icons.local_hospital, 'PIMS Hospital', 'Prepare for G-10 casualties'),
      _StakeholderItem(Icons.local_police, 'Islamabad Police', 'Block G-10 roads'),
      _StakeholderItem(Icons.support, 'Rescue 1122', 'Stand down flood rescue'),
      _StakeholderItem(Icons.water_drop, 'WASA Water Authority', 'Investigate Street 12 G-10'),
      _StakeholderItem(Icons.shield, 'Command Center', 'Situation summary sent'),
    ];

    return Column(
      children: list.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderSubtle.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_arrow, color: kSuccessGreen, size: 14),
            const SizedBox(width: 8),
            Icon(item.icon, color: Colors.grey.shade400, size: 16),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Text(item.name, style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
              )),
            ),
            Expanded(
              flex: 3,
              child: Text(item.msg, style: TextStyle(
                color: Colors.grey.shade400, fontSize: 12,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            const Text('SENT ✓', style: TextStyle(
              color: kSuccessGreen, fontSize: 11, fontWeight: FontWeight.w800,
            )),
          ],
        ),
      )).toList(),
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
          _buildStat(Icons.campaign, 'ALERTS SENT', '4', kCriticalRed),
          _buildStat(Icons.people, 'STAKEHOLDERS NOTIFIED', '5', kPrimaryBlue),
          _buildStat(Icons.autorenew, 'RETRACTIONS', '1', kWarningOrange),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 18),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          color: Colors.grey.shade600, fontSize: 8, fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        )),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          color: color, fontSize: 20, fontWeight: FontWeight.w800,
        )),
      ],
    );
  }
}

class _StakeholderItem {
  final IconData icon;
  final String name;
  final String msg;
  _StakeholderItem(this.icon, this.name, this.msg);
}
