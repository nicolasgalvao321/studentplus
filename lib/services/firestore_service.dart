import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    return _db
        .collection('users')
        .where('role', isEqualTo: 'aluno')
        .snapshots();
  }

  Future<DocumentSnapshot> getAlunoVinculado(String responsavelUid) async {
    DocumentSnapshot respDoc = await _db
        .collection('users')
        .doc(responsavelUid)
        .get();
    String alunoId = respDoc.get('alunoId') ?? '';
    return await _db.collection('users').doc(alunoId).get();
  }

  // ==========================================
  // 2. DISCIPLINAS E FALTAS
  // ==========================================

  Stream<QuerySnapshot> getDisciplinas(String alunoUid) {
    return _db
        .collection('users')
        .doc(alunoUid)
        .collection('disciplinas')
        .snapshots();
  }

  Future<void> addDisciplina(String alunoUid, String nome,
      String professor) async {
    await _db.collection('users').doc(alunoUid).collection('disciplinas').add({
      'nome': nome,
      'professor': professor,
      'faltas': 0,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarFaltas(String alunoUid, String disciplinaId,
      int novasFaltas) async {
    await _db
        .collection('users')
        .doc(alunoUid)
        .collection('disciplinas')
        .doc(disciplinaId)
        .update({'faltas': novasFaltas});
  }

  // ==========================================
  // 3. TAREFAS DOS ALUNOS
  // ==========================================

  Stream<QuerySnapshot> getTarefas(String alunoUid) {
    return _db
        .collection('users')
        .doc(alunoUid)
        .collection('tarefas')
        .orderBy('dataEntrega')
        .snapshots();
  }

  Future<void> addTarefa(String alunoUid, String titulo, String disciplina,
      String dataEntrega) async {
    await _db.collection('users').doc(alunoUid).collection('tarefas').add({
      'titulo': titulo,
      'disciplina': disciplina,
      'dataEntrega': dataEntrega,
      'concluida': false,
    });
  }

  Future<void> toggleTarefaStatus(String alunoUid, String tarefaId,
      bool statusAtual) async {
    await _db
        .collection('users')
        .doc(alunoUid)
        .collection('tarefas')
        .doc(tarefaId)
        .update({'concluida': !statusAtual});
  }

  // ==========================================
  // 4. RECADOS E COMUNICADOS
  // ==========================================

  Stream<QuerySnapshot> getRecados() {
    return _db
        .collection('recados')
        .orderBy('data', descending: true)
        .snapshots();
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
      'linkAnexo': linkAnexo ?? '',
      'destino': destino,
      'confirmacoes': [],
      'data': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmarLeituraRecado(String recadoId,
      String responsavelUid) async {
    await _db.collection('recados').doc(recadoId).update({
      'confirmacoes': FieldValue.arrayUnion([responsavelUid])
    });
  }

  // ==========================================
  // 5. JUSTIFICATIVAS E FINANCEIRO DINÂMICO
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

  // Inicializa mensalidades de demonstração para 2026, 2027 e 2028 caso não existam no banco
  Future<void> inicializarMensalidadesExemplo(String alunoId) async {
    var snapshot = await _db
        .collection('mensalidades')
        .where('alunoId', isEqualTo: alunoId)
        .get();

    if (snapshot.docs.isEmpty) {
      List<Map<String, dynamic>> mensalidadesDemo = [
        // --- 2026 ---
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Outubro',
          'valor': 450.0,
          'vencimento': '10/10/2026',
          'ano': 2026,
          'status': 'pago'
        },
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Novembro',
          'valor': 450.0,
          'vencimento': '10/11/2026',
          'ano': 2026,
          'status': 'pendente'
        },
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Dezembro',
          'valor': 450.0,
          'vencimento': '10/12/2026',
          'ano': 2026,
          'status': 'a vencer'
        },
        // --- 2027 ---
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Janeiro',
          'valor': 480.0,
          'vencimento': '10/01/2027',
          'ano': 2027,
          'status': 'a vencer'
        },
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Fevereiro',
          'valor': 480.0,
          'vencimento': '10/02/2027',
          'ano': 2027,
          'status': 'a vencer'
        },
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Março',
          'valor': 480.0,
          'vencimento': '10/03/2027',
          'ano': 2027,
          'status': 'a vencer'
        },
        // --- 2028 ---
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Janeiro',
          'valor': 500.0,
          'vencimento': '10/01/2028',
          'ano': 2028,
          'status': 'a vencer'
        },
        {
          'alunoId': alunoId,
          'titulo': 'Mensalidade - Fevereiro',
          'valor': 500.0,
          'vencimento': '10/02/2028',
          'ano': 2028,
          'status': 'a vencer'
        },
      ];

      for (var item in mensalidadesDemo) {
        await _db.collection('mensalidades').add(item);
      }
    }
  }

  // Buscar mensalidades do aluno
  Stream<QuerySnapshot> getMensalidadesDoAluno(String alunoId) {
    return _db
        .collection('mensalidades')
        .where('alunoId', isEqualTo: alunoId)
        .snapshots();
  }

  // Simular Pagamento: Muda o status no Firestore para 'pago'
  Future<void> simularPagamentoMensalidade(String mensalidadeId) async {
    await _db.collection('mensalidades').doc(mensalidadeId).update({
      'status': 'pago',
      'pagoEm': FieldValue.serverTimestamp(),
    });
  }

  // Stream de todas as mensalidades para a Secretaria/Staff
  Stream<QuerySnapshot> getTodasMensalidades() {
    return _db.collection('mensalidades').snapshots();
  }

  // Criar/Enviar novo boleto pela Secretaria
  Future<void> gerarBoleto({
    required String alunoId,
    required String alunoNome,
    required String titulo,
    required double valor,
    required String vencimento,
    required int ano,
  }) async {
    await _db.collection('mensalidades').add({
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'titulo': titulo,
      'valor': valor,
      'vencimento': vencimento,
      'ano': ano,
      'status': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
    });
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

  Future<void> atualizarStatusJustificativa(String docId,
      String novoStatus) async {
    await _db.collection('justificativas').doc(docId).update({
      'status': novoStatus,
      'analisadoEm': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // 7. CANTINA E ESCALA DE LIMPEZA
  // ==========================================

  // Buscar itens do cardápio da cantina
  Stream<QuerySnapshot> getCardapioCantina() {
    return _db
        .collection('cantina')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  // Adicionar novo lanche (Somente Staff / Funcionários)
  Future<void> addLancheCantina(String nome, double preco) async {
    await _db.collection('cantina').add({
      'nome': nome,
      'preco': preco,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Deletar lanche da cantina
  Future<void> deletarLancheCantina(String docId) async {
    await _db.collection('cantina').doc(docId).delete();
  }

  // ==========================================
  // 8. CHAT / MENSAGENS EM TEMPO REAL
  // ==========================================

  // Buscar todas as conversas do usuário atual sem exigir índice composto
  Stream<QuerySnapshot> getMinhasConversas(String meuUid) {
    return _db
        .collection('chats')
        .where('participantes', arrayContains: meuUid)
        .snapshots();
  }

  // Buscar ou criar o ID de uma conversa entre dois usuários
  Future<String> obterOuCriarChat({
    required String meuUid,
    required String meuNome,
    required String outroUid,
    required String outroNome,
  }) async {
    // Procura se já existe um chat entre os dois
    var query = await _db
        .collection('chats')
        .where('participantes', arrayContains: meuUid)
        .get();

    for (var doc in query.docs) {
      List participantes = doc.get('participantes') ?? [];
      if (participantes.contains(outroUid)) {
        return doc.id;
      }
    }

    // Se não existir, cria uma nova conversa
    var novochat = await _db.collection('chats').add({
      'participantes': [meuUid, outroUid],
      'nomes': {
        meuUid: meuNome,
        outroUid: outroNome,
      },
      'ultimaMensagem': 'Conversa iniciada',
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    return novochat.id;
  }

  // Buscar mensagens de um chat específico em tempo real
  Stream<QuerySnapshot> getMensagensChat(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('mensagens')
        .orderBy('enviadoEm', descending: true)
        .snapshots();
  }

  // Enviar uma nova mensagem
  Future<void> enviarMensagem({
    required String chatId,
    required String remetenteUid,
    required String texto,
  }) async {
    if (texto.trim().isEmpty) return;

    // 1. Salva a mensagem na subcoleção
    await _db.collection('chats').doc(chatId).collection('mensagens').add({
      'remetenteUid': remetenteUid,
      'texto': texto.trim(),
      'enviadoEm': FieldValue.serverTimestamp(),
    });

    // 2. Atualiza o resumo da última mensagem na conversa
    await _db.collection('chats').doc(chatId).update({
      'ultimaMensagem': texto.trim(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Buscar lista de contatos disponíveis para conversar (Professores, Pais, Staff e Alunos)
  Stream<QuerySnapshot> getContatosDisponiveis() {
    return _db.collection('users').snapshots();
  }
}
