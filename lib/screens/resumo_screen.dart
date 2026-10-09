import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ResumoScreen extends StatefulWidget {
  const ResumoScreen({super.key});

  @override
  State<ResumoScreen> createState() => _ResumoScreenState();
}

class _ResumoScreenState extends State<ResumoScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo Acadêmico'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getTarefas(),
          builder: (context, tarefasSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getDisciplinas(),
              builder: (context, disciplinasSnap) {
                if (tarefasSnap.connectionState == ConnectionState.waiting ||
                    disciplinasSnap.connectionState ==
                        ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final tarefasDocs = tarefasSnap.data?.docs ?? [];
                final disciplinasDocs = disciplinasSnap.data?.docs ?? [];

                // 1. Cálculo do Progresso de Tarefas
                final totalTarefas = tarefasDocs.length;
                final tarefasConcluidas = tarefasDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['concluida'] == true;
                }).length;
                final pctTarefas = totalTarefas > 0
                    ? (tarefasConcluidas / totalTarefas)
                    : 1.0;

                // 2. Cálculo da Frequência Geral de Presença
                int totalFaltas = 0;
                int totalMaxFaltas = 0;
                int disciplinasCriticas = 0;

                for (var doc in disciplinasDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final int f = data['faltas'] ?? 0;
                  final int mf = data['maxFaltas'] ?? 10;
                  totalFaltas += f;
                  totalMaxFaltas += mf;

                  if (mf > 0 && (f / mf) >= 0.75) {
                    disciplinasCriticas++;
                  }
                }

                final pctPresenca = totalMaxFaltas > 0
                    ? (1.0 - (totalFaltas / totalMaxFaltas)).clamp(0.0, 1.0)
                    : 1.0;

                // 3. Progresso Geral Unificado (Média de tarefas e frequência)
                final double progressoGeral =
                ((pctTarefas * 0.5) + (pctPresenca * 0.5));
                final int percentualFinal = (progressoGeral * 100).round();

                // Definição de Status
                String statusTexto = 'Excelente Desempenho';
                Color statusCor = Colors.green;
                IconData statusIcone = Icons.stars;

                if (disciplinasCriticas > 0 || percentualFinal < 60) {
                  statusTexto = 'Atenção Necessária';
                  statusCor = Colors.orange.shade800;
                  statusIcone = Icons.warning;
                }
                if (percentualFinal < 40) {
                  statusTexto = 'Situação Crítica';
                  statusCor = Colors.red;
                  statusIcone = Icons.dangerous;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD DE PROGRESSO E STATUS GERAL DO ALUNO
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              statusCor.withOpacity(0.08),
                              Colors.purple.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(statusIcone,
                                        color: statusCor, size: 28),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusTexto,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: statusCor,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusCor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$percentualFinal%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Progresso Geral do Semestre',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progressoGeral.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.shade300,
                                color: statusCor,
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tarefas: ${(pctTarefas * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                ),
                                Text(
                                  'Presença: ${(pctPresenca * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Visão de Tarefas',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Métricas de Tarefas
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Pendentes',
                            value: '${totalTarefas - tarefasConcluidas}',
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Concluídas',
                            value: '$tarefasConcluidas',
                            icon: Icons.task_alt,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Situação de Faltas por Disciplina',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Lista de Frequência por Disciplina
                    if (disciplinasDocs.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhuma disciplina cadastrada.'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: disciplinasDocs.length,
                        itemBuilder: (context, index) {
                          final data = disciplinasDocs[index].data()
                          as Map<String, dynamic>;
                          final String nome = data['nome'] ?? 'Disciplina';
                          final int faltas = data['faltas'] ?? 0;
                          final int maxFaltas = data['maxFaltas'] ?? 10;

                          final bool estourou = faltas >= maxFaltas;
                          final bool emRisco =
                              !estourou && (faltas >= (maxFaltas * 0.75));

                          Color itemColor = Colors.green;
                          String rotulo = 'Regular';

                          if (estourou) {
                            itemColor = Colors.red;
                            rotulo = 'Reprovado por Faltas';
                          } else if (emRisco) {
                            itemColor = Colors.orange.shade800;
                            rotulo = 'Em Risco';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: itemColor.withOpacity(0.15),
                                child: Icon(
                                  estourou
                                      ? Icons.cancel
                                      : (emRisco
                                      ? Icons.warning_amber
                                      : Icons.check_circle_outline),
                                  color: itemColor,
                                ),
                              ),
                              title: Text(nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Faltas: $faltas de $maxFaltas permitidas'),
                              trailing: Text(
                                rotulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: itemColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}