import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'gestao_recados_screen.dart';

class FuncionarioHomeScreen extends StatefulWidget {
  const FuncionarioHomeScreen({super.key});

  @override
  State<FuncionarioHomeScreen> createState() => _FuncionarioHomeScreenState();
}

class _FuncionarioHomeScreenState extends State<FuncionarioHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da Secretaria / Staff'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                nav.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              color: Colors.purple.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.admin_panel_settings, size: 32, color: Colors.white),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Módulo Administrativo', style: TextStyle(fontSize: 12, color: Colors.purple)),
                          Text('Secretaria e Coordenação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Ações de Gestão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildCardMenu(
                  context,
                  titulo: 'Aprovar Atestados',
                  subtitulo: 'Justificativas de faltas',
                  icone: Icons.fact_check,
                  cor: Colors.teal,
                  onTap: () => _abrirModalJustificativas(context),
                ),
                _buildCardMenu(
                  context,
                  titulo: 'Publicar Recado',
                  subtitulo: 'Avisos gerais e turmas',
                  icone: Icons.campaign,
                  cor: Colors.amber.shade900,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GestaoRecadosScreen(isProfessor: true),
                      ),
                    );
                  },
                ),
                _buildCardMenu(
                  context,
                  titulo: 'Consulta de IDs',
                  subtitulo: 'IDs dos alunos p/ pais',
                  icone: Icons.badge,
                  cor: Colors.blue,
                  onTap: () => _abrirModalAlunosIDs(context),
                ),
                _buildCardMenu(
                  context,
                  titulo: 'Balanço Financeiro',
                  subtitulo: 'Resumo das mensalidades',
                  icone: Icons.monetization_on,
                  cor: Colors.green.shade700,
                  onTap: () => _abrirModalResumoFinanceiro(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardMenu(
      BuildContext context, {
        required String titulo,
        required String subtitulo,
        required IconData icone,
        required Color cor,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(backgroundColor: cor.withOpacity(0.15), child: Icon(icone, color: cor)),
              const SizedBox(height: 8),
              Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirModalJustificativas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atestados e Justificativas Pendentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getJustificativasPendentes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('Nenhuma justificativa pendente.'));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String status = data['status'] ?? 'pendente';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ExpansionTile(
                          leading: Icon(
                            status == 'aprovado'
                                ? Icons.check_circle
                                : (status == 'rejeitado' ? Icons.cancel : Icons.hourglass_top),
                            color: status == 'aprovado'
                                ? Colors.green
                                : (status == 'rejeitado' ? Colors.red : Colors.orange),
                          ),
                          title: Text('Disciplina: ${data['disciplina'] ?? 'Geral'}'),
                          subtitle: Text('Data: ${data['dataFalta'] ?? ''} • Status: ${status.toUpperCase()}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Motivo: ${data['motivo'] ?? ''}', style: const TextStyle(fontSize: 13)),
                                  if ((data['comprovanteUrl'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Link do Anexo: ${data['comprovanteUrl']}', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                                  ],
                                  const SizedBox(height: 12),
                                  if (status == 'pendente')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                          onPressed: () async {
                                            final nav = Navigator.of(ctx);
                                            await _firestoreService.atualizarStatusJustificativa(docs[index].id, 'rejeitado');
                                            nav.pop();
                                          },
                                          child: const Text('Rejeitar'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                          onPressed: () async {
                                            final nav = Navigator.of(ctx);
                                            await _firestoreService.atualizarStatusJustificativa(docs[index].id, 'aprovado');
                                            nav.pop();
                                          },
                                          child: const Text('Aprovar'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  void _abrirModalAlunosIDs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Consulta de IDs de Alunos Cadastrados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Forneça este ID aos pais caso precisem realizar o vínculo no cadastro.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getAlunos(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('Nenhum aluno cadastrado no momento.'));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(data['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: SelectableText('ID: ${docs[index].id}'),
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

  void _abrirModalResumoFinanceiro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Balanço Geral de Mensalidades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLinhaFinanceira('Total Recebido (Mês Atual)', 'R\$ 42.750,00', Colors.green),
            _buildLinhaFinanceira('Pendente / Em Aberto', 'R\$ 4.050,00', Colors.orange),
            _buildLinhaFinanceira('Inadimplência Global', '8.6%', Colors.red),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar Relatório'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaFinanceira(String rotulo, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: const TextStyle(fontSize: 14)),
          Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor)),
        ],
      ),
    );
  }
}
