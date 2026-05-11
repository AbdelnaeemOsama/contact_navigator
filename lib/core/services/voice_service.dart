import 'package:flutter_tts/flutter_tts.dart';
import 'package:contact_navigator/core/services/settings_service.dart';

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

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> setEnabled(bool value) async {
    await _settingsService.setVoiceEnabled(value);
  }

  Future<void> speak(String text) async {
    if (!isEnabled || text.isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
