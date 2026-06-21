part of 'voice_assistant_bloc.dart';

enum VoiceIntent { call, navigate, unknown }

abstract class VoiceAssistantState {}

class VoiceAssistantIdle extends VoiceAssistantState {}

class VoiceAssistantListening extends VoiceAssistantState {
  final String partialText;
  VoiceAssistantListening({this.partialText = ''});
}

class VoiceAssistantProcessing extends VoiceAssistantState {
  final String recognizedText;
  VoiceAssistantProcessing(this.recognizedText);
}

class VoiceAssistantContactFound extends VoiceAssistantState {
  final VoiceIntent intent;
  final Contact contact;
  VoiceAssistantContactFound({required this.intent, required this.contact});
}

class VoiceAssistantContactNotFound extends VoiceAssistantState {
  final String searchedName;
  VoiceAssistantContactNotFound(this.searchedName);
}

class VoiceAssistantUnknownIntent extends VoiceAssistantState {
  final String recognizedText;
  VoiceAssistantUnknownIntent(this.recognizedText);
}

class VoiceAssistantExecuting extends VoiceAssistantState {
  final VoiceIntent intent;
  final Contact contact;
  VoiceAssistantExecuting({required this.intent, required this.contact});
}

class VoiceAssistantError extends VoiceAssistantState {
  final String message;
  VoiceAssistantError(this.message);
}
