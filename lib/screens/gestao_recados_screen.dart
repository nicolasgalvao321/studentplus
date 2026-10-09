import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class GestaoRecadosScreen extends StatefulWidget {
  final bool isProfessor; // Se verdadeiro, permite criar/eliminar recados

  const GestaoRecadosScreen({super.key, this.isProfessor = true});

  @override
  State<GestaoRecadosScreen> createState() => _GestaoRecadosScreenState();
}

class _GestaoRecadosScreenState extends State<GestaoRecadosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _conteudoController = TextEditingController();

  // Dialog/Modal para o Professor escrever um novo recado
  void _mostrarDialogNovoRecado() {
    _tituloController.clear();
    _conteudoController.clear();

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
              const Text(
                'Novo Recado / Aviso',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título do Recado',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _conteudoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mensagem / Conteúdo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E3B68),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Publicar Recado'),
                onPressed: () async {
                  final titulo = _tituloController.text.trim();
                  final conteudo = _conteudoController.text.trim();

                  if (titulo.isEmpty || conteudo.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Preencha o título e o conteúdo.')),
                    );
                    return;
                  }

                  // Obtém o nome do professor ou valor padrão
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_authService.currentUser?.uid)
                      .get();

                  final String nomeProfessor =
                      userDoc.data()?['nome'] ?? 'Professor';

                  await _firestoreService.enviarRecado(
                    titulo: titulo,
                    conteudo: conteudo,
                    autorNome: nomeProfessor,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Recado publicado com sucesso!')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Recados'),
        backgroundColor: const Color(0xFF0E3B68),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getRecados(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar recados: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum recado na agenda até ao momento.'),
            );
          }

          final recados = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recados.length,
            itemBuilder: (context, index) {
              final doc = recados[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final String titulo = data['titulo'] ?? 'Sem título';
              final String conteudo = data['conteudo'] ?? '';
              final String autor = data['autorNome'] ?? 'Professor';
              final Timestamp? dataTimestamp = data['criadoEm'] as Timestamp?;

              String dataFormatada = 'Data indisponível';
              if (dataTimestamp != null) {
                final dt = dataTimestamp.toDate();
                dataFormatada =
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0E3B68),
                              ),
                            ),
                          ),
                          if (widget.isProfessor)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar Recado'),
                                    content: const Text(
                                        'Deseja apagar este recado da agenda?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Eliminar',
                                            style:
                                            TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmar == true) {
                                  await _firestoreService
                                      .deletarRecado(doc.id);
                                }
                              },
                            ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        conteudo,
                        style: const TextStyle(fontSize: 15, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Por: $autor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            dataFormatada,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
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
          ? FloatingActionButton.extended(
        onPressed: _mostrarDialogNovoRecado,
        backgroundColor: const Color(0xFF0E3B68),
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text(
          'Novo Recado',
          style: TextStyle(color: Colors.white),
        ),
      )
          : null,
    );
  }
}