import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginFormState {
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.submitting = false,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool submitting;
  final String? errorMessage;

  bool get isValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) && password.length >= 8;

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? submitting,
    String? errorMessage,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage,
    );
  }
}

class LoginFormController extends StateNotifier<LoginFormState> {
  LoginFormController() : super(const LoginFormState());

  void setEmail(String value) {
    state = state.copyWith(email: value.trim(), errorMessage: null);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, errorMessage: null);
  }

  void setSubmitting(bool submitting) {
    state = state.copyWith(submitting: submitting);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }
}

// M-3 FIX: autoDispose clears credentials from memory when the login screen
// is popped, preventing sensitive form state from living indefinitely in the
// Riverpod container while the user navigates the rest of the app.
final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormController, LoginFormState>(
  (ref) => LoginFormController(),
);




