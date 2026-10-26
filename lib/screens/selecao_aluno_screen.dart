import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'disciplinas_screen.dart';
import 'tarefas_screen.dart';

enum TipoSelecao { disciplinas, tarefas }

class SelecaoAlunoScreen extends StatelessWidget {
  final TipoSelecao tipoSelecao;

  const SelecaoAlunoScreen({super.key, required this.tipoSelecao});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Selecione um Aluno'),
        backgroundColor: const Color(0xFF0E3B68),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getAlunos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum aluno cadastrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String nome = data['nome'] ?? 'Aluno sem nome';
              final String email = data['email'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0E3B68),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: email.isNotEmpty ? Text(email) : null,
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    if (tipoSelecao == TipoSelecao.disciplinas) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisciplinasScreen(
                            isProfessor: true,
                            alunoUid: doc.id,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TarefasScreen(
                            isProfessor: true,
                            alunoUid: doc.id,
                            alunoNome: nome,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
