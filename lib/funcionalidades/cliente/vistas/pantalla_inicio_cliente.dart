import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/inicio_cliente_view_model.dart';

class PantallaInicioCliente extends StatelessWidget {
  const PantallaInicioCliente({super.key});

  @override
  Widget build(BuildContext context) {
    // Conectamos la vista con su ViewModel
    final viewModel = context.watch<InicioClienteViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TacoHub - Menú'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, '/perfil');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Si está cargando, desactiva el botón. Si no, ejecuta el cierre de sesión.
            onPressed: viewModel.estaCargando
                ? null
                : () => viewModel.cerrarSesion(() {
                      // Esta navegación ocurre solo cuando el ViewModel avisa que terminó
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (ruta) => false);
                      }
                    }),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido a TacoHub!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Explora los mejores tacos de la ciudad',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Próximamente: Navegar a la pantalla de búsqueda de taquerías
              },
              icon: const Icon(Icons.search),
              label: const Text('Buscar Taquerías'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}