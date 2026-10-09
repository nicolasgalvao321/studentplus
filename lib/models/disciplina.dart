class Disciplina {
  final String id;
  final String nome;
  final String professor;
  final String corHex;
  final int faltas;
  final int limiteFaltas;

  Disciplina({
    required this.id,
    required this.nome,
    required this.professor,
    required this.corHex,
    this.faltas = 0,
    this.limiteFaltas = 15,
  });
}