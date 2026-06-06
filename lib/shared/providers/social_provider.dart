import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class MockFriend {
  final String name;
  final String status;
  final int streak;
  final int progress;
  final int ahead;
  final Color color;

  const MockFriend({
    required this.name,
    required this.status,
    required this.streak,
    required this.progress,
    required this.ahead,
    required this.color,
  });
}

class LeaderboardEntry {
  final String name;
  final int xp;
  final Color color;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.name,
    required this.xp,
    required this.color,
    this.isCurrentUser = false,
  });
}

class SocialState {
  final List<MockFriend> friends;
  final List<MockFriend> pendingRequests;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;

  const SocialState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.leaderboard = const [],
    this.isLoading = false,
  });

  SocialState copyWith({
    List<MockFriend>? friends,
    List<MockFriend>? pendingRequests,
    List<LeaderboardEntry>? leaderboard,
    bool? isLoading,
  }) =>
      SocialState(
        friends: friends ?? this.friends,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        leaderboard: leaderboard ?? this.leaderboard,
        isLoading: isLoading ?? this.isLoading,
      );
}

class SocialNotifier extends StateNotifier<SocialState> {
  SocialNotifier() : super(const SocialState());

  void init() {
    if (state.friends.isNotEmpty) return;
    state = state.copyWith(
      friends: _mockFriends,
      pendingRequests: _mockRequests,
      leaderboard: _mockLeaderboard,
    );
  }
}

final _mockFriends = const [
  MockFriend(
    name: 'Alex Kim',
    status: 'Level 12 of 30 in DSA Roadmap',
    streak: 14,
    progress: 40,
    ahead: 4,
    color: Color(0xFF6C63FF),
  ),
  MockFriend(
    name: 'Priya Sharma',
    status: 'Level 8 of 20 in System Design',
    streak: 7,
    progress: 40,
    ahead: -3,
    color: Color(0xFFFF6584),
  ),
  MockFriend(
    name: 'James Wu',
    status: 'Level 20 of 42 in Gym Plan',
    streak: 21,
    progress: 48,
    ahead: 8,
    color: Color(0xFF43E97B),
  ),
  MockFriend(
    name: 'Aisha Patel',
    status: 'No active roadmap',
    streak: 3,
    progress: 0,
    ahead: 0,
    color: Color(0xFFFFD93D),
  ),
  MockFriend(
    name: 'Marco Rossi',
    status: 'Level 5 of 30 in DSA Roadmap',
    streak: 5,
    progress: 17,
    ahead: -3,
    color: Color(0xFF38F9D7),
  ),
];

final _mockRequests = const [
  MockFriend(
    name: 'Sofia Chen',
    status: 'Wants to connect',
    streak: 0,
    progress: 0,
    ahead: 0,
    color: Color(0xFFFF8C00),
  ),
];

final _mockLeaderboard = const [
  LeaderboardEntry(name: 'James Wu', xp: 8400, color: Color(0xFF43E97B)),
  LeaderboardEntry(name: 'Alex Kim', xp: 6200, color: Color(0xFF6C63FF)),
  LeaderboardEntry(name: 'Priya Sharma', xp: 4100, color: Color(0xFFFF6584)),
  LeaderboardEntry(
      name: 'You', xp: 2450, color: Color(0xFF6C63FF), isCurrentUser: true),
  LeaderboardEntry(name: 'Marco Rossi', xp: 1800, color: Color(0xFF38F9D7)),
  LeaderboardEntry(name: 'Aisha Patel', xp: 900, color: Color(0xFFFFD93D)),
  LeaderboardEntry(name: 'Sofia Chen', xp: 450, color: Color(0xFFFF8C00)),
];

final socialProvider =
    StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  return SocialNotifier();
});
