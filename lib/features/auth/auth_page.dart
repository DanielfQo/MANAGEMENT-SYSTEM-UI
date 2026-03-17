import 'package:flutter/material.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'auth_provider.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// ICONO SUPERIOR
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE9EEF6),
                ),
                child: const Icon(
                  Icons.construction,
                  size: 40,
                  color: Color(0xFF2F3A8F),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Ferretería Central",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                "Gestión de Inventario y Ventas",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              /// TARJETA LOGIN
              Container(
                width: 380,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Bienvenido",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const Text(
                      "Ingresa tus credenciales para continuar",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: "Usuario",
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: const Icon(Icons.visibility_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// BOTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F3A8F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          ref.read(authProvider.notifier).login(
                                usernameController.text,
                                passwordController.text,
                              );
                        },
                        child: authState.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Iniciar Sesión",
                                style: TextStyle(color: Colors.white, fontSize: 16)
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// OLVIDE PASSWORD
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text("¿Olvidaste tu contraseña?"),
                      ),
                    ),

                    if (authState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Si no tienes una cuenta, contacta al administrador",
                style: TextStyle(color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }
}