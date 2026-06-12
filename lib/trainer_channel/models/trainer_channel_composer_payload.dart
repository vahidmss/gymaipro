import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';

class TrainerChannelComposerPayload {
  TrainerChannelComposerPayload({
    required this.contentType,
    this.textContent,
    this.mediaUrl,
    this.mediaDurationSeconds,
  });

  final TrainerChannelContentType contentType;
  final String? textContent;
  final String? mediaUrl;
  final int? mediaDurationSeconds;
}
