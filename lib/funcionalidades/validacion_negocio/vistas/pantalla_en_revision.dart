import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaEnRevision extends StatelessWidget {
  const PantallaEnRevision({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 100, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Documentos en Revisión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Un administrador está revisando tu solicitud. Te notificaremos cuando tu taquería sea aprobada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión por ahora'),
              )
            ],
          ),
        ),
      ),
    );
  }
}