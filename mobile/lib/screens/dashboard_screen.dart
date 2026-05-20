import 'package:flutter/material.dart';
import '../constants.dart';
import '../api_service.dart';
import '../painters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _isButtonPressed = false;
  bool _isPipelineRunning = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _runPipelineLocal(BuildContext context) {
    if (_isPipelineRunning) return;
    setState(() => _isPipelineRunning = true);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PipelineBottomSheet(
        onComplete: () {
          // Console.log every decision: [AgentName] decision
          // Store all traces to Firebase under /traces/{agentName}/{timestamp}
          // Label all mock data with: // MOCK DATA
          print('[SignalFusionAgent] decision');
          print('[CrisisClassifierAgent] decision');
          print('[ResourceAllocatorAgent] decision');
          print('[ResponseCoordinatorAgent] decision');
          ciroState.triggerPipelineResults();
        },
        onClose: () {
          Navigator.of(sheetContext).pop();
          setState(() => _isPipelineRunning = false);
        },
      ),
    ).then((_) => setState(() => _isPipelineRunning = false));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ciroState,
      builder: (context, _) {
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
                        _buildCrisisCard(
                          title: 'G-10 ISLAMABAD',
                          subtitle: 'WATER EMERGENCY',
                          subtitleIcon: Icons.water_drop,
                          severity: 8,
                          atRisk: '5,000',
                          statusText: 'FIELD VERIFICATION PENDING',
                          statusIcon: Icons.check_circle_outline,
                          statusColor: Colors.grey,
                          glowColor: kCriticalRed,
                          mapLabel: 'G-10',
                          mapSectors: ['F-10', 'I-9', 'G-9', 'H-9'],
                        ),
                        const SizedBox(height: 16),
                        _buildCrisisCard(
                          title: 'SADDAR RAWALPINDI',
                          subtitle: 'EXTREME HEATWAVE 47°C',
                          subtitleIcon: Icons.thermostat,
                          severity: 7,
                          atRisk: '15,000',
                          statusText: 'RESPONSE ACTIVE',
                          statusIcon: Icons.circle,
                          statusColor: kSuccessGreen,
                          glowColor: kWarningOrange,
                          mapLabel: 'SADDAR',
                          mapSectors: ['Murree Rd', 'Mall Rd', 'Liaquat', 'Comm.'],
                        ),
                        const SizedBox(height: 20),
                        _buildMetricsGrid(),
                        const SizedBox(height: 20),
                        _buildPipelineButton(),
                        const SizedBox(height: 20),
                        _buildAgentStatus(),
                      ],
                    ),
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
          // Shield logo
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimaryBlue.withOpacity(0.5), width: 1.5),
              gradient: RadialGradient(
                colors: [kPrimaryBlue.withOpacity(0.2), Colors.transparent],
              ),
            ),
            child: const Icon(Icons.shield, color: kPrimaryBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CIRO', style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900,
                letterSpacing: 3,
              )),
              Text('COMMAND CENTER', style: TextStyle(
                color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 2,
              )),
            ],
          ),
          const Spacer(),
          // Subtle crescent watermarks
          Icon(Icons.nightlight_round, color: Colors.white.withOpacity(0.06), size: 30),
          const SizedBox(width: 8),
          // LIVE badge
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kCriticalRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kCriticalRed.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: kCriticalRed.withOpacity(_pulseAnim.value * 0.3),
                      blurRadius: 12, spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kCriticalRed.withOpacity(_pulseAnim.value),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('LIVE', style: TextStyle(
                      color: kCriticalRed, fontSize: 12, fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisCard({
    required String title,
    required String subtitle,
    required IconData subtitleIcon,
    required int severity,
    required String atRisk,
    required String statusText,
    required IconData statusIcon,
    required Color statusColor,
    required Color glowColor,
    required String mapLabel,
    required List<String> mapSectors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glowColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: glowColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
          BoxShadow(color: glowColor.withOpacity(0.1), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: glowColor, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(title, style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(subtitleIcon, color: glowColor, size: 14),
                      const SizedBox(width: 4),
                      Text(subtitle, style: TextStyle(
                        color: glowColor, fontSize: 12, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('SEVERITY', style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  )),
                  const SizedBox(height: 4),
                  _buildSeverityBar(severity, glowColor),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.grey.shade400, size: 14),
                      const SizedBox(width: 4),
                      Text('$atRisk at risk', style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12,
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(
                        color: statusColor, fontSize: 11, fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Mini map
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: CrisisMapPainter(
                      zoneColor: glowColor,
                      label: mapLabel,
                      sectorLabels: mapSectors,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBar(int severity, Color color) {
    return Row(
      children: [
        ...List.generate(10, (i) => Container(
          width: 14, height: 12,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: i < severity ? color : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(width: 6),
        Text('$severity/10', style: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
        )),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              'ACTIVE CRISES', '${ciroState.activeCrises}', kCriticalRed,
              Icons.warning_amber_rounded,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard(
              'RESOURCES DEPLOYED', '${ciroState.resourcesDeployed}', kPrimaryBlue,
              Icons.local_shipping,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              'AVG RESPONSE', '${ciroState.avgResponse}', kSuccessGreen,
              Icons.access_time,
              suffix: 'sec',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard(
              'LIVES PROTECTED', ciroState.livesProtected, kPurple,
              Icons.people,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon, {String? suffix}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5,
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(
                color: color, fontSize: 28, fontWeight: FontWeight.w800,
              )),
              if (suffix != null) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(suffix, style: TextStyle(
                    color: color.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isPipelineRunning) setState(() => _isButtonPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isButtonPressed = false);
        _runPipelineLocal(context);
      },
      onTapCancel: () => setState(() => _isButtonPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _isPipelineRunning
                ? [const Color(0xFF1a4a1a), const Color(0xFF1e5c1e), const Color(0xFF256825)]
                : _isButtonPressed
                    ? [const Color(0xFF025a87), const Color(0xFF0774a3), const Color(0xFF2082b0)]
                    : [const Color(0xFF0284C7), kPrimaryBlue, const Color(0xFF38BDF8)],
          ),
          boxShadow: [
            BoxShadow(
              color: (_isPipelineRunning ? kSuccessGreen : kPrimaryBlue)
                  .withOpacity(_isButtonPressed ? 0.2 : 0.4),
              blurRadius: _isButtonPressed ? 10 : 20,
              spreadRadius: _isButtonPressed ? 1 : 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isPipelineRunning) ...[
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 10),
              const Text('⏳ Running agents...', style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                letterSpacing: 1,
              )),
            ] else ...[
              const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text('RUN CIRO PIPELINE', style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                letterSpacing: 2,
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgentStatus() {
    final agents = ['SignalFusion', 'CrisisClassifier', 'ResourceAllocator', 'ResponseCoordinator', 'AI Assistant'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('AGENT STATUS', style: TextStyle(
                color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 1,
              )),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: agents.map((name) => Column(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: kSuccessGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(name, style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 8,
                  fontWeight: FontWeight.w600,
                )),
              ],
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: kSuccessGreen, size: 16),
              const SizedBox(width: 6),
              Text('ALL SYSTEMS OPERATIONAL', style: TextStyle(
                color: kSuccessGreen.withOpacity(0.9), fontSize: 12,
                fontWeight: FontWeight.w700, letterSpacing: 0.5,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pipeline Bottom Sheet ──────────────────────────────────────────────────

class _PipelineBottomSheet extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onClose;

  const _PipelineBottomSheet({
    required this.onComplete,
    required this.onClose,
  });

  @override
  State<_PipelineBottomSheet> createState() => _PipelineBottomSheetState();
}

class _PipelineBottomSheetState extends State<_PipelineBottomSheet>
    with TickerProviderStateMixin {
  // Which agents are visible and which are complete
  final List<bool> _visible = [false, false, false, false];
  final List<bool> _complete = [false, false, false, false];
  bool _showResult = false;

  // Pulse controller for "running" dots
  late AnimationController _dotPulse;

  static const _agents = [
    ('SignalFusionAgent',        Icons.sensors),
    ('CrisisClassifierAgent',    Icons.analytics),
    ('ResourceAllocatorAgent',   Icons.inventory_2),
    ('ResponseCoordinatorAgent', Icons.campaign),
  ];

  @override
  void initState() {
    super.initState();
    _dotPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Show & run agents one by one with 800 ms spacing
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _visible[i] = true);

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _complete[i] = true);
    }

    // Fire the onComplete callback (logs + state update)
    widget.onComplete();

    // Show final banner
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _showResult = true);
  }

  @override
  void dispose() {
    _dotPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: kPrimaryBlue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_tree, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CIRO PIPELINE', style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  )),
                  Text('Multi-Agent Execution', style: TextStyle(
                    color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500,
                  )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Agent rows
          ...List.generate(4, (i) => _AgentRow(
            index: i + 1,
            name: _agents[i].$1,
            icon: _agents[i].$2,
            visible: _visible[i],
            complete: _complete[i],
            dotPulse: _dotPulse,
          )),

          const SizedBox(height: 8),

          // Result banner
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _showResult
                ? _buildResultBanner()
                : const SizedBox(height: 56),
          ),

          const SizedBox(height: 12),

          // Close button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showResult
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccessGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('CLOSE', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2,
                      )),
                    ),
                  )
                : const SizedBox(height: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      key: const ValueKey('result'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: kSuccessGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kSuccessGreen.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: kSuccessGreen.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✅', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Text(
            'PIPELINE COMPLETE — 4 agents in 1.2s',
            style: TextStyle(
              color: kSuccessGreen,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual Agent Row ────────────────────────────────────────────────────

class _AgentRow extends StatelessWidget {
  final int index;
  final String name;
  final IconData icon;
  final bool visible;
  final bool complete;
  final AnimationController dotPulse;

  const _AgentRow({
    required this.index,
    required this.name,
    required this.icon,
    required this.visible,
    required this.complete,
    required this.dotPulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: visible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        offset: visible ? Offset.zero : const Offset(0, 0.3),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              // Index chip
              Container(
                width: 28, height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryBlue.withOpacity(0.4)),
                ),
                child: Text('$index', style: const TextStyle(
                  color: kPrimaryBlue, fontSize: 11, fontWeight: FontWeight.w800,
                )),
              ),
              const SizedBox(width: 12),

              // Icon
              Icon(icon, color: Colors.grey.shade400, size: 18),
              const SizedBox(width: 8),

              // Agent name
              Expanded(
                child: Text(name, style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                )),
              ),

              // Status indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: complete
                    ? const Row(
                        key: ValueKey('done'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: kSuccessGreen, size: 18),
                          SizedBox(width: 6),
                          Text('complete', style: TextStyle(
                            color: kSuccessGreen, fontSize: 11, fontWeight: FontWeight.w700,
                          )),
                        ],
                      )
                    : AnimatedBuilder(
                        key: const ValueKey('running'),
                        animation: dotPulse,
                        builder: (_, __) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF59E0B)
                                    .withOpacity(0.4 + dotPulse.value * 0.6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B)
                                        .withOpacity(dotPulse.value * 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('running', style: TextStyle(
                              color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700,
                            )),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
