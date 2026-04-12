import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/recuperar_contrasena_view_model.dart';

class PantallaRecuperarContrasena extends StatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  State<PantallaRecuperarContrasena> createState() => _PantallaRecuperarContrasenaState();
}

class _PantallaRecuperarContrasenaState extends State<PantallaRecuperarContrasena> {
  final _controladorCorreo = TextEditingController();

  @override
  void dispose() {
    _controladorCorreo.dispose();
    super.dispose();
  }

  void _solicitarRecuperacion(RecuperarContrasenaViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    final correo = _controladorCorreo.text.trim();
    final error = await viewModel.enviarCorreoRecuperacion(correo);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo de recuperación enviado. Revisa tu bandeja.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecuperarContrasenaViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Acceso')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: viewModel.estaCargando ? null : () => _solicitarRecuperacion(viewModel),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.orange,
              ),
              child: viewModel.estaCargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar Enlace', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
