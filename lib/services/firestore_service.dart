import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ==========================================
  // 1. USUÁRIOS E PERFIS
  // ==========================================

  Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  Stream<QuerySnapshot> getAlunos() {
    return _db.collection('users').where('role', isEqualTo: 'aluno').snapshots();
  }

  Future<DocumentSnapshot> getAlunoVinculado(String responsavelUid) async {
    DocumentSnapshot respDoc = await _db.collection('users').doc(responsavelUid).get();
    String alunoId = respDoc.get('alunoId') ?? '';
    return await _db.collection('users').doc(alunoId).get();
  }

  // ==========================================
  // 2. DISCIPLINAS E FALTAS
  // ==========================================

  Stream<QuerySnapshot> getDisciplinas([String? alunoUid]) {
    final uid = (alunoUid != null && alunoUid.isNotEmpty) ? alunoUid : _currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _db.collection('users').doc(uid).collection('disciplinas').snapshots();
  }

  Stream<QuerySnapshot> getDisciplinasDoAluno(String alunoUid) {
    return getDisciplinas(alunoUid);
  }

  Future<void> addDisciplina(String alunoUid, String nome, String professor) async {
    await _db.collection('users').doc(alunoUid).collection('disciplinas').add({
      'nome': nome,
      'professor': professor,
      'materia': 'Geral',
      'faltas': 0,
      'maxFaltas': 10,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adicionarDisciplina({
    String? uid,
    required String materia,
    required String nome,
    required String professor,
    required int maxFaltas,
  }) async {
    final alunoUid = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    await _db.collection('users').doc(alunoUid).collection('disciplinas').add({
      'materia': materia,
      'nome': nome,
      'professor': professor,
      'faltas': 0,
      'maxFaltas': maxFaltas,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarFaltas(String alunoUid, String disciplinaId, int novasFaltas) async {
    await _db
        .collection('users')
        .doc(alunoUid)
        .collection('disciplinas')
        .doc(disciplinaId)
        .update({'faltas': novasFaltas});
  }

  Future<void> atualizarFaltasAluno({
    required String alunoUid,
    required String disciplinaId,
    required int novasFaltas,
  }) async {
    await atualizarFaltas(alunoUid, disciplinaId, novasFaltas);
  }

  Future<void> deletarDisciplina(String disciplinaId, [String? alunoUid]) async {
    final uid = (alunoUid != null && alunoUid.isNotEmpty) ? alunoUid : _currentUid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('disciplinas')
        .doc(disciplinaId)
        .delete();
  }

  // ==========================================
  // 3. TAREFAS DOS ALUNOS
  // ==========================================

  Stream<QuerySnapshot> getTarefas([String? alunoUid]) {
    final uid = (alunoUid != null && alunoUid.isNotEmpty) ? alunoUid : _currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('tarefas')
        .orderBy('dataEntrega')
        .snapshots();
  }

  Future<void> addTarefa(String alunoUid, String titulo, String disciplina, String dataEntrega) async {
    await _db.collection('users').doc(alunoUid).collection('tarefas').add({
      'titulo': titulo,
      'disciplina': disciplina,
      'dataEntrega': dataEntrega,
      'concluida': false,
    });
  }

  Future<void> adicionarTarefa({
    String? uid,
    required String titulo,
    String? descricao,
    required String disciplina,
    required dynamic dataEntrega,
  }) async {
    final alunoUid = (uid != null && uid.isNotEmpty) ? uid : _currentUid;
    await _db.collection('users').doc(alunoUid).collection('tarefas').add({
      'titulo': titulo,
      'descricao': descricao ?? '',
      'disciplina': disciplina,
      'dataEntrega': dataEntrega,
      'concluida': false,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleTarefaStatus(String alunoUid, String tarefaId, bool statusAtual) async {
    await _db
        .collection('users')
        .doc(alunoUid)
        .collection('tarefas')
        .doc(tarefaId)
        .update({'concluida': !statusAtual});
  }

  Future<void> alternarStatusTarefa(String tarefaId, bool statusAtual, [String? alunoUid]) async {
    final uid = (alunoUid != null && alunoUid.isNotEmpty) ? alunoUid : _currentUid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('tarefas')
        .doc(tarefaId)
        .update({'concluida': statusAtual});
  }

  Future<void> deletarTarefa(String tarefaId, [String? alunoUid]) async {
    final uid = (alunoUid != null && alunoUid.isNotEmpty) ? alunoUid : _currentUid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('tarefas')
        .doc(tarefaId)
        .delete();
  }

  // ==========================================
  // 4. RECADOS E COMUNICADOS
  // ==========================================

  Stream<QuerySnapshot> getRecados() {
    return _db.collection('recados').orderBy('data', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getRecadosParaResponsavel() {
    return _db
        .collection('recados')
        .where('destino', whereIn: ['todos', 'responsaveis'])
        .snapshots();
  }

  Future<void> addRecado({
    required String titulo,
    required String conteudo,
    required String autor,
    String? linkAnexo,
    String destino = 'todos',
  }) async {
    await _db.collection('recados').add({
      'titulo': titulo,
      'conteudo': conteudo,
      'autor': autor,
      'autorNome': autor,
      'link': linkAnexo ?? '',
      'linkAnexo': linkAnexo ?? '',
      'destino': destino,
      'confirmacoes': [],
      'data': FieldValue.serverTimestamp(),
    });
  }

  Future<void> enviarRecado({
    required String titulo,
    required String conteudo,
    required String autorNome,
    String? link,
    String destino = 'todos',
  }) async {
    await addRecado(
      titulo: titulo,
      conteudo: conteudo,
      autor: autorNome,
      linkAnexo: link,
      destino: destino,
    );
  }

  Future<void> deletarRecado(String recadoId) async {
    await _db.collection('recados').doc(recadoId).delete();
  }

  Future<void> confirmarLeituraRecado(String recadoId, String responsavelUid) async {
    await _db.collection('recados').doc(recadoId).update({
      'confirmacoes': FieldValue.arrayUnion([responsavelUid])
    });
  }

  // ==========================================
  // 5. JUSTIFICATIVAS E FINANCEIRO (PAIS)
  // ==========================================

  Future<void> enviarJustificativa({
    required String alunoId,
    required String responsavelUid,
    required String disciplina,
    required String dataFalta,
    required String motivo,
    String? linkComprovante,
  }) async {
    await _db.collection('justificativas').add({
      'alunoId': alunoId,
      'responsavelUid': responsavelUid,
      'disciplina': disciplina,
      'dataFalta': dataFalta,
      'motivo': motivo,
      'comprovanteUrl': linkComprovante ?? '',
      'status': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMensalidadesAluno(String alunoId) {
    return _db
        .collection('users')
        .doc(alunoId)
        .collection('mensalidades')
        .orderBy('vencimento')
        .snapshots();
  }

  // ==========================================
  // 6. GESTÃO E SECRETARIA (STAFF)
  // ==========================================

  Stream<QuerySnapshot> getJustificativasPendentes() {
    return _db
        .collection('justificativas')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Future<void> atualizarStatusJustificativa(String docId, String novoStatus) async {
    await _db.collection('justificativas').doc(docId).update({
      'status': novoStatus,
      'analisadoEm': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // 7. EVENTOS E CALENDÁRIO
  // ==========================================

  Stream<QuerySnapshot> getEventos() {
    return _db.collection('eventos').orderBy('data').snapshots();
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
