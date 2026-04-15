import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/registro_view_model.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _controladorNombre = TextEditingController();
  final _controladorApellidoPat = TextEditingController();
  final _controladorApellidoMat = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  final _controladorConfirmarContrasena = TextEditingController();

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorApellidoPat.dispose();
    _controladorApellidoMat.dispose();
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    _controladorConfirmarContrasena.dispose();
    super.dispose();
  }

  void _procesarRegistro(RegistroViewModel viewModel) async {
    FocusScope.of(context).unfocus();

    final error = await viewModel.registrarUsuario(
      _controladorNombre.text.trim(),
      _controladorApellidoPat.text.trim(),
      _controladorApellidoMat.text.trim(), // puede estar vacío
      _controladorCorreo.text.trim(),
      _controladorContrasena.text,
      _controladorConfirmarContrasena.text,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Bienvenido a TacoHub! Registro exitoso.')),
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
    final viewModel = context.watch<RegistroViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Únete a TacoHub'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.orange),
            const SizedBox(height: 10),
            const Text(
              'Crea tu cuenta',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controladorNombre,
              decoration: const InputDecoration(
                labelText: 'Nombre(s)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !viewModel.estaCargando,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorApellidoPat,
              decoration: const InputDecoration(
                labelText: 'Apellido Paterno',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              enabled: !viewModel.estaCargando,
            ),
            const SizedBox(height: 16),
            // ── APELLIDO MATERNO OPCIONAL ──
            TextField(
              controller: _controladorApellidoMat,
              decoration: const InputDecoration(
                labelText: 'Apellido Materno (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
                helperText: 'Déjalo vacío si no tienes apellido materno',
              ),
              enabled: !viewModel.estaCargando,
            ),
            const SizedBox(height: 16),
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
              obscureText: viewModel.ocultarContrasena,
              decoration: InputDecoration(
                labelText: 'Contraseña (Mínimo 6 caracteres)',
                helperText: 'Debe incluir letras y números',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(viewModel.ocultarContrasena
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: viewModel.alternarVisibilidadContrasena,
                ),
              ),
              enabled: !viewModel.estaCargando,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorConfirmarContrasena,
              obscureText: viewModel.ocultarConfirmarContrasena,
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(viewModel.ocultarConfirmarContrasena
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed:
                  viewModel.alternarVisibilidadConfirmarContrasena,
                ),
              ),
              enabled: !viewModel.estaCargando,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Soy un negocio (Taquería)'),
              subtitle:
              const Text('Necesitarás validar tus documentos después'),
              value: viewModel.esNegocio,
              onChanged: viewModel.estaCargando
                  ? null
                  : (valor) =>
                  viewModel.cambiarTipoNegocio(valor ?? false),
              activeColor: Colors.orange,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: viewModel.estaCargando
                  ? null
                  : () => _procesarRegistro(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: viewModel.estaCargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Registrarme en TacoHub'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: viewModel.estaCargando
                  ? null
                  : () => Navigator.pop(context),
              child:
              const Text('¿Ya eres parte de TacoHub? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}