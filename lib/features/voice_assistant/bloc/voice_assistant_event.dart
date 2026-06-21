part of 'voice_assistant_bloc.dart';

abstract class VoiceAssistantEvent {}

class StartListeningEvent extends VoiceAssistantEvent {}

class StopListeningEvent extends VoiceAssistantEvent {}

class SpeechResultEvent extends VoiceAssistantEvent {
  final String text;
  final bool isFinal;
  SpeechResultEvent(this.text, {this.isFinal = false});
}

class ExecuteActionEvent extends VoiceAssistantEvent {
  final VoiceIntent intent;
  final Contact contact;
  ExecuteActionEvent({required this.intent, required this.contact});
}

class ResetAssistantEvent extends VoiceAssistantEvent {}
