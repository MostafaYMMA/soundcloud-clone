import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';

final likedTracksProvider =
    StateNotifierProvider<LikedTracksNotifier, Set<String>>(
  (ref) => LikedTracksNotifier(),
);

class LikedTracksNotifier extends StateNotifier<Set<String>> {
  LikedTracksNotifier() : super({});

  bool isLiked(String trackId) {
    return state.contains(trackId);
  }

  void toggleLocal(String trackId) {
    final newSet = Set<String>.from(state);

    if (newSet.contains(trackId)) {
      newSet.remove(trackId);
    } else {
      newSet.add(trackId);
    }

    state = newSet;
  }

  void setAll(Set<String> ids) {
    state = ids;
  }
}