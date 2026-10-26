import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';

class GestaoRecadosScreen extends StatefulWidget {
  final bool isProfessor;

  const GestaoRecadosScreen({super.key, this.isProfessor = false});

  @override
  State<GestaoRecadosScreen> createState() => _GestaoRecadosScreenState();
}

class _GestaoRecadosScreenState extends State<GestaoRecadosScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _conteudoController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  Future<void> _abrirLink(String url) async {
    final String urlTratada = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    final Uri uri = Uri.parse(urlTratada);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o link.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir link: $e')),
        );
      }
    }
  }

  void _mostrarDialogNovoRecado() {
    _tituloController.clear();
    _conteudoController.clear();
    _linkController.clear();

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo do Recado',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link / Anexo (Word, Vídeo, Drive - opcional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Publicar Recado'),
                onPressed: () async {
                  final titulo = _tituloController.text.trim();
                  final conteudo = _conteudoController.text.trim();
                  final link = _linkController.text.trim();

                  if (titulo.isEmpty || conteudo.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Preencha o título e o conteúdo.')),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);

                  await _firestoreService.addRecado(
                    titulo: titulo,
                    conteudo: conteudo,
                    autor: 'Professor',
                    linkAnexo: link,
                  );

                  if (mounted) {
                    nav.pop();
                    messenger.showSnackBar(
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
        title: Text(widget.isProfessor ? 'Mural de Recados' : 'Recados'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getRecados(),
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
              child: Text('Nenhum recado no mural.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String titulo = data['titulo'] ?? '';
              final String conteudo = data['conteudo'] ?? '';
              final String autorNome = data['autor'] ?? data['autorNome'] ?? 'Professor';
              final String link = data['linkAnexo'] ?? data['link'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.isProfessor)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('recados')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por: $autorNome',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        conteudo,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (link.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _abrirLink(link),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 18,
                                  color: Colors.amber.shade900,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Abrir Anexo / Link (Vídeo / Documento)',
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Colors.amber.shade900,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
        onPressed: _mostrarDialogNovoRecado,
        backgroundColor: Colors.amber.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}
