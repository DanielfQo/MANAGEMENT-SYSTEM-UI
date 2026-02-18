import 'package:flutter/material.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'auth_provider.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider); // Escuchamos el estado
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Login de Inventario')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 20),
            
            if (authState.isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).login(
                    usernameController.text,
                    passwordController.text,
                  );
                  
                },
                child: const Text('Entrar'),
              ),
            
            if (authState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
