import 'dart:async';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../bloc/voice_assistant_bloc.dart';

class ParsedIntent {
  final VoiceIntent intent;
  final String? contactName;
  ParsedIntent({required this.intent, this.contactName});
}

class VoiceCommandService {
  final FlutterTts _tts;
  final stt.SpeechToText _stt;
  Timer? _listeningTimer;

  final Future<void> Function(Contact contact)? onNavigate;

  VoiceCommandService({
    FlutterTts? tts,
    stt.SpeechToText? speechToText,
    this.onNavigate,
  })  : _tts = tts ?? FlutterTts(),
        _stt = speechToText ?? stt.SpeechToText();

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }
    await _tts.setLanguage('ar-EG');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    return await _stt.initialize(
      onError: (e) {},
      onStatus: (_) {},
    );
  }

  Future<void> startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onFinalResult,
    required void Function(String msg) onError,
  }) async {
    _listeningTimer?.cancel();
    await _stt.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'ar_EG',
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 2),
        listenFor: const Duration(seconds: 10),
      ),
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
    );
    _listeningTimer = Timer(const Duration(seconds: 12), () {
      if (_stt.isListening) stopListening();
    });
  }

  Future<void> stopListening() async {
    _listeningTimer?.cancel();
    if (_stt.isListening) await _stt.stop();
  }

  bool get isListening => _stt.isListening;

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  ParsedIntent parseIntent(String text) {
    final t = text.trim();

    final callAr = [
      RegExp(r'اتصل\s+(?:بـ?|ب|على|ع)\s*(.+)'),
      RegExp(r'(?:كلم|هاتف|رن\s+على|بعتلك\s+مكالمة\s+ل)\s*(.+)'),
      RegExp(r'(?:ابعتلي|خليني\s+اكلم)\s+(.+)'),
    ];
    final callEn = [
      RegExp(r'(?:call|phone|dial|ring)\s+(.+)', caseSensitive: false),
    ];
    final navAr = [
      RegExp(r'(?:روح|روحنا)\s+(?:عند|ل|على|ع|لـ?|إلى)?\s*(.+)'),
      RegExp(r'(?:وصلني|خدني|ودني)\s+(?:ل|لـ?|إلى|عند)?\s*(.+)'),
      RegExp(
          r'(?:ابدأ|افتح)\s+(?:navigation|تنقل|توجيه|الخريطة\s+ل)\s*(?:ل|لـ?|إلى)?\s*(.+)'),
      RegExp(r'(?:اتجه|امشي)\s+(?:ل|لـ?|إلى|نحو)?\s*(.+)'),
    ];
    final navEn = [
      RegExp(
          r'(?:navigate\s+to|go\s+to|take\s+me\s+to|directions?\s+to|start\s+navigation\s+(?:to\s+)?)\s*(.+)',
          caseSensitive: false),
    ];

    for (final p in [...callAr, ...callEn]) {
      final m = p.firstMatch(t);
      if (m != null) {
        return ParsedIntent(
            intent: VoiceIntent.call, contactName: _clean(m.group(1)));
      }
    }
    for (final p in [...navAr, ...navEn]) {
      final m = p.firstMatch(t);
      if (m != null) {
        return ParsedIntent(
            intent: VoiceIntent.navigate, contactName: _clean(m.group(1)));
      }
    }
    return ParsedIntent(intent: VoiceIntent.unknown);
  }

  String? _clean(String? s) {
    if (s == null) return null;
    return s
        .replaceAll(
            RegExp(r'\b(من\s+فضلك|لو\s+سمحت|please)\b', caseSensitive: false),
            '')
        .trim();
  }

  Contact? findBestMatch(String name, List<Contact> contacts) {
    if (name.isEmpty || contacts.isEmpty) return null;
    final q = name.toLowerCase().trim();

    for (final c in contacts) {
      if ((c.displayName ?? '').toLowerCase() == q) return c;
    }
    for (final c in contacts) {
      if ((c.displayName ?? '').toLowerCase().startsWith(q)) return c;
    }
    for (final c in contacts) {
      if ((c.displayName ?? '').toLowerCase().contains(q)) return c;
    }

    final queryWords = q.split(RegExp(r'\s+'));
    Contact? bestMatch;
    var bestScore = 0;
    for (final c in contacts) {
      final contactWords =
          (c.displayName ?? '').toLowerCase().split(RegExp(r'\s+'));
      var score = 0;
      for (final qw in queryWords) {
        if (qw.length < 2) continue;
        for (final cw in contactWords) {
          if (cw.contains(qw) || qw.contains(cw)) score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = c;
      }
    }
    return bestScore > 0 ? bestMatch : null;
  }

  Future<void> executeCall(Contact contact) async {
    final phone =
        contact.phones.isNotEmpty ? contact.phones.first.number : null;
    if (phone == null) {
      await speak('مفيش رقم لـ ${contact.displayName}');
      return;
    }
    await FlutterPhoneDirectCaller.callNumber(phone);
  }

  Future<void> executeNavigation(Contact contact) async {
    if (onNavigate != null) {
      await onNavigate!(contact);
    }
  }

  void dispose() {
    _listeningTimer?.cancel();
    _tts.stop();
    _stt.stop();
  }
}
