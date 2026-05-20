import 'package:flutter/material.dart';
import '../constants.dart';
import '../api_service.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ciroState,
      builder: (context, _) {
        final hasData = ciroState.isLive;
        return Container(
          color: kBgDark,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildIncidentCard(
                        title: 'WATER MAIN BURST',
                        location: 'G-10, Islamabad',
                        severity: 'Severity: 8/10',
                        desc: 'Social posts report flooding, but WASA field reports confirmed a major water main burst. Traffic is being rerouted. Rescue 1122 and WASA teams are on site.',
                        statusText: 'FIELD VERIFICATION PENDING',
                        statusColor: kWarningOrange,
                        leftColor: kCriticalRed,
                      ),
                      const SizedBox(height: 16),
                      _buildIncidentCard(
                        title: 'EXTREME HEATWAVE',
                        location: 'Saddar, Rawalpindi',
                        severity: 'Severity: 7/10',
                        desc: 'Temperature hit 47°C. High risk to vulnerable population. Local administration has activated cooling centers and mobile medical teams.',
                        statusText: 'RESPONSE ACTIVE',
                        statusColor: kSuccessGreen,
                        leftColor: kWarningOrange,
                      ),
                      if (hasData) ...[
                        const SizedBox(height: 16),
                        _buildIncidentCard(
                          title: 'LIVE INCIDENT REPORT',
                          location: 'Signal Fusion Data',
                          severity: 'Severity: High',
                          desc: 'Automatically processed signal from pipeline. All agents verified and allocated resources.',
                          statusText: 'PIPELINE PROCESSED',
                          statusColor: kPrimaryBlue,
                          leftColor: kPrimaryBlue,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          const Text('INCIDENTS', style: TextStyle(
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
              border: Border.all(color: kPrimaryBlue.withOpacity(0.5)),
              color: kPrimaryBlue.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kPrimaryBlue)),
                const SizedBox(width: 6),
                const Text('ACTIVE THREATS', style: TextStyle(
                  color: kPrimaryBlue, fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard({
    required String title,
    required String location,
    required String severity,
    required String desc,
    required String statusText,
    required Color statusColor,
    required Color leftColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: leftColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                  )),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: leftColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(severity, style: TextStyle(
                    color: leftColor, fontWeight: FontWeight.w700, fontSize: 11,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(location, style: TextStyle(
                  color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 12,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Text(desc, style: TextStyle(
              color: Colors.grey.shade300, fontSize: 13, height: 1.4,
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.circle, color: statusColor, size: 10),
                const SizedBox(width: 6),
                Text(statusText, style: TextStyle(
                  color: statusColor, fontSize: 11, fontWeight: FontWeight.w700,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
