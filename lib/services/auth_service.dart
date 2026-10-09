import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> cadastrar({
    required String email,
    required String password,
    required String nome,
    required String role,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome,
      'email': email,
      'role': role,
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'aluno';

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('role')) {
        return doc.data()!['role'] as String;
      }
    } catch (e) {
      return 'aluno';
    }
    return 'aluno';
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}