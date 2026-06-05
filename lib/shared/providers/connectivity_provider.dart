import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams real-time connectivity status.
/// true = online, false = offline.
///
/// connectivity_plus 5.0.2:
///   checkConnectivity()    → Future<ConnectivityResult>
///   onConnectivityChanged  → Stream<ConnectivityResult>
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Emit initial state immediately
  final initial = await connectivity.checkConnectivity();
  yield _isOnline(initial);

  // Stream ongoing changes
  yield* connectivity.onConnectivityChanged.map(_isOnline);
});

bool _isOnline(ConnectivityResult result) =>
    result == ConnectivityResult.mobile ||
    result == ConnectivityResult.wifi ||
    result == ConnectivityResult.ethernet;
