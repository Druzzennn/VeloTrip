import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Partage un défi via la feuille native, avec repli presse-papiers.
class ShareService {
  static String buildMessage({
    required int day,
    required String title,
    String? description,
    String? textAnswer,
    DateTime? completedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('❄️ FrostPedal — Carnet de voyage')
      ..writeln()
      ..writeln('📍 Jour $day · $title');

    if (description != null && description.trim().isNotEmpty) {
      buffer.writeln(description.trim());
    }

    if (textAnswer != null && textAnswer.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('💬 Mon souvenir')
        ..writeln('« ${textAnswer.trim()} »');
    }

    if (completedAt != null) {
      buffer.writeln();
      buffer.writeln(
        '✅ Validé le ${DateFormat('d MMMM yyyy', 'fr_FR').format(completedAt)}',
      );
    }

    buffer
      ..writeln()
      ..writeln('—')
      ..write('Mon aventure à vélo dans le Grand Nord 🚲');

    return buffer.toString().trim();
  }

  static Future<void> shareChallenge({
    required BuildContext context,
    required int day,
    required String title,
    String? description,
    String? textAnswer,
    DateTime? completedAt,
    String? photoPath,
    Rect? shareOrigin,
  }) async {
    final message = buildMessage(
      day: day,
      title: title,
      description: description,
      textAnswer: textAnswer,
      completedAt: completedAt,
    );
    final subject = 'FrostPedal — Jour $day · $title';

    try {
      if (photoPath != null && photoPath.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            text: message,
            subject: subject,
            title: subject,
            files: [XFile(photoPath)],
            sharePositionOrigin: shareOrigin,
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: message,
            subject: subject,
            title: subject,
            sharePositionOrigin: shareOrigin,
          ),
        );
      }
    } on MissingPluginException {
      if (context.mounted) await _copyToClipboard(context, message);
    } on PlatformException {
      if (photoPath != null && photoPath.isNotEmpty) {
        try {
          await SharePlus.instance.share(
            ShareParams(text: message, subject: subject, title: subject),
          );
          return;
        } on Object {
          // ignore et passe au presse-papiers
        }
      }
      if (context.mounted) await _copyToClipboard(context, message);
    }
  }

  static Future<void> _copyToClipboard(
    BuildContext context,
    String text,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Partage indisponible — texte copié dans le presse-papiers',
        ),
      ),
    );
  }
}
