import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

class HistoryModel {
  final String id;
  final String levelTitle;
  final int levelNumber;
  final int xpReward;
  final String roadmapTitle;
  final String roadmapType;
  final DateTime createdAt;

  const HistoryModel({
    required this.id,
    required this.levelTitle,
    required this.levelNumber,
    required this.xpReward,
    required this.roadmapTitle,
    required this.roadmapType,
    required this.createdAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    final lvl = json['levelId'] as Map<String, dynamic>? ?? {};
    final rm = json['roadmapId'] as Map<String, dynamic>? ?? {};
    return HistoryModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      levelTitle: lvl['title'] as String? ?? 'Level',
      levelNumber: (lvl['levelNumber'] as num?)?.toInt() ?? 0,
      xpReward: (lvl['xpReward'] as num?)?.toInt() ?? 0,
      roadmapTitle: rm['title'] as String? ?? 'Roadmap',
      roadmapType: rm['type'] as String? ?? 'custom',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ProfileHistoryState {
  final List<HistoryModel> history;
  final bool isLoading;
  final String? error;

  const ProfileHistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileHistoryState copyWith({
    List<HistoryModel>? history,
    bool? isLoading,
    String? error,
  }) {
    return ProfileHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileHistoryNotifier extends StateNotifier<ProfileHistoryState> {
  ProfileHistoryNotifier() : super(const ProfileHistoryState());

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.history);
      final data = response.data as Map<String, dynamic>;
      final list = (data['history'] as List<dynamic>? ?? [])
          .map((e) => HistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = ProfileHistoryState(history: list, isLoading: false);
    } catch (e) {
      state = ProfileHistoryState(
        history: state.history,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final profileHistoryProvider =
    StateNotifierProvider<ProfileHistoryNotifier, ProfileHistoryState>((ref) {
  return ProfileHistoryNotifier();
});
