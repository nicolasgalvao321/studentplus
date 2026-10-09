import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class TarefasScreen extends StatefulWidget {
  final bool isProfessor;
  final String? alunoUid;
  final String? alunoNome;

  const TarefasScreen({
    super.key,
    this.isProfessor = false,
    this.alunoUid,
    this.alunoNome,
  });

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  String? _disciplinaSelecionada;
  DateTime _dataEntregaSelecionada = DateTime.now();

  String _formatarData(DateTime date) {
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    return '$dia/$mes/${date.year}';
  }

  void _abrirCupertinoDatePicker(
      BuildContext context, StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builderContext) {
        return Container(
          height: 280,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => Navigator.of(builderContext).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Concluído',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(builderContext).pop(),
                  ),
                ],
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _dataEntregaSelecionada,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2030),
                  onDateTimeChanged: (DateTime newDate) {
                    setModalState(() {
                      _dataEntregaSelecionada = newDate;
                    });
                    setState(() {
                      _dataEntregaSelecionada = newDate;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogNovaTarefa() {
    _tituloController.clear();
    _descricaoController.clear();
    _disciplinaSelecionada = null;
    _dataEntregaSelecionada = DateTime.now();

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
                    'Nova Tarefa (${widget.alunoNome ?? 'Aluno'})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título da Tarefa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getDisciplinas(widget.alunoUid),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final items = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nome = data['nome'] ?? 'Sem nome';
                        final materia = data['materia'] ?? 'Geral';
                        return DropdownMenuItem<String>(
                          value: nome,
                          child: Text('$nome ($materia)'),
                        );
                      }).toList();

                      return DropdownButtonFormField<String>(
                        value: _disciplinaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Selecione a Disciplina',
                          border: OutlineInputBorder(),
                        ),
                        items: items,
                        hint: const Text('Escolha uma disciplina'),
                        onChanged: (val) {
                          setModalState(() {
                            _disciplinaSelecionada = val;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricaoController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição / Orientações',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () =>
                        _abrirCupertinoDatePicker(context, setModalState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.calendar,
                                  color: Colors.orange),
                              const SizedBox(width: 10),
                              Text(
                                'Data limite: ${_formatarData(_dataEntregaSelecionada)}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Lançar Tarefa'),
                    onPressed: () async {
                      final titulo = _tituloController.text.trim();
                      if (titulo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Insira o título da tarefa.')),
                        );
                        return;
                      }

                      await _firestoreService.adicionarTarefa(
                        uid: widget.alunoUid,
                        titulo: titulo,
                        descricao: _descricaoController.text.trim(),
                        disciplina: _disciplinaSelecionada ?? 'Geral',
                        dataEntrega: Timestamp.fromDate(_dataEntregaSelecionada),
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Tarefa lançada com sucesso!')),
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
    final String titulo = widget.alunoNome != null
        ? 'Tarefas - ${widget.alunoNome}'
        : 'Minhas Tarefas';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getTarefas(widget.alunoUid),
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
              child: Text('Nenhuma tarefa registada.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String titulo = data['titulo'] ?? '';
              final String descricao = data['descricao'] ?? '';
              final String disciplina = data['disciplina'] ?? '';
              final bool concluida = data['concluida'] ?? false;

              String dataEntregaFormatada = 'Sem data';
              final rawData = data['dataEntrega'] ?? data['data'];

              if (rawData is Timestamp) {
                dataEntregaFormatada = _formatarData(rawData.toDate());
              } else if (rawData is String && rawData.isNotEmpty) {
                dataEntregaFormatada = rawData;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: Checkbox(
                    value: concluida,
                    activeColor: Colors.orange,
                    onChanged: (bool? novoValor) async {
                      if (novoValor != null) {
                        await _firestoreService.alternarStatusTarefa(
                            doc.id, novoValor, widget.alunoUid);
                      }
                    },
                  ),
                  title: Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration:
                      concluida ? TextDecoration.lineThrough : null,
                      color: concluida ? Colors.grey : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (disciplina.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Disciplina: $disciplina',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                      if (descricao.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          descricao,
                          style: TextStyle(
                            decoration:
                            concluida ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Entrega: $dataEntregaFormatada',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: widget.isProfessor
                      ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await _firestoreService.deletarTarefa(
                          doc.id, widget.alunoUid);
                    },
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isProfessor
          ? FloatingActionButton(
        onPressed: _mostrarDialogNovaTarefa,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}