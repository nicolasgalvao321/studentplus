import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'disciplinas_screen.dart';

class ResponsavelHomeScreen extends StatefulWidget {
  const ResponsavelHomeScreen({super.key});

  @override
  State<ResponsavelHomeScreen> createState() => _ResponsavelHomeScreenState();
}

class _ResponsavelHomeScreenState extends State<ResponsavelHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? _alunoId;
  String _nomeAluno = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _carregarDadosFilho();
  }

  void _carregarDadosFilho() async {
    try {
      var alunoDoc = await _firestoreService.getAlunoVinculado(_uid);
      if (alunoDoc.exists) {
        setState(() {
          _alunoId = alunoDoc.id;
          _nomeAluno = alunoDoc.get('nome') ?? 'Aluno Vinculado';
        });
        await _firestoreService.inicializarMensalidadesExemplo(_alunoId!);
      } else {
        setState(() => _nomeAluno = 'Nenhum aluno vinculado');
      }
    } catch (e) {
      setState(() => _nomeAluno = 'Aluno Vinculado (Demo)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área dos Pais e Responsáveis'),
        backgroundColor: Colors.indigo,
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
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.face, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Acompanhando o Aluno:', style: TextStyle(fontSize: 12, color: Colors.indigo)),
                          Text(_nomeAluno, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Status Pedagógico: Regular', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Acesso Rápido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildMenuCard(
                  context,
                  titulo: 'Frequência e Faltas',
                  icone: Icons.calendar_today,
                  cor: Colors.orange,
                  onTap: () {
                    if (_alunoId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DisciplinasScreen(
                            alunoUid: _alunoId!,
                            isProfessor: false,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildMenuCard(
                  context,
                  titulo: 'Justificar Ausência',
                  icone: Icons.assignment_turned_in,
                  cor: Colors.teal,
                  onTap: () => _abrirModalJustificativa(context),
                ),
                _buildMenuCard(
                  context,
                  titulo: 'Mensalidades',
                  icone: Icons.attach_money,
                  cor: Colors.green,
                  onTap: () => _abrirModalFinanceiro(context),
                ),
                _buildMenuCard(
                  context,
                  titulo: 'Comunicados',
                  icone: Icons.campaign,
                  cor: Colors.blue,
                  onTap: () => _abrirModalComunicados(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String titulo, required IconData icone, required Color cor, required VoidCallback onTap}) {
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
            ],
          ),
        ),
      ),
    );
  }

  void _abrirModalJustificativa(BuildContext context) {
    final motivoController = TextEditingController();
    final disciplinaController = TextEditingController();
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Justificativa / Atestado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: disciplinaController, decoration: const InputDecoration(labelText: 'Disciplina')),
              TextField(controller: motivoController, decoration: const InputDecoration(labelText: 'Motivo / Observação'), maxLines: 2),
              TextField(controller: linkController, decoration: const InputDecoration(labelText: 'Link do Atestado/Comprovante (Drive/Cloud)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.isNotEmpty && _alunoId != null) {
                await _firestoreService.enviarJustificativa(
                  alunoId: _alunoId!,
                  responsavelUid: _uid,
                  disciplina: disciplinaController.text,
                  dataFalta: DateTime.now().toString().split(' ')[0],
                  motivo: motivoController.text,
                  linkComprovante: linkController.text,
                );
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Justificativa enviada para a coordenação!')));
              }
            },
            child: const Text('Enviar'),
          )
        ],
      ),
    );
  }

  // Modal de Mensalidades (SEM OS BOTÕES DE ANO NA PARTE SUPERIOR)
  void _abrirModalFinanceiro(BuildContext context) {
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
            const Text('Financeiro & Mensalidades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Acompanhe os boletos e efetue pagamentos em tempo real.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getMensalidadesDoAluno(_alunoId ?? ''),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('Nenhuma mensalidade cadastrada.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      String docId = doc.id;
                      String status = (data['status'] ?? 'pendente').toString().toLowerCase();
                      double valor = (data['valor'] ?? 0.0).toDouble();
                      String titulo = data['titulo'] ?? 'Mensalidade';
                      String vencimento = data['vencimento'] ?? '';

                      Color corStatus = Colors.orange;
                      String statusText = 'PENDENTE';

                      if (status == 'pago') {
                        corStatus = Colors.green;
                        statusText = 'PAGO';
                      } else if (status == 'a vencer') {
                        corStatus = Colors.blue;
                        statusText = 'A VENCER';
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(Icons.receipt_long, color: corStatus),
                          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('R\$ ${valor.toStringAsFixed(2)} • Vencimento: $vencimento'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: corStatus.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text(statusText, style: TextStyle(color: corStatus, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          onTap: () {
                            if (status != 'pago') {
                              _simularPagamentoModal(context, docId, titulo, valor);
                            }
                          },
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

  void _simularPagamentoModal(BuildContext context, String docId, String titulo, double valor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Simular Pagamento: $titulo'),
        content: Text('Valor: R\$ ${valor.toStringAsFixed(2)}\n\nDeseja simular o pagamento via PIX para atualizar o status para PAGO em tempo real?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestoreService.simularPagamentoMensalidade(docId);
              if (mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento confirmado com sucesso! Status atualizado para PAGO.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar Pagamento (PIX)'),
          ),
        ],
      ),
    );
  }

  void _abrirModalComunicados(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comunicados da Coordenação', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getRecadosParaResponsavel(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('Nenhum comunicado no momento.'));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      List confirmacoes = data['confirmacoes'] ?? [];
                      bool ciente = confirmacoes.contains(_uid);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(data['titulo'] ?? 'Sem título', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['conteudo'] ?? ''),
                          trailing: ElevatedButton.icon(
                            icon: Icon(ciente ? Icons.check_circle : Icons.radio_button_unchecked, size: 16),
                            label: Text(ciente ? 'Ciente' : 'Assinar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ciente ? Colors.grey : Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: ciente
                                ? null
                                : () async {
                              await _firestoreService.confirmarLeituraRecado(docs[index].id, _uid);
                              setState(() {});
                            },
                          ),
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