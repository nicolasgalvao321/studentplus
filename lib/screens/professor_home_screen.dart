import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'gestao_faltas_screen.dart';
import 'gestao_recados_screen.dart';
import 'calendario_screen.dart';
import 'selecao_aluno_screen.dart';
import 'cantina_screen.dart';
import 'disciplinas_screen.dart';
import 'lista_chats_screen.dart';

class ProfessorHomeScreen extends StatelessWidget {
  const ProfessorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E3B68),
      appBar: AppBar(
        title: const Text('Portal do Professor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              'Painel do Professor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context: context,
                    title: 'LANÇAR FALTAS',
                    icon: Icons.school,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GestaoFaltasScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'CADASTRAR DISCIPLINAS',
                    icon: Icons.book,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DisciplinasScreen(isProfessor: true), // HABILITA MÓDULO DE CADASTRO
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'PASSAR TAREFAS',
                    icon: Icons.task_alt,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelecaoAlunoScreen(
                            tipoSelecao: TipoSelecao.tarefas,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'AGENDA DE RECADOS',
                    icon: Icons.assignment_outlined,
                    color: Colors.amber.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const GestaoRecadosScreen(isProfessor: true),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'CANTINA',
                    icon: Icons.fastfood,
                    color: Colors.orange.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CantinaScreen(isStaff: false), // SOMENTE LEITURA
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'MENSAGENS',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF075E54),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListaChatsScreen(
                            meuUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                            meuNome: 'Professor',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'CALENDÁRIO',
                    icon: Icons.calendar_month,
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const CalendarioScreen(isProfessor: true),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
