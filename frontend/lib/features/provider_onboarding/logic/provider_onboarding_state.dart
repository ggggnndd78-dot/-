import 'package:equatable/equatable.dart';

class ProviderOnboardingState extends Equatable {
  final bool loading;
  final String? organizationType;
  final String? organizationId;
  final String? verificationRequestId;
  final String? errorMessage;

  const ProviderOnboardingState({
    this.loading = false,
    this.organizationType,
    this.organizationId,
    this.verificationRequestId,
    this.errorMessage,
  });

  ProviderOnboardingState copyWith({
    bool? loading,
    String? organizationType,
    String? organizationId,
    String? verificationRequestId,
    String? errorMessage,
  }) {
    return ProviderOnboardingState(
      loading: loading ?? this.loading,
      organizationType: organizationType ?? this.organizationType,
      organizationId: organizationId ?? this.organizationId,
      verificationRequestId:
          verificationRequestId ?? this.verificationRequestId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        organizationType,
        organizationId,
        verificationRequestId,
        errorMessage
      ];
}
