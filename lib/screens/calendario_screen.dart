import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class CalendarioScreen extends StatefulWidget {
  final bool isProfessor;

  const CalendarioScreen({super.key, this.isProfessor = true});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  DateTime _selectedDate = DateTime.now();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  String _tipoSelecionado = 'Prova';

  // Auxiliar para comparar se duas datas correspondem ao mesmo dia
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Função para definir a cor da etiqueta pelo tipo de evento
  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'Prova':
        return Colors.red.shade700;
      case 'Trabalho':
        return Colors.orange.shade800;
      case 'Compromisso':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Modal para o professor criar um compromisso/prova
  void _mostrarDialogNovoEvento() {
    _tituloController.clear();
    _descricaoController.clear();
    _tipoSelecionado = 'Prova';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  Text(
                    'Novo Evento (${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título (ex: Prova de Matemática)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Evento',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Prova', child: Text('Prova')),
                      DropdownMenuItem(
                          value: 'Trabalho', child: Text('Trabalho')),
                      DropdownMenuItem(
                          value: 'Compromisso', child: Text('Compromisso')),
                      DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _tipoSelecionado = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricaoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição / Conteúdo cobrado',
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
                    icon: const Icon(Icons.event_available),
                    label: const Text('Guardar no Calendário'),
                    onPressed: () async {
                      final titulo = _tituloController.text.trim();
                      final desc = _descricaoController.text.trim();

                      if (titulo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Insira o título do evento.')),
                        );
                        return;
                      }

                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_authService.currentUser?.uid)
                          .get();

                      final String nomeProf =
                          userDoc.data()?['nome'] ?? 'Professor';

                      await _firestoreService.adicionarEvento(
                        titulo: titulo,
                        descricao: desc,
                        tipo: _tipoSelecionado,
                        data: _selectedDate,
                        autorNome: nomeProf,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Evento adicionado com sucesso!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário Acadêmico'),
        backgroundColor: const Color(0xFF0E3B68),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Eventos de ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E3B68),
                  ),
                ),
                Icon(Icons.event_note, color: Colors.grey.shade600),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getEventos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erro ao carregar: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                final eventosDoDia = docs.where((doc) {
                  final dataMap = doc.data() as Map<String, dynamic>;
                  final Timestamp? ts = dataMap['data'] as Timestamp?;
                  if (ts == null) return false;
                  return _isSameDay(ts.toDate(), _selectedDate);
                }).toList();

                if (eventosDoDia.isEmpty) {
                  return const Center(
                    child: Text('Nenhum compromisso marcado para este dia.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: eventosDoDia.length,
                  itemBuilder: (context, index) {
                    final doc = eventosDoDia[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String titulo = data['titulo'] ?? '';
                    final String desc = data['descricao'] ?? '';
                    final String tipo = data['tipo'] ?? 'Outro';
                    final String autor = data['autorNome'] ?? 'Professor';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Chip(
                          label: Text(
                            tipo,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: _getTipoColor(tipo),
                        ),
                        title: Text(
                          titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(desc),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Por: $autor',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: widget.isProfessor
                            ? IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () async {
                            await _firestoreService.deletarEvento(doc.id);
                          },
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isProfessor
          ? FloatingActionButton.extended(
        onPressed: _mostrarDialogNovoEvento,
        backgroundColor: const Color(0xFF0E3B68),
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text(
          'Agendar Evento',
          style: TextStyle(color: Colors.white),
        ),
      )
          : null,
    );
  }
}