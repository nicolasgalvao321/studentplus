import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  // =========================================================================
  // MÉTODOS DE DISCIPLINAS (POR ALUNO)
  // =========================================================================

  Stream<QuerySnapshot> getDisciplinas([String? uid]) {
    final userId = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    return _db
        .collection('users')
        .doc(userId)
        .collection('disciplinas')
        .snapshots();
  }

  // Atalho para consulta por UID do aluno
  Stream<QuerySnapshot> getDisciplinasDoAluno(String alunoUid) {
    return getDisciplinas(alunoUid);
  }

  Future<void> adicionarDisciplina({
    String? uid,
    required String nome,
    required String professor,
    required int maxFaltas,
    String materia = 'Geral',
    int faltas = 0,
  }) async {
    final userId = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('disciplinas')
        .add({
      'nome': nome,
      'materia': materia,
      'professor': professor,
      'faltas': faltas,
      'maxFaltas': maxFaltas,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletarDisciplina(String disciplinaId, [String? uid]) async {
    final userId = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('disciplinas')
        .doc(disciplinaId)
        .delete();
  }

  // =========================================================================
  // MÉTODOS DE TAREFAS (POR ALUNO)
  // =========================================================================

  Stream<QuerySnapshot> getTarefas([String? uid]) {
    final userId = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    return _db
        .collection('users')
        .doc(userId)
        .collection('tarefas')
        .snapshots();
  }

  Future<void> adicionarTarefa({
    String? uid,
    required String titulo,
    String? descricao,
    String? disciplina,
    dynamic dataEntrega,
    bool concluida = false,
  }) async {
    final userId = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('tarefas')
        .add({
      'titulo': titulo,
      'descricao': descricao ?? '',
      'disciplina': disciplina ?? '',
      'dataEntrega': dataEntrega,
      'concluida': concluida,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> alternarStatusTarefa(String tarefaId, bool concluida, [String? uid]) async {
    final userId = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('tarefas')
        .doc(tarefaId)
        .update({'concluida': concluida});
  }

  Future<void> deletarTarefa(String tarefaId, [String? uid]) async {
    final userId = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('tarefas')
        .doc(tarefaId)
        .delete();
  }

  // =========================================================================
  // MÉTODOS DO PROFESSOR (LISTAR ALUNOS E GESTÃO DE FALTAS)
  // =========================================================================

  Stream<QuerySnapshot> getAlunos() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'aluno')
        .snapshots();
  }

  Future<void> atualizarFaltasAluno({
    required String alunoUid,
    required String disciplinaId,
    required int novasFaltas,
  }) async {
    await _db
        .collection('users')
        .doc(alunoUid)
        .collection('disciplinas')
        .doc(disciplinaId)
        .update({'faltas': novasFaltas});
  }

  // =========================================================================
  // MURAL DE RECADOS (COM SUPORTE A LINKS / ANEXOS)
  // =========================================================================

  Stream<QuerySnapshot> getRecados() {
    return _db
        .collection('recados')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Future<void> enviarRecado({
    required String titulo,
    required String conteudo,
    required String autorNome,
    String? link,
  }) async {
    await _db.collection('recados').add({
      'titulo': titulo,
      'conteudo': conteudo,
      'autorNome': autorNome,
      'link': link ?? '',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletarRecado(String recadoId) async {
    await _db.collection('recados').doc(recadoId).delete();
  }

  // =========================================================================
  // CALENDÁRIO (PROVAS E COMPROMISSOS)
  // =========================================================================

  Stream<QuerySnapshot> getEventos() {
    return _db
        .collection('eventos')
        .orderBy('data', descending: false)
        .snapshots();
  }

  Future<void> adicionarEvento({
    required String titulo,
    required String descricao,
    required String tipo,
    required DateTime data,
    required String autorNome,
  }) async {
    await _db.collection('eventos').add({
      'titulo': titulo,
      'descricao': descricao,
      'tipo': tipo,
      'data': Timestamp.fromDate(data),
      'autorNome': autorNome,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletarEvento(String eventoId) async {
    await _db.collection('eventos').doc(eventoId).delete();
  }
}