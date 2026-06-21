import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/voice_assistant_bloc.dart';

class VoiceAssistantFab extends StatelessWidget {
  const VoiceAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
      builder: (context, state) {
        final isActive = state is! VoiceAssistantIdle;
        return FloatingActionButton(
          heroTag: 'voice_fab',
          backgroundColor:
              isActive ? const Color(0xFF1565C0) : const Color(0xFF1E88E5),
          onPressed: () => _onFabPressed(context, state),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isActive
                ? const Icon(Icons.mic,
                    key: ValueKey('mic_on'), color: Colors.white)
                : const Icon(Icons.mic_none,
                    key: ValueKey('mic_off'), color: Colors.white),
          ),
        );
      },
    );
  }

  void _onFabPressed(BuildContext context, VoiceAssistantState state) {
    if (state is VoiceAssistantIdle) {
      final bloc = context.read<VoiceAssistantBloc>();
      bloc.add(StartListeningEvent());
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const VoiceAssistantOverlay(),
        ),
      ).whenComplete(() {
        bloc.add(ResetAssistantEvent());
      });
    } else {
      Navigator.of(context).pop();
    }
  }
}

class VoiceAssistantOverlay extends StatelessWidget {
  const VoiceAssistantOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoiceAssistantBloc, VoiceAssistantState>(
      listener: (context, state) {
        if (state is VoiceAssistantIdle) {
          final route = ModalRoute.of(context);
          if (route != null && route.isCurrent) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                _buildContent(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, VoiceAssistantState state) {
    if (state is VoiceAssistantListening) {
      return Column(children: [
        const _PulsingMic(),
        const SizedBox(height: 16),
        const Text('بسمعك...',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        if (state.partialText.isNotEmpty)
          Text(state.partialText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
      ]);
    }
    if (state is VoiceAssistantProcessing) {
      return Column(children: [
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 16),
        Text('"${state.recognizedText}"',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('بحلل...',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
      ]);
    }
    if (state is VoiceAssistantContactFound) {
      final isCall = state.intent == VoiceIntent.call;
      return Column(children: [
        Icon(isCall ? Icons.call : Icons.navigation,
            color: Colors.greenAccent, size: 40),
        const SizedBox(height: 12),
        Text(isCall ? 'هاتصل بـ' : 'هروح لـ',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Text(state.contact.displayName ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600)),
      ]);
    }
    if (state is VoiceAssistantExecuting) {
      final isCall = state.intent == VoiceIntent.call;
      return Column(children: [
        const CircularProgressIndicator(color: Colors.greenAccent),
        const SizedBox(height: 12),
        Text(
          isCall
              ? 'بيتصل بـ ${state.contact.displayName}...'
              : 'بيفتح الخريطة لـ ${state.contact.displayName}...',
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ]);
    }
    if (state is VoiceAssistantContactNotFound) {
      return Column(children: [
        const Icon(Icons.person_search, color: Colors.orangeAccent, size: 40),
        const SizedBox(height: 12),
        Text('مش لاقي "${state.searchedName}"',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('جرّب قول الاسم بالكامل',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
      ]);
    }
    if (state is VoiceAssistantUnknownIntent) {
      return Column(children: [
        const Icon(Icons.help_outline,
            color: Colors.orangeAccent, size: 40),
        const SizedBox(height: 12),
        Text('"${state.recognizedText}"',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('مش فاهم. جرّب "اتصل بـ..." أو "روح عند..."',
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center),
      ]);
    }
    if (state is VoiceAssistantError) {
      return Column(children: [
        const Icon(Icons.mic_off, color: Colors.redAccent, size: 40),
        const SizedBox(height: 12),
        Text(state.message,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ]);
    }
    return const SizedBox.shrink();
  }
}

class _PulsingMic extends StatefulWidget {
  const _PulsingMic();
  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade300, width: 1.5),
              ),
            ),
          ),
          Transform.scale(
            scale: (_scale.value + 1) / 2,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade700.withValues(alpha: 0.3),
              ),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.blue),
            child: const Icon(Icons.mic, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}


