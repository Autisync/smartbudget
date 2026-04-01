import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupFormState {
  const SignupFormState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.submitting = false,
    this.errorMessage,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final bool submitting;
  final String? errorMessage;

  bool get passwordStrong =>
      password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password);

  bool get isValid =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) &&
      passwordStrong &&
      password == confirmPassword;

  SignupFormState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? confirmPassword,
    bool? submitting,
    String? errorMessage,
  }) {
    return SignupFormState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage,
    );
  }
}

class SignupFormController extends StateNotifier<SignupFormState> {
  SignupFormController() : super(const SignupFormState());

  void setFirstName(String value) {
    state = state.copyWith(firstName: value.trim(), errorMessage: null);
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value.trim(), errorMessage: null);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim(), errorMessage: null);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, errorMessage: null);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, errorMessage: null);
  }

  void setSubmitting(bool submitting) {
    state = state.copyWith(submitting: submitting);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }
}

final signupFormProvider = StateNotifierProvider<SignupFormController, SignupFormState>((ref) {
  return SignupFormController();
});
