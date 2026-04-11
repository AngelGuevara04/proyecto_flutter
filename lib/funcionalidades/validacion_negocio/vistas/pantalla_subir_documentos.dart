import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/subir_documentos_view_model.dart';

class PantallaSubirDocumentos extends StatefulWidget {
  const PantallaSubirDocumentos({super.key});

  @override
  State<PantallaSubirDocumentos> createState() => _PantallaSubirDocumentosState();
}

class _PantallaSubirDocumentosState extends State<PantallaSubirDocumentos> {
  final _controladorRfc = TextEditingController();
  final _controladorNombre = TextEditingController();

  @override
  void dispose() {
    _controladorRfc.dispose();
    _controladorNombre.dispose();
    super.dispose();
  }

  void _procesarEnvio(SubirDocumentosViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    final error = await viewModel.enviarDocumentacion(
      _controladorRfc.text.trim(),
      _controladorNombre.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pushReplacementNamed(context, '/en_revision');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubirDocumentosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validación de Taquería'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.domain_verification, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              '¡Casi listo para vender!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Por seguridad, necesitamos verificar tu negocio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controladorNombre,
              decoration: const InputDecoration(
                labelText: 'Nombre Comercial',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorRfc,
              decoration: const InputDecoration(
                labelText: 'RFC del Negocio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: viewModel.estaCargando ? null : () => _procesarEnvio(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: viewModel.estaCargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar a Revisión'),
            ),
          ],
        ),
      ),
    );
  }
}