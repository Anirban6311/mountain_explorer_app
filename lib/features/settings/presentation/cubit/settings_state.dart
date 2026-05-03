import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final int quotaMb;
  final int totalUsedBytes;
  final bool loading;
  final String? error;

  const SettingsState({
    this.quotaMb = 250,
    this.totalUsedBytes = 0,
    this.loading = true,
    this.error,
  });

  SettingsState copyWith({
    int? quotaMb,
    int? totalUsedBytes,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      quotaMb: quotaMb ?? this.quotaMb,
      totalUsedBytes: totalUsedBytes ?? this.totalUsedBytes,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [quotaMb, totalUsedBytes, loading, error];
}
