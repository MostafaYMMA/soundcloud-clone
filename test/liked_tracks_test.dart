/*
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/screens/library/library_screen.dart';
import 'package:my_project/screens/library/liked_tracks_screen.dart';
import 'package:my_project/widgets/mini_player.dart';
import 'package:my_project/models/track.dart';
import 'package:my_project/mock_data/mock_tracks.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

Widget wrap(Widget child) => MaterialApp(home: child);

Track get fakeTrack => MockTracks.recentlyPlayedTracks.first;

/// Scoped AppBar title finder (avoids matching tab labels)
Finder appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

Future<void> goToLibrary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tab_library')));
  await tester.pumpAndSettle();
}

Future<void> openLikedTracks(WidgetTester tester) async {
  await tester.tap(find.text('Liked Tracks'));
  await tester.pumpAndSettle();
}

// ── Fake Root ───────────────────────────────────────────────────────────────

class FakeRoot extends StatefulWidget {
  const FakeRoot();

  @override
  State<FakeRoot> createState() => _FakeRootState();
}

class _FakeRootState extends State<FakeRoot> {
  int selectedIndex = 0;
  final Map<int, Widget> subScreens = {};

  void push(Widget screen) =>
      setState(() => subScreens[selectedIndex] = screen);

  void pop() => setState(() => subScreens.remove(selectedIndex));

  Widget body() {
    if (subScreens.containsKey(selectedIndex)) {
      return subScreens[selectedIndex]!;
    }
    if (selectedIndex == 3) {
      return LibraryScreen(
        onNavigate: push,
        onBack: pop,
        onTrackTap: (_) async {},
      );
    }
    return const Text('HomeTab');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            track: fakeTrack,
            isPlaying: false,
            onPlay: () {},
            onOpenFullPlayer: () {},
          ),
          Row(
            children: [
              TextButton(
                key: const Key('tab_home'),
                onPressed: () => setState(() => selectedIndex = 0),
                child: const Text('Home'),
              ),
              TextButton(
                key: const Key('tab_library'),
                onPressed: () => setState(() => selectedIndex = 3),
                child: const Text('Library'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Navigation', () {
    testWidgets('opens LikedTracksScreen from Library', (tester) async {
      await tester.pumpWidget(wrap(const FakeRoot()));

      await goToLibrary(tester);
      await openLikedTracks(tester);

      expect(find.text('Your likes'), findsOneWidget);
      expect(appBarTitle('Library'), findsNothing);
    });

    testWidgets('back returns to LibraryScreen', (tester) async {
      await tester.pumpWidget(wrap(const FakeRoot()));

      await goToLibrary(tester);
      await openLikedTracks(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(appBarTitle('Library'), findsOneWidget);
      expect(find.text('Your likes'), findsNothing);
    });

    testWidgets('state persists when switching tabs', (tester) async {
      await tester.pumpWidget(wrap(const FakeRoot()));

      await goToLibrary(tester);
      await openLikedTracks(tester);

      await tester.tap(find.byKey(const Key('tab_home')));
      await tester.pumpAndSettle();

      expect(find.text('Your likes'), findsNothing);

      await goToLibrary(tester);

      expect(find.text('Your likes'), findsOneWidget);
    });
  });

  group('MiniPlayer', () {
    testWidgets('visible on LibraryScreen', (tester) async {
      await tester.pumpWidget(wrap(const FakeRoot()));

      await goToLibrary(tester);

      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('persists across navigation', (tester) async {
      await tester.pumpWidget(wrap(const FakeRoot()));

      await goToLibrary(tester);
      await openLikedTracks(tester);

      expect(find.byType(MiniPlayer), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.byType(MiniPlayer), findsOneWidget);
    });
  });

  group('Search', () {
    Widget screen() => wrap(LikedTracksScreen(onBack: () {}));

    testWidgets('filters by title', (tester) async {
      await tester.pumpWidget(screen());

      final title = MockTracks.recentlyPlayedTracks.first.title;

      await tester.enterText(find.byType(TextField), title);
      await tester.pumpAndSettle();

      expect(find.text(title), findsWidgets);
    });

    testWidgets('filters by artist', (tester) async {
      await tester.pumpWidget(screen());

      final artist = MockTracks.recentlyPlayedTracks.first.artist;

      await tester.enterText(find.byType(TextField), artist?.displayName ?? '');
      await tester.pumpAndSettle();

      expect(find.text(artist?.displayName ?? ''), findsWidgets);
    });

    testWidgets('no results case', (tester) async {
      await tester.pumpWidget(screen());

      await tester.enterText(find.byType(TextField), 'no_match_xyz');
      await tester.pumpAndSettle();

      for (final t in MockTracks.recentlyPlayedTracks) {
        expect(find.text(t.title), findsNothing);
      }
    });

    testWidgets('clearing restores list', (tester) async {
      await tester.pumpWidget(screen());

      final title = MockTracks.recentlyPlayedTracks.first.title;

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text(title), findsWidgets);
    });
  });

  group('Sorting', () {
    Widget screen() => wrap(LikedTracksScreen(onBack: () {}));

    Future<void> openSort(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
    }

    testWidgets('opens sort sheet', (tester) async {
      await tester.pumpWidget(screen());

      await openSort(tester);

      expect(find.text('Sort by'), findsOneWidget);
    });

    testWidgets('sort by track name', (tester) async {
      await tester.pumpWidget(screen());

      await openSort(tester);
      await tester.tap(find.text('Track Name'));
      await tester.pumpAndSettle();

      final sorted = [...MockTracks.recentlyPlayedTracks]
        ..sort((a, b) => a.title.compareTo(b.title));

      // Find at least two tracks to compare
      final titles = sorted.map((t) => t.title).toList();
      expect(titles.length, greaterThanOrEqualTo(2));

      final firstTitle = find.text(titles[0]);
      final secondTitle = find.text(titles[1]);

      expect(firstTitle, findsOneWidget);
      expect(secondTitle, findsOneWidget);

      final firstY = tester.getTopLeft(firstTitle).dy;
      final secondY = tester.getTopLeft(secondTitle).dy;

      // Check if they're in correct order or at least not reversed
      expect(firstY, lessThanOrEqualTo(secondY));
    });

    testWidgets('sort by artist', (tester) async {
      await tester.pumpWidget(screen());

      await openSort(tester);
      await tester.tap(find.text('Artist'));
      await tester.pumpAndSettle();

      final sorted = [...MockTracks.recentlyPlayedTracks]
        ..sort(
          (a, b) => (a.artist?.displayName ?? '').compareTo(
            b.artist?.displayName ?? '',
          ),
        );

      // Filter out tracks without artists or find items that exist
      final validTracks = sorted
          .where(
            (t) =>
                t.artist?.displayName != null &&
                t.artist!.displayName.isNotEmpty,
          )
          .toList();

      if (validTracks.length >= 2) {
        final firstArtist = validTracks[0].artist!.displayName;
        final secondArtist = validTracks[1].artist!.displayName;

        final firstFinder = find.text(firstArtist);
        final secondFinder = find.text(secondArtist);

        // Wait for widgets to be fully rendered
        await tester.pumpAndSettle();

        if (firstFinder.evaluate().isNotEmpty &&
            secondFinder.evaluate().isNotEmpty) {
          final firstY = tester.getTopLeft(firstFinder).dy;
          final secondY = tester.getTopLeft(secondFinder).dy;

          expect(firstY, lessThanOrEqualTo(secondY));
        } else {
          // If we can't find two distinct artist names, just verify sorting works
          expect(true, true);
        }
      } else {
        // Not enough tracks to test sorting order, test passes
        expect(true, true);
      }
    });

    testWidgets('checkmark appears on selected sort', (tester) async {
      await tester.pumpWidget(screen());

      await openSort(tester);
      await tester.tap(find.text('Track Name'));
      await tester.pumpAndSettle();

      await openSort(tester);

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/screens/library/library_screen.dart';
import 'package:my_project/screens/library/liked_tracks_screen.dart';
import 'package:my_project/widgets/mini_player.dart';
import 'package:my_project/models/track.dart';
import 'package:my_project/models/user.dart';
import 'package:my_project/models/auth_token.dart';
import 'package:my_project/providers/auth_providers.dart';
import 'package:my_project/providers/track_provider.dart';
import 'package:my_project/services/auth_service.dart';
import 'package:my_project/services/user_profile_services.dart';
import 'package:dio/dio.dart';

// ── Fake services (no network) ───────────────────────────────────────────────

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(dio: Dio());
}

class _FakeUserService extends UserService {
  _FakeUserService() : super(dio: Dio());
}

// ── Fake data ────────────────────────────────────────────────────────────────

final _fakeArtist = TrackArtist(
  userId: 'u1',
  username: 'artist_one',
  displayName: 'Artist One',
  followerCount: 0,
);

final _fakeTracks = [
  Track(
    trackId: '1',
    title: 'Alpha Track',
    streamUrl: '',
    visibility: 'public',
    processingStatus: 'ready',
    playCount: 0,
    artist: _fakeArtist,
  ),
  Track(
    trackId: '2',
    title: 'Beta Track',
    streamUrl: '',
    visibility: 'public',
    processingStatus: 'ready',
    playCount: 0,
    artist: TrackArtist(
      userId: 'u2',
      username: 'artist_two',
      displayName: 'Artist Two',
      followerCount: 0,
    ),
  ),
  Track(
    trackId: '3',
    title: 'Gamma Track',
    streamUrl: '',
    visibility: 'public',
    processingStatus: 'ready',
    playCount: 0,
    artist: _fakeArtist,
  ),
];

Track get fakeTrack => _fakeTracks.first;

// ── Provider overrides ───────────────────────────────────────────────────────

/// Injects a fake logged-in user so LikedTracksScreen gets a username.
final _fakeAuthOverride = authProvider.overrideWith((ref) {
  final notifier = AuthNotifier(_FakeAuthService(), _FakeUserService());
  // Directly set the state — AuthState and AuthTokens constructors
  // match exactly what's in auth_providers.dart and auth_token.dart.
  notifier.state = AuthState(
    tokens: AuthTokens(
      accessToken: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
    ),
    user: User(id: 'fake-id', email: 'test@test.com', userName: 'testuser'),
  );
  return notifier;
});

/// Returns fake liked tracks immediately without hitting the network.
final _fakeUserLikedTracksOverride = userLikedTracksProvider.overrideWith(
  (ref, username) async => _fakeTracks,
);

List<Override> get _overrides => [
  _fakeAuthOverride,
  _fakeUserLikedTracksOverride,
];

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget wrap(Widget child) => ProviderScope(
  overrides: _overrides,
  child: MaterialApp(home: child),
);

Widget wrappedRoot() => ProviderScope(
  overrides: _overrides,
  child: const MaterialApp(home: FakeRoot()),
);

Finder appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

Future<void> goToLibrary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tab_library')));
  await tester.pumpAndSettle();
}

Future<void> openLikedTracks(WidgetTester tester) async {
  await tester.tap(find.text('Liked Tracks'));
  await tester.pumpAndSettle();
}

// ── Fake Root ────────────────────────────────────────────────────────────────

class FakeRoot extends StatefulWidget {
  const FakeRoot({super.key});

  @override
  State<FakeRoot> createState() => _FakeRootState();
}

class _FakeRootState extends State<FakeRoot> {
  int selectedIndex = 0;
  final Map<int, Widget> subScreens = {};

  void push(Widget screen) =>
      setState(() => subScreens[selectedIndex] = screen);

  void pop() => setState(() => subScreens.remove(selectedIndex));

  Widget body() {
    if (subScreens.containsKey(selectedIndex)) {
      return subScreens[selectedIndex]!;
    }
    if (selectedIndex == 3) {
      return LibraryScreen(
        onNavigate: push,
        onBack: pop,
        onTrackTap: (_) async {},
      );
    }
    return const Text('HomeTab');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            track: fakeTrack,
            isPlaying: false,
            onPlay: () {},
            onOpenFullPlayer: () {},
          ),
          Row(
            children: [
              TextButton(
                key: const Key('tab_home'),
                onPressed: () => setState(() => selectedIndex = 0),
                child: const Text('Home'),
              ),
              TextButton(
                key: const Key('tab_library'),
                onPressed: () => setState(() => selectedIndex = 3),
                child: const Text('Library'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('Navigation', () {
    testWidgets('opens LikedTracksScreen from Library', (tester) async {
      await tester.pumpWidget(wrappedRoot());
      await goToLibrary(tester);
      await openLikedTracks(tester);

      expect(find.textContaining('Your likes'), findsOneWidget);
      expect(appBarTitle('Library'), findsNothing);
    });

    testWidgets('back returns to LibraryScreen', (tester) async {
      await tester.pumpWidget(wrappedRoot());
      await goToLibrary(tester);
      await openLikedTracks(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(appBarTitle('Library'), findsOneWidget);
      expect(find.textContaining('Your likes'), findsNothing);
    });

    testWidgets('state persists when switching tabs', (tester) async {
      await tester.pumpWidget(wrappedRoot());
      await goToLibrary(tester);
      await openLikedTracks(tester);

      await tester.tap(find.byKey(const Key('tab_home')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your likes'), findsNothing);

      await goToLibrary(tester);
      expect(find.textContaining('Your likes'), findsOneWidget);
    });
  });

  group('MiniPlayer', () {
    testWidgets('visible on LibraryScreen', (tester) async {
      await tester.pumpWidget(wrappedRoot());
      await goToLibrary(tester);

      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('persists across navigation', (tester) async {
      await tester.pumpWidget(wrappedRoot());
      await goToLibrary(tester);
      await openLikedTracks(tester);

      expect(find.byType(MiniPlayer), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.byType(MiniPlayer), findsOneWidget);
    });
  });

  group('Search', () {
    testWidgets('filters by title', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      final title = _fakeTracks.first.title;
      await tester.enterText(find.byType(TextField), title);
      await tester.pumpAndSettle();

      expect(find.text(title), findsWidgets);
    });

    testWidgets('filters by artist', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      final artistName = _fakeTracks.first.artist!.displayName;
      await tester.enterText(find.byType(TextField), artistName);
      await tester.pumpAndSettle();

      expect(find.text(artistName), findsWidgets);
    });

    testWidgets('no results case', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'no_match_xyz');
      await tester.pumpAndSettle();

      for (final t in _fakeTracks) {
        expect(find.text(t.title), findsNothing);
      }
    });

    testWidgets('clearing restores list', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      final title = _fakeTracks.first.title;

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text(title), findsWidgets);
    });
  });

  group('Sorting', () {
    Future<void> openSort(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
    }

    testWidgets('opens sort sheet', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      await openSort(tester);
      expect(find.text('Sort by'), findsOneWidget);
    });

    testWidgets('sort by track name', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      await openSort(tester);
      await tester.tap(find.text('Track Name'));
      await tester.pumpAndSettle();

      final sorted = [..._fakeTracks]
        ..sort((a, b) => a.title.compareTo(b.title));
      final titles = sorted.map((t) => t.title).toList();

      expect(titles.length, greaterThanOrEqualTo(2));

      final firstFinder = find.text(titles[0]);
      final secondFinder = find.text(titles[1]);

      expect(firstFinder, findsOneWidget);
      expect(secondFinder, findsOneWidget);

      expect(
        tester.getTopLeft(firstFinder).dy,
        lessThanOrEqualTo(tester.getTopLeft(secondFinder).dy),
      );
    });

    testWidgets('sort by artist', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      await openSort(tester);
      await tester.tap(find.text('Artist'));
      await tester.pumpAndSettle();

      final sorted = [..._fakeTracks]
        ..sort(
          (a, b) => (a.artist?.displayName ?? '').compareTo(
            b.artist?.displayName ?? '',
          ),
        );

      final valid = sorted
          .where(
            (t) =>
                t.artist?.displayName != null &&
                t.artist!.displayName.isNotEmpty,
          )
          .toList();

      if (valid.length >= 2) {
        final firstArtist = valid.first.artist!.displayName;
        final nextDifferentArtist = valid.firstWhere(
          (track) => track.artist!.displayName != firstArtist,
          orElse: () => valid.first,
        );

        if (nextDifferentArtist.artist!.displayName != firstArtist) {
          final firstFinder = find.text(firstArtist).first;
          final secondFinder = find.text(nextDifferentArtist.artist!.displayName);

          expect(firstFinder, findsOneWidget);
          expect(secondFinder, findsOneWidget);
          expect(
            tester.getTopLeft(firstFinder).dy,
            lessThan(tester.getTopLeft(secondFinder).dy),
          );
        }
      }
    });

    testWidgets('checkmark appears on selected sort', (tester) async {
      await tester.pumpWidget(wrap(LikedTracksScreen(onBack: () {})));
      await tester.pumpAndSettle();

      await openSort(tester);
      await tester.tap(find.text('Track Name'));
      await tester.pumpAndSettle();

      await openSort(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
