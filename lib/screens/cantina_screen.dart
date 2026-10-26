import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class CantinaScreen extends StatelessWidget {
  final bool isStaff; // Controls edit/delete permissions

  const CantinaScreen({super.key, this.isStaff = false});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cardápio da Cantina'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getCardapioCantina(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum item cadastrado no cardápio no momento.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              String nome = data['nome'] ?? 'Lanche';
              double preco = (data['preco'] ?? 0.0).toDouble();

              // Formata para exibição em Reais com vírgula (ex: R$ 7,50)
              String precoFormatado =
                  'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.fastfood, color: Colors.white),
                  ),
                  title: Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    precoFormatado,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  // Exibe a lixeira APENAS para Funcionários / Staff
                  trailing: isStaff
                      ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await firestoreService.deletarLancheCantina(docId);
                    },
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
      // Botão de Adicionar Lanche (Exibido APENAS para Funcionários / Staff)
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Lanche'),
        onPressed: () => _abrirModalAdicionarLanche(context, firestoreService),
      )
          : null,
    );
  }

  void _abrirModalAdicionarLanche(
      BuildContext context, FirestoreService service) {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadastrar Lanche da Cantina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Lanche (ex: Coxinha de Frango)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço em R\$ (ex: 7,50 ou 7.50)',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              String nomeText = nomeController.text.trim();
              String precoText = precoController.text.trim().replaceAll(',', '.');

              if (nomeText.isNotEmpty && precoText.isNotEmpty) {
                double precoParsed = double.tryParse(precoText) ?? 0.0;
                await service.addLancheCantina(nomeText, precoParsed);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }
}