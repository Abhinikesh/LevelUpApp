import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';

class MockFriend {
  final String? id;
  final String name;
  final String status;
  final int streak;
  final int progress;
  final int ahead;
  final Color color;

  const MockFriend({
    this.id,
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
  final String? error;

  const SocialState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.leaderboard = const [],
    this.isLoading = false,
    this.error,
  });

  SocialState copyWith({
    List<MockFriend>? friends,
    List<MockFriend>? pendingRequests,
    List<LeaderboardEntry>? leaderboard,
    bool? isLoading,
    String? error,
  }) =>
      SocialState(
        friends: friends ?? this.friends,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        leaderboard: leaderboard ?? this.leaderboard,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class SocialNotifier extends StateNotifier<SocialState> {
  final Dio _dio;

  SocialNotifier(this._dio) : super(const SocialState());

  // Mock mode when: running against placeholder URL, still pointing at the
  // old 'your-backend.com' placeholder, or the server is unreachable.
  // We keep it simple — real mode is used by default unless overridden.
  bool get _isMockMode => false;

  void init() {
    fetchSocialData();
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return const Color(0xFF6C63FF);
    final hash = name.codeUnits.reduce((a, b) => a + b);
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6584),
      const Color(0xFF43E97B),
      const Color(0xFFFFD93D),
      const Color(0xFF38F9D7),
      const Color(0xFFFF8C00),
    ];
    return colors[hash % colors.length];
  }

  Future<void> fetchSocialData({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    if (_isMockMode) {
      if (state.friends.isEmpty || forceRefresh) {
        state = state.copyWith(isLoading: true, error: null);
        await Future.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(
          friends: _mockFriends,
          pendingRequests: _mockRequests,
          leaderboard: _mockLeaderboard,
          isLoading: false,
        );
      }
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Fetch friends & requests
      final friendsRes = await _dio.get(ApiConstants.friends);
      final friendsData = friendsRes.data;

      List<MockFriend> friendsList = [];
      List<MockFriend> pendingList = [];

      if (friendsData is Map<String, dynamic> && friendsData['success'] == true) {
        final List<dynamic> fList = friendsData['friends'] ?? [];
        final List<dynamic> pList = friendsData['pendingRequests'] ?? [];

        friendsList = fList.map((f) {
          final activeRm = f['activeRoadmap'];
          final statusStr = activeRm != null
              ? 'Level ${activeRm['currentLevel']} of ${activeRm['totalLevels']} in ${activeRm['title']}'
              : 'No active roadmap';
          return MockFriend(
            id: f['_id'] as String?,
            name: f['name'] ?? '',
            status: statusStr,
            streak: (f['streakCount'] as num?)?.toInt() ?? 0,
            progress: (activeRm?['progress'] as num?)?.toInt() ?? 0,
            ahead: (f['relativeProgress'] as num?)?.toInt() ?? 0,
            color: _getColorFromName(f['name'] ?? ''),
          );
        }).toList();

        pendingList = pList.map((p) {
          return MockFriend(
            id: p['_id'] as String?,
            name: p['name'] ?? '',
            status: 'Wants to connect',
            streak: 0,
            progress: 0,
            ahead: 0,
            color: _getColorFromName(p['name'] ?? ''),
          );
        }).toList();
      }

      // 2. Fetch leaderboard
      final lbRes = await _dio.get(ApiConstants.leaderboard);
      final lbData = lbRes.data;
      List<LeaderboardEntry> lbList = [];

      if (lbData is Map<String, dynamic> && lbData['success'] == true) {
        final List<dynamic> list = lbData['leaderboard'] ?? [];
        lbList = list.map((l) {
          return LeaderboardEntry(
            name: l['name'] ?? '',
            xp: (l['xpTotal'] as num?)?.toInt() ?? 0,
            color: _getColorFromName(l['name'] ?? ''),
            isCurrentUser: l['isCurrentUser'] as bool? ?? false,
          );
        }).toList();
      }

      state = state.copyWith(
        friends: friendsList,
        pendingRequests: pendingList,
        leaderboard: lbList,
        isLoading: false,
      );
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load social data');
    }
  }

  Future<bool> sendFriendInvite(String email) async {
    if (_isMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    try {
      final res = await _dio.post(ApiConstants.addFriend, data: {'email': email});
      if (res.statusCode == 200) {
        fetchSocialData(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SocialNotifier] sendFriendInvite failed: $e');
      return false;
    }
  }

  Future<bool> acceptRequest(String userId) async {
    if (_isMockMode) {
      state = state.copyWith(
        pendingRequests: state.pendingRequests.where((f) => f.id != userId).toList(),
      );
      return true;
    }

    try {
      final res = await _dio.put(ApiConstants.acceptFriendRequest(userId));
      if (res.statusCode == 200) {
        fetchSocialData(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SocialNotifier] acceptRequest failed: $e');
      return false;
    }
  }

  Future<bool> declineRequest(String userId) async {
    if (_isMockMode) {
      state = state.copyWith(
        pendingRequests: state.pendingRequests.where((f) => f.id != userId).toList(),
      );
      return true;
    }

    try {
      final res = await _dio.delete(ApiConstants.removeFriend(userId));
      if (res.statusCode == 200) {
        fetchSocialData(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SocialNotifier] declineRequest failed: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final _mockFriends = const [
  MockFriend(
    id: 'mock-f1',
    name: 'Alex Kim',
    status: 'Level 12 of 30 in DSA Roadmap',
    streak: 14,
    progress: 40,
    ahead: 4,
    color: Color(0xFF6C63FF),
  ),
  MockFriend(
    id: 'mock-f2',
    name: 'Priya Sharma',
    status: 'Level 8 of 20 in System Design',
    streak: 7,
    progress: 40,
    ahead: -3,
    color: Color(0xFFFF6584),
  ),
  MockFriend(
    id: 'mock-f3',
    name: 'James Wu',
    status: 'Level 20 of 42 in Gym Plan',
    streak: 21,
    progress: 48,
    ahead: 8,
    color: Color(0xFF43E97B),
  ),
  MockFriend(
    id: 'mock-f4',
    name: 'Aisha Patel',
    status: 'No active roadmap',
    streak: 3,
    progress: 0,
    ahead: 0,
    color: Color(0xFFFFD93D),
  ),
  MockFriend(
    id: 'mock-f5',
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
    id: 'mock-r1',
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
  return SocialNotifier(DioClient.instance);
});
