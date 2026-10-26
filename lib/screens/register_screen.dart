import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _alunoIdController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  String _selectedRole = 'aluno';
  bool _carregando = false;

  Future<void> _realizarCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      String alunoIdDigitado = _alunoIdController.text.trim();

      if (_selectedRole == 'responsavel') {
        DocumentSnapshot alunoDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(alunoIdDigitado)
            .get();

        if (!alunoDoc.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ID do aluno não existente! Verifique o código e tente novamente.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _carregando = false);
          return;
        }
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'criadoEm': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'responsavel') {
        userData['alunoId'] = alunoIdDigitado;
      }

      await _firestoreService.saveUserData(uid, userData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Faça login para continuar.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao cadastrar.';
      if (e.code == 'email-already-in-use') {
        mensagem = 'Este e-mail já está em uso.';
      } else if (e.code == 'weak-password') {
        mensagem = 'A senha deve ter pelo menos 6 caracteres.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Formato de e-mail inválido.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Nova Conta'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tipo de Conta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'aluno',
                    label: Text('Aluno', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.school, size: 16),
                  ),
                  ButtonSegment(
                    value: 'professor',
                    label: Text('Prof.', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.person_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: 'responsavel',
                    label: Text('Pais', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.family_restroom, size: 16),
                  ),
                  ButtonSegment(
                    value: 'funcionario',
                    label: Text('Staff', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.admin_panel_settings, size: 16),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Informe o seu nome';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Informe o e-mail';
                  if (!val.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha (mínimo 6 caracteres)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Informe a senha';
                  if (val.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_selectedRole == 'responsavel') ...[
                Card(
                  color: Colors.indigo.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vínculo do Filho',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Digite o UID/ID do aluno cadastrado para associá-lo a esta conta.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _alunoIdController,
                          decoration: const InputDecoration(
                            labelText: 'ID / UID do Aluno',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          validator: (val) {
                            if (_selectedRole == 'responsavel' && (val == null || val.isEmpty)) {
                              return 'Informe o ID do aluno vinculado';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _carregando ? null : _realizarCadastro,
                  child: _carregando
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'CRIAR CONTA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}