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
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
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
              childAspectRatio: 1.1,
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
                  titulo: 'Enviar Boleto',
                  subtitulo: 'Gerar cobrança p/ aluno',
                  icone: Icons.request_quote,
                  cor: Colors.indigo,
                  onTap: () => _abrirModalGerarBoleto(context),
                ),
                _buildCardMenu(
                  context,
                  titulo: 'Balanço Financeiro',
                  subtitulo: 'Receita em tempo real',
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

  void _abrirModalGerarBoleto(BuildContext context) {
    String? alunoIdSelecionado;
    String? alunoNomeSelecionado;
    final tituloController = TextEditingController(text: 'Mensalidade Escola');
    final valorController = TextEditingController(text: '450.00');
    final vencimentoController = TextEditingController(text: '10/11/2026');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Boleto / Cobrança'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getAlunos(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  var alunosDocs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Selecione o Aluno'),
                    items: alunosDocs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['nome'] ?? 'Aluno sem nome'),
                        onTap: () => alunoNomeSelecionado = data['nome'],
                      );
                    }).toList(),
                    onChanged: (val) => alunoIdSelecionado = val,
                  );
                },
              ),
              TextField(controller: tituloController, decoration: const InputDecoration(labelText: 'Descrição / Título')),
              TextField(controller: valorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor (R\$)')),
              TextField(controller: vencimentoController, decoration: const InputDecoration(labelText: 'Data de Vencimento')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              if (alunoIdSelecionado != null && valorController.text.isNotEmpty) {
                await _firestoreService.gerarBoleto(
                  alunoId: alunoIdSelecionado!,
                  alunoNome: alunoNomeSelecionado ?? 'Aluno',
                  titulo: tituloController.text,
                  valor: double.tryParse(valorController.text) ?? 0.0,
                  vencimento: vencimentoController.text,
                  ano: 2026,
                );
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Boleto enviado com sucesso para o painel dos pais!')),
                );
              }
            },
            child: const Text('Enviar Boleto'),
          ),
        ],
      ),
    );
  }

  // Balanço Financeiro em Tempo Real
  void _abrirModalResumoFinanceiro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getTodasMensalidades(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var docs = snapshot.data!.docs;
            double totalPago = 0.0;
            double totalPendente = 0.0;

            for (var doc in docs) {
              var data = doc.data() as Map<String, dynamic>;
              double val = (data['valor'] ?? 0.0).toDouble();
              String status = (data['status'] ?? 'pendente').toString().toLowerCase();

              if (status == 'pago') {
                totalPago += val;
              } else {
                totalPendente += val;
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balanço Financeiro Escolar (Tempo Real)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLinhaFinanceira('Total Recebido (Pago)', 'R\$ ${totalPago.toStringAsFixed(2)}', Colors.green),
                _buildLinhaFinanceira('Pendente / A Vencer', 'R\$ ${totalPendente.toStringAsFixed(2)}', Colors.orange),
                _buildLinhaFinanceira('Cobranças Emitidas', '${docs.length} mensalidades', Colors.blue),
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
            );
          },
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
                                            await _firestoreService.atualizarStatusJustificativa(docs[index].id, 'rejeitado');
                                            if (mounted) Navigator.pop(ctx);
                                          },
                                          child: const Text('Rejeitar'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                          onPressed: () async {
                                            await _firestoreService.atualizarStatusJustificativa(docs[index].id, 'aprovado');
                                            if (mounted) Navigator.pop(ctx);
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
}