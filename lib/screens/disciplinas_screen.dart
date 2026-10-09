import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class DisciplinasScreen extends StatefulWidget {
  final bool isProfessor;
  final String? alunoUid;
  final String? alunoNome;

  const DisciplinasScreen({
    super.key,
    this.isProfessor = false,
    this.alunoUid,
    this.alunoNome,
  });

  @override
  State<DisciplinasScreen> createState() => _DisciplinasScreenState();
}

class _DisciplinasScreenState extends State<DisciplinasScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _materiaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _professorController = TextEditingController();
  final TextEditingController _maxFaltasController = TextEditingController();

  void _mostrarDialogNovaDisciplina() {
    _materiaController.clear();
    _nomeController.clear();
    _professorController.clear();
    _maxFaltasController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nova Disciplina (${widget.alunoNome ?? 'Aluno'})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _materiaController,
                decoration: const InputDecoration(
                  labelText: 'Matéria / Área (ex: Exatas, Programação)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Disciplina (ex: Cálculo I, Java)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _professorController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Professor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxFaltasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limite Máximo de Faltas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add_task),
                label: const Text('Cadastrar Disciplina'),
                onPressed: () async {
                  final materia = _materiaController.text.trim();
                  final nome = _nomeController.text.trim();
                  final prof = _professorController.text.trim();
                  final maxFaltas =
                      int.tryParse(_maxFaltasController.text.trim()) ?? 10;

                  if (nome.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insira o nome da disciplina.')),
                    );
                    return;
                  }

                  await _firestoreService.adicionarDisciplina(
                    uid: widget.alunoUid,
                    materia: materia.isEmpty ? 'Geral' : materia,
                    nome: nome,
                    professor: prof,
                    maxFaltas: maxFaltas,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Disciplina cadastrada!')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String titulo = widget.alunoNome != null
        ? 'Disciplinas - ${widget.alunoNome}'
        : 'Minhas Disciplinas';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getDisciplinas(widget.alunoUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma disciplina registada para este aluno.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String materia = data['materia'] ?? 'Geral';
              final String nome = data['nome'] ?? 'Sem Nome';
              final String prof = data['professor'] ?? 'Não informado';
              final int faltas = data['faltas'] ?? 0;
              final int maxFaltas = data['maxFaltas'] ?? 10;

              final double percentualFaltas =
              (maxFaltas > 0) ? (faltas / maxFaltas) : 0.0;
              final bool estourou = faltas >= maxFaltas;
              final bool pertoDoLimite =
                  !estourou && (maxFaltas > 0) && (percentualFaltas >= 0.75);

              Color statusColor = Colors.green;
              String statusText = 'Frequência Regular';
              IconData statusIcon = Icons.check_circle_outline;

              if (estourou) {
                statusColor = Colors.red;
                statusText = 'LIMITE EXCEDIDO!';
                statusIcon = Icons.cancel;
              } else if (pertoDoLimite) {
                statusColor = Colors.orange.shade800;
                statusText = 'ALERTA: Perto do limite!';
                statusIcon = Icons.warning_amber_rounded;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: statusColor.withOpacity(0.5),
                    width: estourou || pertoDoLimite ? 1.5 : 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              materia.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          if (widget.isProfessor)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () async {
                                await _firestoreService.deletarDisciplina(
                                    doc.id, widget.alunoUid);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Prof: $prof',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Faltas: $faltas / $maxFaltas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentualFaltas.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          color: statusColor,
                          minHeight: 8,
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
      floatingActionButton: widget.isProfessor
          ? FloatingActionButton(
        onPressed: _mostrarDialogNovaDisciplina,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}