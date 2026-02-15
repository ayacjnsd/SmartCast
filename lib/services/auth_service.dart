import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Регистрация по email + password
  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  /// Вход по email + password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  /// Выход
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Текущий пользователь
  User? get currentUser => _auth.currentUser;
}
