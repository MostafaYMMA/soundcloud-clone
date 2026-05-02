import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';

enum QueueAction { playNext, playLast }

class QueueRequest {
  final Track track;
  final QueueAction action;
  QueueRequest({required this.track, required this.action});
}

class QueueNotifier extends StateNotifier<QueueRequest?> {
  QueueNotifier() : super(null);

  void playNext(Track track) {
    state = QueueRequest(track: track, action: QueueAction.playNext);
  }

  void playLast(Track track) {
    state = QueueRequest(track: track, action: QueueAction.playLast);
  }

  void clear() => state = null;
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueRequest?>(
  (ref) => QueueNotifier(),
);
