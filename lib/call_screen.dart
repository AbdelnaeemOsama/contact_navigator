import 'package:flutter/material.dart';
import 'package:contact_navigator/app_theme.dart';

class CallScreen extends StatefulWidget {
  final String name;
  final String imagePath;

  const CallScreen({super.key, required this.name, required this.imagePath});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  Widget build(BuildContext context) {
    const lightBlue = Color(0xFF33A1E5);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: lightBlue.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipOval(
                    child: Image.asset(widget.imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calling...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallAction(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  'Mute',
                  isActive: _isMuted,
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                ),
                _buildCallAction(Icons.videocam, 'Video'),
                _buildCallAction(
                  _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  'Speaker',
                  isActive: _isSpeakerOn,
                  onTap: () {
                    setState(() {
                      _isSpeakerOn = !_isSpeakerOn;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCallAction(
    IconData icon,
    String label, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryBlue : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
