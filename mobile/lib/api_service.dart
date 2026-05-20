import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ═══════════════════════════════════════════════════════════════
// CIRO API Service & State Management
// ═══════════════════════════════════════════════════════════════

class CiroApiService {
  static const String geminiApiKey = 'AIzaSyAWt1MOPc_gIAQj3lUgGr0rwj5JYGdEkSg';

  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: geminiApiKey,
    systemInstruction: Content.system(
      'You are CIRO, AI crisis assistant for Islamabad/Rawalpindi Pakistan. '
      'Current crises: G-10 water emergency severity 8/10, '
      'Saddar heatwave 47C severity 7/10. '
      'Answer in same language user writes in. '
      'Keep answers short, 3-4 lines max, actionable.'
    ),
  );

  static String getKeywordFallback(String question) {
    final q = question.toLowerCase();
    if (q.contains('resource') || q.contains('deploy') || q.contains('kitne')) {
      return 'Command Center Update: Currently 9 resources are active in Islamabad/Rawalpindi sectors (2 Ambulances in Saddar, 3 Police units in G-10, 2 Water Tankers in G-10, and 1 Medical Outreach unit).';
    }
    if (q.contains('heatwave') || q.contains('saddar') || q.contains('garmi') || q.contains('heat')) {
      return 'Saddar Heatwave Alert: Temperature is 47°C. Response active. Local cooling centers and mobile medical units are deployed at Saddar bazaar area. Stay hydrated and avoid direct sunlight.';
    }
    if (q.contains('g-10') || q.contains('water') || q.contains('paani') || q.contains('flooding')) {
      return 'G-10 Water Emergency: A major water main burst has been confirmed by WASA field crews on Street 12. Islamabad Police is rerouting traffic. Avoid G-10 main roads.';
    }
    if (q.contains('safe') || q.contains('hifazat') || q.contains('elaka')) {
      return 'Safety Alert: Sector G-10 has localized flooding on main roads. Saddar is experiencing extreme heat. Rest of the sectors in Islamabad/Rawalpindi are currently clear and safe.';
    }
    return 'CIRO Command Center AI: Understood. Please provide details regarding the G-10 water burst or Saddar heatwave emergency so I can direct resources accordingly.';
  }

  static Future<String> askAssistant(String question) async {
    try {
      final response = await _model.generateContent([
        Content.text(question),
      ]);
      return response.text ?? 'Unable to process request';
    } catch (e) {
      debugPrint('Gemini SDK error: $e. Using keyword fallback.');
      return getKeywordFallback(question);
    }
  }
}

class CiroState extends ChangeNotifier {
  bool isLive = false;
  bool isLoading = false;

  // Operational metrics
  int activeCrises = 2;
  int resourcesDeployed = 9;
  int avgResponse = 8;
  String livesProtected = '20,000+';

  void triggerPipelineResults() {
    isLive = true;
    activeCrises = 2;
    resourcesDeployed = 14; // updated count
    avgResponse = 5;        // reduced time
    livesProtected = '25,000+'; // updated lives count
    notifyListeners();
  }
}

final ciroState = CiroState();
