import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'photo_verification_screen.dart';
import 'voice_verification_screen.dart';

/// Router shim — dispatches to the right verification screen
/// based on proofType path parameter.
class VerificationScreen extends StatelessWidget {
  final String levelId;
  final String proofType;

  const VerificationScreen({
    super.key,
    required this.levelId,
    required this.proofType,
  });

  @override
  Widget build(BuildContext context) {
    switch (proofType) {
      case 'photo':
      case 'screenshot':
        return PhotoVerificationScreen(levelId: levelId);
      case 'voice':
        return VoiceVerificationScreen(levelId: levelId);
      case 'quiz':
      case 'text':
      case 'code':
      default:
        return QuizScreen(levelId: levelId);
    }
  }
}
