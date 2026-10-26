import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class DisciplinasScreen extends StatelessWidget {
  final bool isProfessor;
  final String? alunoUid; // ID passado quando aberta pelo responsável ou professor
  final String? alunoNome;

  const DisciplinasScreen({
    super.key,
    this.isProfessor = false,
    this.alunoUid,
    this.alunoNome,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    // Usa o alunoUid do filho (se for responsável) ou o UID logado (se for o próprio aluno)
    final String targetUid = alunoUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final String titulo = alunoNome != null ? 'Disciplinas - $alunoNome' : 'Minhas Disciplinas';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getDisciplinas(targetUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma disciplina encontrada.'));
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
              String categoria = data['categoria'] ?? data['materia'] ?? 'GERAL';

              double progresso = (faltas / maxFaltas).clamp(0.0, 1.0);

              // Definição visual dos alertas e da barra de progresso
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
                      // Categoria (Ex: ENGENHARIA DE SOFTWARE, EXATAS)
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

                      // Nome da Disciplina e Professor
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

                      // Status (Alerta / Frequência Regular / Reprovado)
                      if (reprovado)
                        _buildStatusBadge('EXCEDEU O LIMITE DE FALTAS', Colors.red)
                      else if (pertoDoLimite)
                        _buildStatusBadge('⚠️ ALERTA: Perto do limite!', Colors.orange)
                      else
                        _buildStatusBadge('✓ Frequência Regular', Colors.green),

                      const SizedBox(height: 12),

                      // Contador de Faltas
                      Text(
                        'Faltas: $faltas / $maxFaltas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: corBarra,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Barra de Progresso Visual
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
}
