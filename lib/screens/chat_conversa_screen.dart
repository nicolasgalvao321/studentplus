import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ChatConversaScreen extends StatefulWidget {
  final String chatId;
  final String meuUid;
  final String outroNome;

  const ChatConversaScreen({
    super.key,
    required this.chatId,
    required this.meuUid,
    required this.outroNome,
  });

  @override
  State<ChatConversaScreen> createState() => _ChatConversaScreenState();
}

class _ChatConversaScreenState extends State<ChatConversaScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _mensagemController = TextEditingController();

  void _enviar() async {
    String texto = _mensagemController.text;
    if (texto.trim().isEmpty) return;
    _mensagemController.clear();
    await _firestoreService.enviarMensagem(
      chatId: widget.chatId,
      remetenteUid: widget.meuUid,
      texto: texto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.outroNome,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54), // Verde WhatsApp
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFECE5DD), // Fundo suave estilo WhatsApp
      body: Column(
        children: [
          // Lista de Mensagens
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getMensagensChat(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Erro ao carregar mensagens: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma mensagem ainda. Diga olá!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Começa do fim (mensagens recentes embaixo)
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool eMinha = data['remetenteUid'] == widget.meuUid;
                    String texto = data['texto'] ?? '';

                    return Align(
                      alignment:
                      eMinha ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: eMinha ? const Color(0xFFDCF8C6) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(eMinha ? 12 : 0),
                            bottomRight: Radius.circular(eMinha ? 0 : 12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Text(
                          texto,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de Entrada de Texto Estilo WhatsApp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensagemController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF075E54),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _enviar,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
