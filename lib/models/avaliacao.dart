class Avaliacao {
  final String id;
  final String disciplinaNome;
  final String titulo;
  final double notaObtida;
  final double notaMaxima;
  final String tipo; // 'Trabalho' ou 'Prova'

  const Avaliacao({
    required this.id,
    required this.disciplinaNome,
    required this.titulo,
    required this.notaObtida,
    this.notaMaxima = 10.0,
    required this.tipo,
  });
}