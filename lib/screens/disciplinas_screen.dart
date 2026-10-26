import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class DisciplinasScreen extends StatelessWidget {
  final bool isProfessor;
  final String? alunoUid;

  const DisciplinasScreen({
    super.key,
    this.isProfessor = false,
    this.alunoUid,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    final String targetUid =
        alunoUid ?? (!isProfessor ? FirebaseAuth.instance.currentUser?.uid ?? '' : '');

    return Scaffold(
      appBar: AppBar(
        title: Text(isProfessor ? 'Cadastrar & Gerenciar Disciplinas' : 'Minhas Disciplinas'),
        backgroundColor: isProfessor ? Colors.indigo : Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: targetUid.isEmpty && isProfessor
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.indigo),
              SizedBox(height: 16),
              Text(
                'Gestão de Disciplinas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Clique no botão "+ Nova Disciplina" abaixo para selecionar um aluno e vincular uma nova matéria a ele.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getDisciplinas(targetUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma disciplina cadastrada para este aluno.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              int faltas = data['faltas'] ?? 0;
              int maxFaltas = data['maxFaltas'] ?? 20;
              String nome = data['nome'] ?? 'Disciplina';
              String professor = data['professor'] ?? 'Professor não informado';
              String categoria = data['categoria'] ?? 'GERAL';

              double progresso = (faltas / maxFaltas).clamp(0.0, 1.0);

              bool pertoDoLimite = faltas >= (maxFaltas * 0.75) && faltas < maxFaltas;
              bool reprovado = faltas >= maxFaltas;

              Color corBarra = Colors.green;
              if (reprovado) {
                corBarra = Colors.red;
              } else if (pertoDoLimite) {
                corBarra = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: reprovado ? Colors.red.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoria.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Prof: $professor',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      if (reprovado)
                        _buildStatusBadge('EXCEDEU O LIMITE DE FALTAS', Colors.red)
                      else if (pertoDoLimite)
                        _buildStatusBadge('⚠️ ALERTA: Perto do limite!', Colors.orange)
                      else
                        _buildStatusBadge('✓ Frequência Regular', Colors.green),
                      const SizedBox(height: 12),
                      Text(
                        'Faltas: $faltas / $maxFaltas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: corBarra,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(corBarra),
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
      floatingActionButton: isProfessor
          ? FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Disciplina'),
        onPressed: () => _abrirModalAdicionarDisciplina(context, firestoreService),
      )
          : null,
    );
  }

  Widget _buildStatusBadge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _abrirModalAdicionarDisciplina(BuildContext context, FirestoreService service) {
    String? alunoSelecionado = alunoUid;
    final nomeController = TextEditingController();
    final professorController = TextEditingController();
    final categoriaController = TextEditingController(text: 'Exatas');
    final maxFaltasController = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadastrar Nova Disciplina'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alunoUid == null) ...[
                StreamBuilder<QuerySnapshot>(
                  stream: service.getAlunos(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    var docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Text(
                        'Nenhum aluno cadastrado no sistema.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Selecione o Aluno',
                        border: OutlineInputBorder(),
                      ),
                      items: docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(data['nome'] ?? 'Aluno sem nome'),
                        );
                      }).toList(),
                      onChanged: (val) => alunoSelecionado = val,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Disciplina (ex: Matemática)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: professorController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Professor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoria (ex: Exatas, Humanas, Biológicas)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxFaltasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limite Máximo de Faltas',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (alunoSelecionado == null || alunoSelecionado!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, selecione um aluno na lista.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (nomeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe o nome da disciplina.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(alunoSelecionado)
                  .collection('disciplinas')
                  .add({
                'nome': nomeController.text.trim(),
                'professor': professorController.text.trim(),
                'categoria': categoriaController.text.trim(),
                'faltas': 0,
                'maxFaltas': int.tryParse(maxFaltasController.text) ?? 20,
                'criadoEm': FieldValue.serverTimestamp(),
              });

              if (context.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Disciplina cadastrada com sucesso para o aluno!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }
}