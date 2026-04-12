import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/login_view_model.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  void _procesarLogin(LoginViewModel viewModel) async {
    FocusScope.of(context).unfocus();

    final correo = _controladorCorreo.text.trim();
    final contrasena = _controladorContrasena.text;

    final mensajeError = await viewModel.iniciarSesion(
      correo,
      contrasena,
          () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (ruta) => false);
        }
      },
    );

    if (mensajeError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TacoHub - Bienvenidos'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 100, color: Colors.orange),
            const SizedBox(height: 10),
            const Text(
              'TacoHub',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controladorCorreo,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !viewModel.estaCargando,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorContrasena,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    viewModel.ocultarContrasena ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    viewModel.alternarVisibilidadContrasena();
                  },
                ),
              ),
              obscureText: viewModel.ocultarContrasena,
              enabled: !viewModel.estaCargando,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (viewModel.estaCargando || viewModel.estaBloqueado)
                  ? null
                  : () => _procesarLogin(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: viewModel.estaBloqueado ? Colors.grey : Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                disabledBackgroundColor: viewModel.estaBloqueado ? Colors.grey[400] : Colors.orange[200],
              ),
              child: viewModel.estaBloqueado
                  ? Text(
                'Bloqueado: Reintenta en ${viewModel.segundosRestantes}s',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
                  : (viewModel.estaCargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Iniciar Sesión')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: viewModel.estaCargando ? null : () {
                Navigator.pushNamed(context, '/registro');
              },
              child: const Text('¿No tienes cuenta? Únete a TacoHub'),
            ),
            TextButton(
              onPressed: viewModel.estaCargando ? null : () {
                // AQUÍ ACTIVAMOS LA NAVEGACIÓN A LA RECUPERACIÓN
                Navigator.pushNamed(context, '/recuperar_contrasena');
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ],
        ),
      ),
    );
  }
}
