import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_project/mock_data/mock_tracks.dart';
import 'package:my_project/models/track.dart';
import 'package:my_project/navigation/bottom_nav_bar.dart';
import 'package:my_project/screens/feed/feed_screen.dart';
import 'package:my_project/screens/home/home_screen.dart';
import 'package:my_project/screens/library/library_screen.dart';
import 'package:my_project/screens/search/search_screen.dart';
import 'package:my_project/screens/upgrade/upgrade_screen.dart';
import 'package:my_project/widgets/full_player.dart';
import 'package:my_project/widgets/mini_player.dart';
import 'package:my_project/screens/auth/welcome_screen.dart';
import 'package:my_project/providers/auth_providers.dart';
import './providers/track_provider.dart';
import './providers/library_providers.dart';
import './providers/queue_provider.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _selectedIndex = 0;

  final AudioPlayer _player = AudioPlayer();
  late final ValueNotifier<Track> _currentTrackNotifier;

  bool _isPlaying = false;
  bool _hasLoaded = false;

  Track _currentTrack = MockTracks.hotTrack;
  Duration _totalDuration = Duration.zero;

  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  List<Track> _queue = [];
  int _currentQueueIndex = -1;

  String? _lastRecordedTrackId;

  final Map<int, Widget> _subScreens = {};
  bool _bootstrapped = false;
  bool _queueListenerRegistered = false;

  void _pushSubScreen(Widget screen) {
    setState(() => _subScreens[_selectedIndex] = screen);
  }

  void _popSubScreen() {
    setState(() => _subScreens.remove(_selectedIndex));
  }

  @override
  void initState() {
    super.initState();
    _currentTrackNotifier = ValueNotifier(MockTracks.hotTrack);
    _listenToPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_queueListenerRegistered) return;
    _queueListenerRegistered = true;
    ref.listenManual(queueProvider, (previous, next) {
      if (next == null) return;
      if (next.action == QueueAction.playNext) {
        _addToQueueNext(next.track);
      } else {
        _addToQueueLast(next.track);
      }
      ref.read(queueProvider.notifier).clear();
    });
  }

  void _listenToPlayer() {
    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() {
        _totalDuration =
            duration ?? Duration(seconds: _currentTrack.durationSeconds ?? 0);
      });
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      debugPrint(
        'PLAYER STATE: ${state.processingState} playing=${state.playing}',
      );
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _playNextInQueue();
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    _currentTrackNotifier.dispose();
    super.dispose();
  }

  // ── Queue management ───────────────────────────────────────────────────────

  void _setQueueAndPlay(List<Track> tracks, int startIndex) {
    _queue = List.from(tracks);
    _currentQueueIndex = startIndex;
    _playTrack(tracks[startIndex]);
  }

  void _addToQueueNext(Track track) {
    if (_queue.isEmpty) {
      _queue = [_currentTrack, track];
      _currentQueueIndex = 0;
      if (!_isPlaying) {
        _currentQueueIndex = 1;
        _playTrack(track);
        return;
      }
    } else {
      _queue.removeWhere((t) => t.trackId == track.trackId);
      final insertAt = (_currentQueueIndex + 1).clamp(0, _queue.length);
      _queue.insert(insertAt, track);
      // Queue ended and not playing — play this track immediately
      if (!_isPlaying) {
        _currentQueueIndex = insertAt;
        _playTrack(track);
        return;
      }
    }
    debugPrint(
      'QUEUE NEXT: ${_queue.map((t) => t.title).toList()} idx=$_currentQueueIndex',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${track.title} will play next'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToQueueLast(Track track) {
    if (_queue.isEmpty) {
      _queue = [_currentTrack, track];
      _currentQueueIndex = 0;
      if (!_isPlaying) {
        _currentQueueIndex = 1;
        _playTrack(track);
        return;
      }
    } else {
      _queue.removeWhere((t) => t.trackId == track.trackId);
      _queue.add(track);
      // Queue ended and not playing — play this track immediately
      if (!_isPlaying) {
        _currentQueueIndex = _queue.length - 1;
        _playTrack(track);
        return;
      }
    }
    debugPrint(
      'QUEUE LAST: ${_queue.map((t) => t.title).toList()} idx=$_currentQueueIndex',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${track.title} added to queue'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _playNextInQueue() async {
    debugPrint(
      'PLAY NEXT CALLED: idx=$_currentQueueIndex len=${_queue.length}',
    );
    if (_currentQueueIndex < _queue.length - 1) {
      _currentQueueIndex++;
      debugPrint('PLAYING NEXT: ${_queue[_currentQueueIndex].title}');
      await _playTrack(_queue[_currentQueueIndex]);
    } else {
      debugPrint('QUEUE ENDED - no more tracks');
    }
  }

  // ── Direct user tap ────────────────────────────────────────────────────────

  Future<void> _handlePlay(Track track) async {
    final existingIndex = _queue.indexWhere((t) => t.trackId == track.trackId);
    if (existingIndex >= 0) {
      _currentQueueIndex = existingIndex;
      await _playTrack(track);
    } else {
      _queue = [track];
      _currentQueueIndex = 0;
      await _playTrack(track);
    }
  }

  // ── Core play logic ────────────────────────────────────────────────────────

  Future<void> _playTrack(Track track) async {
    try {
      final streamData = await ref
          .read(tracksServiceProvider)
          .getTrackStream(trackId: track.trackId);

      final rawUrl = streamData['stream_url'];

      if (rawUrl == null || rawUrl.toString().isEmpty) {
        debugPrint('Invalid stream URL');
        return;
      }

      final url = rawUrl.toString().startsWith('http')
          ? rawUrl.toString()
          : 'https://streamline-swp.duckdns.org$rawUrl';

      if (_currentTrack.trackId == track.trackId && _isPlaying) {
        await _player.pause();
        return;
      }

      if (_currentTrack.trackId != track.trackId || !_hasLoaded) {
        setState(() {
          _hasLoaded = true;
          _currentTrack = track;
          _totalDuration = Duration(seconds: track.durationSeconds ?? 0);
        });
        _currentTrackNotifier.value = track;

        try {
          await _player.setUrl(url);
        } catch (e) {
          debugPrint('just_audio load error: $e');
          return;
        }
      }

      await _player.play();

      if (_lastRecordedTrackId != track.trackId) {
        _lastRecordedTrackId = track.trackId;
        ref
            .read(tracksServiceProvider)
            .recordPlay(trackId: track.trackId)
            .then((_) {
              ref.invalidate(recentlyPlayedProvider);
              ref.invalidate(listeningHistoryProvider);
            })
            .catchError((_) {});
      }
    } catch (e, stack) {
      debugPrint('Audio load failed: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  Future<void> _toggleCurrentTrack() async {
    await _playTrack(_currentTrack);
  }

  Future<void> _seekTo(Duration position) async {
    final maxDuration = _totalDuration.inMilliseconds > 0
        ? _totalDuration
        : Duration(seconds: _currentTrack.durationSeconds ?? 0);

    final clamped = position < Duration.zero
        ? Duration.zero
        : position > maxDuration
        ? maxDuration
        : position;

    await _player.seek(clamped);
  }

  void _openFullPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPlayer(
          trackNotifier: _currentTrackNotifier,
          player: _player,
          onPlayPause: _toggleCurrentTrack,
          onSeek: _seekTo,
          onSkipNext: () => _playNextInQueue(),
        ),
      ),
    );
  }

  List<Widget> _buildScreens() => [
    HomeScreen(onTrackTap: _handlePlay, onQueuePlay: _setQueueAndPlay),
    FeedScreen(onTrackTap: _handlePlay),
    SearchScreen(),
    LibraryScreen(
      onNavigate: _pushSubScreen,
      onBack: _popSubScreen,
      onTrackTap: _handlePlay,
    ),
    const UpgradeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!_bootstrapped) {
      Future.microtask(() {
        if (mounted) setState(() => _bootstrapped = true);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isLoggedIn) {
      return const WelcomeScreen();
    }

    return Scaffold(
      body: _subScreens[_selectedIndex] ?? _buildScreens()[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            track: _currentTrack,
            isPlaying: _isPlaying,
            onPlay: _toggleCurrentTrack,
            onOpenFullPlayer: _openFullPlayer,
          ),
          BottomNavBar(
            onTabSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _subScreens.remove(index);
              });
            },
          ),
        ],
      ),
    );
  }
}
