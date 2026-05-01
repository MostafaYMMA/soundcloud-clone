import 'package:flutter_riverpod/flutter_riverpod.dart';

final repostedTracksProvider =
    StateNotifierProvider<RepostedTracksNotifier, Set<String>>(
      (ref) => RepostedTracksNotifier(),
    );

class RepostedTracksNotifier extends StateNotifier<Set<String>> {
  RepostedTracksNotifier() : super({});

  bool isReposted(String trackId) => state.contains(trackId);

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
