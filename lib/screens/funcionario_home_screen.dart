import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'gestao_recados_screen.dart';
import 'cantina_screen.dart';
import 'lista_chats_screen.dart';

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
              childAspectRatio: 1.1,
              children: [
                _buildCardMenu(
                  context,
                  titulo: 'Escala de Limpeza',
                  subtitulo: 'Horários dos banheiros',
                  icone: Icons.cleaning_services,
                  cor: Colors.cyan.shade800,
                  onTap: () => _abrirModalEscalaLimpeza(context),
                ),
                _buildCardMenu(
                  context,
                  titulo: 'Gerenciar Cantina',
                  subtitulo: 'Cardápio e preços',
                  icone: Icons.fastfood,
                  cor: Colors.orange.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CantinaScreen(isStaff: true),
                      ),
                    );
                  },
                ),
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
                  titulo: 'Mensagens / Chat',
                  subtitulo: 'Conversa direta com pais',
                  icone: Icons.chat_bubble_outline,
                  cor: const Color(0xFF075E54),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListaChatsScreen(
                          meuUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                          meuNome: 'Secretaria / Staff',
                        ),
                      ),
                    );
                  },
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
              CircleAvatar(backgroundColor: cor.withValues(alpha: 0.15), child: Icon(icone, color: cor)),
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

  // Modal 1: Escala Organizacional de Limpeza dos Banheiros
  void _abrirModalEscalaLimpeza(BuildContext context) {
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
            const Text('Horários e Escala de Limpeza', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Organização dos setores da equipe de limpeza', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  _buildCardSetorLimpeza(
                    setor: 'Banheiro de Baixo (Térreo)',
                    responsavel: 'Equipe Turno A',
                    horarios: ['07:30', '10:15 (Pós-recreio)', '14:00', '17:30'],
                    cor: Colors.blue,
                  ),
                  _buildCardSetorLimpeza(
                    setor: 'Banheiro de Cima (1º Andar)',
                    responsavel: 'Equipe Turno B',
                    horarios: ['08:00', '10:45 (Pós-recreio)', '14:30', '18:00'],
                    cor: Colors.teal,
                  ),
                  _buildCardSetorLimpeza(
                    setor: 'Banheiro dos Professores',
                    responsavel: 'Equipe Apoio Geral',
                    horarios: ['09:00', '12:00', '15:30'],
                    cor: Colors.purple,
                  ),
                  _buildCardSetorLimpeza(
                    setor: 'Pátio e Refeitório',
                    responsavel: 'Equipe Geral',
                    horarios: ['10:30', '13:00 (Pós-almoço)'],
                    cor: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSetorLimpeza({
    required String setor,
    required String responsavel,
    required List<String> horarios,
    required Color cor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sanitizer, color: cor),
                const SizedBox(width: 8),
                Text(setor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Responsáveis: $responsavel', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: horarios.map((h) {
                return Chip(
                  label: Text(h, style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.bold)),
                  backgroundColor: cor.withValues(alpha: 0.1),
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Modal 2: Envio de Boletos aos Pais
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
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: 'Descrição / Título (ex: Mensalidade - Novembro)'),
              ),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              ),
              TextField(
                controller: vencimentoController,
                decoration: const InputDecoration(labelText: 'Data de Vencimento (ex: 10/11/2026)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              if (alunoIdSelecionado != null && valorController.text.isNotEmpty) {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);

                await _firestoreService.gerarBoleto(
                  alunoId: alunoIdSelecionado!,
                  alunoNome: alunoNomeSelecionado ?? 'Aluno',
                  titulo: tituloController.text,
                  valor: double.tryParse(valorController.text) ?? 0.0,
                  vencimento: vencimentoController.text,
                  ano: DateTime.now().year,
                );
                nav.pop();
                messenger.showSnackBar(
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

  // Modal 3: Resumo Financeiro em Tempo Real
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

  // Modal 4: Aprovação de Justificativas e Atestados
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
}
