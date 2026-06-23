import 'package:flutter_tts/flutter_tts.dart';
import 'package:contact_navigator/core/services/settings_service.dart';

// خدمة المساعد الصوتي وتوليف الكلام من النصوص (TTS)
class VoiceAssistantService {
  static VoiceAssistantService? _instance;
  final SettingsService _settingsService;
  
  factory VoiceAssistantService(SettingsService settingsService) {
    _instance ??= VoiceAssistantService._internal(settingsService);
    return _instance!;
  }
  
  VoiceAssistantService._internal(this._settingsService);

  final FlutterTts _tts = FlutterTts();

  bool get isEnabled => _settingsService.isVoiceEnabled();

  // تهيئة الخدمة وضبط اللغة وسرعة نطق الكلمات ومستوى الصوت ونبرته
  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // تمكين أو تعطيل المساعد الصوتي
  Future<void> setEnabled(bool value) async {
    await _settingsService.setVoiceEnabled(value);
  }

  // نطق النص الممرر صوتياً إذا كانت الخدمة مفعلة
  Future<void> speak(String text) async {
    if (!isEnabled || text.isEmpty) return;
    await _tts.speak(text);
  }

  // إيقاف النطق الصوتي الجاري حالياً فوراً
  Future<void> stop() async {
    await _tts.stop();
  }
}
