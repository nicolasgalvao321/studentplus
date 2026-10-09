class Tarefa {
  final String id;
  final String titulo;
  final String descricao;
  final DateTime dataVencimento;
  bool concluida;
  final String disciplinaNome;

  Tarefa({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataVencimento,
    this.concluida = false,
    required this.disciplinaNome,
  });
}