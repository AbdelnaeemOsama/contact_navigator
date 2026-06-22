import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/voice_assistant_service.dart';
import '../../contacts/bloc/contacts_bloc.dart';
import '../../contacts/bloc/contacts_state.dart';

part 'voice_assistant_event.dart';
part 'voice_assistant_state.dart';

class VoiceAssistantBloc
    extends Bloc<VoiceAssistantEvent, VoiceAssistantState> {
  final VoiceCommandService _service;
  final ContactsBloc _contactsBloc;

  VoiceAssistantBloc({
    required VoiceCommandService service,
    required ContactsBloc contactsBloc,
  }) : _service = service,
       _contactsBloc = contactsBloc,
       super(VoiceAssistantIdle()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<SpeechResultEvent>(_onSpeechResult);
    on<ExecuteActionEvent>(_onExecuteAction);
    on<ResetAssistantEvent>(_onReset);
  }

  Future<void> _onStartListening(
    StartListeningEvent event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      final available = await _service.initialize();
      if (!available) {
        emit(VoiceAssistantError('الميكروفون مش متاح'));
        return;
      }
      emit(VoiceAssistantListening());
      await _service.startListening(
        onPartialResult: (text) =>
            emit(VoiceAssistantListening(partialText: text)),
        onFinalResult: (text) =>
            add(SpeechResultEvent(text, isFinal: true)),
        onError: (msg) => emit(VoiceAssistantError(msg)),
      );
    } catch (e) {
      emit(VoiceAssistantError('حدث خطأ: $e'));
    }
  }

  Future<void> _onStopListening(
    StopListeningEvent event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    await _service.stopListening();
  }

  Future<void> _onSpeechResult(
    SpeechResultEvent event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    if (!event.isFinal || event.text.trim().isEmpty) return;

    emit(VoiceAssistantProcessing(event.text));

    final parsed = _service.parseIntent(event.text);

    if (parsed.intent == VoiceIntent.unknown || parsed.contactName == null) {
      await _service.speak(
        'لم أفهم الأمر. يمكنك قول اتصل بـ أو اذهب إلى متبوعاً بالاسم',
      );
      emit(VoiceAssistantUnknownIntent(event.text));
      return;
    }

    final contacts = _getContactsFromBloc();
    final contact = _service.findBestMatch(parsed.contactName!, contacts);

    if (contact == null) {
      await _service.speak('مش لاقي ${parsed.contactName} في جهات الاتصال');
      emit(VoiceAssistantContactNotFound(parsed.contactName!));
      return;
    }

    final action = parsed.intent == VoiceIntent.call ? 'هاتصل' : 'هروح لـ';
    await _service.speak('$action ${contact.displayName}');

    emit(VoiceAssistantContactFound(intent: parsed.intent, contact: contact));

    await Future.delayed(const Duration(milliseconds: 800));
    add(ExecuteActionEvent(intent: parsed.intent, contact: contact));
  }

  Future<void> _onExecuteAction(
    ExecuteActionEvent event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    emit(VoiceAssistantExecuting(intent: event.intent, contact: event.contact));

    if (event.intent == VoiceIntent.call) {
      await _service.executeCall(event.contact);
    } else {
      await _service.executeNavigation(event.contact);
    }

    await Future.delayed(const Duration(seconds: 2));
    emit(VoiceAssistantIdle());
  }

  void _onReset(ResetAssistantEvent event, Emitter<VoiceAssistantState> emit) {
    _service.stopListening();
    emit(VoiceAssistantIdle());
  }

  List<Contact> _getContactsFromBloc() {
    final state = _contactsBloc.state;
    if (state is ContactsLoaded) return state.allContacts;
    return [];
  }

  @override
  Future<void> close() {
    _service.dispose();
    return super.close();
  }
}
