import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class GestaoFaltasScreen extends StatefulWidget {
  final String? alunoUid;
  final bool isProfessor;

  const GestaoFaltasScreen({
    super.key,
    this.alunoUid,
    this.isProfessor = true,
  });

  @override
  State<GestaoFaltasScreen> createState() => _GestaoFaltasScreenState();
}

class _GestaoFaltasScreenState extends State<GestaoFaltasScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _alunoSelecionadoId;
  String? _alunoSelecionadoNome;

  @override
  void initState() {
    super.initState();
    if (widget.alunoUid != null && widget.alunoUid!.isNotEmpty) {
      _alunoSelecionadoId = widget.alunoUid;
      _alunoSelecionadoNome = 'Aluno';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_alunoSelecionadoNome == null
            ? 'Selecione um Aluno'
            : 'Faltas: $_alunoSelecionadoNome'),
        backgroundColor: const Color(0xFF0E3B68),
        foregroundColor: Colors.white,
      ),
      body: _alunoSelecionadoId == null
          ? _buildListaAlunos()
          : _buildListaDisciplinasAluno(_alunoSelecionadoId!),
    );
  }

  // Lista de Alunos Registados
  Widget _buildListaAlunos() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAlunos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar alunos: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nenhum aluno registado até ao momento.'),
          );
        }

        final alunos = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alunos.length,
          itemBuilder: (context, index) {
            final alunoDoc = alunos[index];
            final data = alunoDoc.data() as Map<String, dynamic>? ?? {};

            final String nome = data['nome']?.toString() ?? 'Aluno sem nome';
            final String email = data['email']?.toString() ?? '';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0E3B68),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _alunoSelecionadoId = alunoDoc.id;
                    _alunoSelecionadoNome = nome;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  // Lista de Disciplinas do Aluno Selecionado
  Widget _buildListaDisciplinasAluno(String alunoUid) {
    return Column(
      children: [
        if (widget.alunoUid == null)
          ListTile(
            tileColor: Colors.grey.shade200,
            leading: const Icon(Icons.arrow_back),
            title: const Text('Voltar para a lista de alunos'),
            onTap: () {
              setState(() {
                _alunoSelecionadoId = null;
                _alunoSelecionadoNome = null;
              });
            },
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getDisciplinas(alunoUid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Erro ao carregar disciplinas: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Este aluno ainda não possui disciplinas.'),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};

                  final String nome = data['nome']?.toString() ?? 'Disciplina';
                  final int faltas = (data['faltas'] as num?)?.toInt() ?? 0;
                  final int maxFaltas = (data['maxFaltas'] as num?)?.toInt() ?? 10;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Faltas: $faltas / $maxFaltas',
                                  style: TextStyle(
                                    color: faltas >= maxFaltas
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isProfessor)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: faltas > 0
                                      ? () {
                                    _firestoreService.atualizarFaltas(
                                      alunoUid,
                                      doc.id,
                                      faltas - 1,
                                    );
                                  }
                                      : null,
                                ),
                                Text(
                                  '$faltas',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: Colors.green),
                                  onPressed: () {
                                    _firestoreService.atualizarFaltas(
                                      alunoUid,
                                      doc.id,
                                      faltas + 1,
                                    );
                                  },
                                ),
                              ],
                            )
                          else
                            Text(
                              '$faltas',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
