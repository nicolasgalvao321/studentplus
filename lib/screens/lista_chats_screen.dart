import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chat_conversa_screen.dart';

class ListaChatsScreen extends StatelessWidget {
  final String meuUid;
  final String meuNome;

  const ListaChatsScreen({
    super.key,
    required this.meuUid,
    required this.meuNome,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens & Conversas'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getMinhasConversas(meuUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao carregar mensagens: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = List<DocumentSnapshot>.from(snapshot.data!.docs);

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Nenhuma conversa iniciada.\nClique no botão "+" verde para buscar um contato e iniciar o bate-papo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            );
          }

          // Ordenação local em memória por data
          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? tA = dataA['atualizadoEm'] as Timestamp?;
            Timestamp? tB = dataB['atualizadoEm'] as Timestamp?;

            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String chatId = docs[index].id;
              List participantes = data['participantes'] ?? [];
              Map nomes = data['nomes'] ?? {};

              String outroUid = participantes.firstWhere(
                    (id) => id != meuUid,
                orElse: () => '',
              );
              String outroNome = nomes[outroUid] ?? 'Contato';
              String ultimaMsg = data['ultimaMensagem'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF128C7E),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(outroNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    ultimaMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatConversaScreen(
                          chatId: chatId,
                          meuUid: meuUid,
                          outroNome: outroNome,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat),
        onPressed: () => _abrirModalNovoContato(context, firestoreService),
      ),
    );
  }

  void _abrirModalNovoContato(BuildContext context, FirestoreService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Iniciar Nova Conversa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Selecione uma pessoa para iniciar o bate-papo',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: service.getContatosDisponiveis(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs
                      .where((d) => d.id != meuUid)
                      .toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Nenhum outro usuário cadastrado no banco.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String outroUid = docs[index].id;
                      String outroNome = data['nome'] ?? 'Sem Nome';
                      String role = (data['role'] ?? 'aluno').toString().toUpperCase();

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.person_outline, color: Colors.white),
                        ),
                        title: Text(outroNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Perfil: $role', style: const TextStyle(fontSize: 12)),
                        onTap: () async {
                          Navigator.pop(ctx);

                          String chatId = await service.obterOuCriarChat(
                            meuUid: meuUid,
                            meuNome: meuNome,
                            outroUid: outroUid,
                            outroNome: outroNome,
                          );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatConversaScreen(
                                  chatId: chatId,
                                  meuUid: meuUid,
                                  outroNome: outroNome,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
