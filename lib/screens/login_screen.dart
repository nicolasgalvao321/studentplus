import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'professor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();

  bool _isLogin = true; // Alterna entre Login (true) e Registo (false)
  String _roleSelecionado = 'aluno'; // Perfil padrão no registo
  bool _carregando = false;

  final AuthService _authService = AuthService();

  void _submeter() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final nome = _nomeController.text.trim();

    if (email.isEmpty || senha.isEmpty || (!_isLogin && nome.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      if (_isLogin) {
        // --- FLUXO DE LOGIN ---
        await _authService.login(email, senha);
      } else {
        // --- FLUXO DE REGISTO (Guarda o perfil escolhido) ---
        await _authService.cadastrar(
          email: email,
          password: senha,
          nome: nome,
          role: _roleSelecionado,
        );
      }

      // Redireciona de acordo com o papel no Firestore
      String role = await _authService.getUserRole();
      if (!mounted) return;

      if (role == 'professor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfessorHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E3B68),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLogin ? 'Student+' : 'Criar Conta',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E3B68),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo Nome (apenas se for Registo)
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Campo Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo Senha
                  TextField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Palavra-passe',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seleção de Perfil (apenas se for Registo)
                  if (!_isLogin) ...[
                    DropdownButtonFormField<String>(
                      value: _roleSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Eu sou:',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'aluno',
                          child: Text('Aluno'),
                        ),
                        DropdownMenuItem(
                          value: 'professor',
                          child: Text('Professor'),
                        ),
                      ],
                      onChanged: (novoValor) {
                        if (novoValor != null) {
                          setState(() => _roleSelecionado = novoValor);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botão Entrar / Cadastrar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _submeter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E3B68),
                      ),
                      child: _carregando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        _isLogin ? 'ENTRAR' : 'REGISTAR',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  // Alternar entre Login e Cadastro
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = !_isLogin);
                    },
                    child: Text(
                      _isLogin
                          ? 'Não tem conta? Registe-se'
                          : 'Já tem conta? Faça Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}