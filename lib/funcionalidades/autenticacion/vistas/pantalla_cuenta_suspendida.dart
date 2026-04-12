import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/apelacion_view_model.dart';

class PantallaCuentaSuspendida extends StatefulWidget {
  const PantallaCuentaSuspendida({super.key});

  @override
  State<PantallaCuentaSuspendida> createState() => _PantallaCuentaSuspendidaState();
}

class _PantallaCuentaSuspendidaState extends State<PantallaCuentaSuspendida> {
  final _controladorMotivo = TextEditingController();

  @override
  void dispose() {
    _controladorMotivo.dispose();
    super.dispose();
  }

  void _abrirDialogoApelacion(ApelacionViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Levantar Apelación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Explica detalladamente por qué crees que tu cuenta debería ser reactivada. El administrador revisará tu caso.'),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorMotivo,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe tu justificación aquí...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: viewModel.estaCargando ? null : () async {
              final error = await viewModel.enviarApelacion(_controladorMotivo.text);
              if (!mounted) return;

              Navigator.pop(ctx); // Cerrar diálogo

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Apelación enviada correctamente. Se revisará pronto.'),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                ),
              );

              if (error == null) _controladorMotivo.clear();
            },
            child: const Text('Enviar Apelación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ApelacionViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.gavel, size: 120, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Cuenta Suspendida',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu acceso a TacoHub ha sido bloqueado debido a la acumulación de reportes o infracciones a nuestros términos de servicio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async => await Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _abrirDialogoApelacion(viewModel),
              icon: const Icon(Icons.support_agent),
              label: const Text('Contactar al Administrador (Apelar)'),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
