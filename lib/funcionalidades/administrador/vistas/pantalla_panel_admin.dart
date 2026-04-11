import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/panel_admin_view_model.dart';

class PantallaPanelAdmin extends StatefulWidget {
  const PantallaPanelAdmin({super.key});

  @override
  State<PantallaPanelAdmin> createState() => _PantallaPanelAdminState();
}

class _PantallaPanelAdminState extends State<PantallaPanelAdmin> {
  @override
  void initState() {
    super.initState();
    // Consultamos los datos reales de Supabase al iniciar la pantalla
    Future.microtask(() =>
        context.read<PanelAdminViewModel>().consultarSolicitudes());
  }

  // Función interna para manejar la respuesta visual de las acciones
  void _gestionar(PanelAdminViewModel viewModel, Map<String, dynamic> solicitud, String nuevoEstatus) async {
    final nombre = solicitud['nombre_comercial'];
    final accion = nuevoEstatus == 'aprobado' ? 'aprobado' : 'rechazado';

    await viewModel.gestionarSolicitud(
      solicitud['id'].toString(),
      solicitud['usuario_id'].toString(),
      nuevoEstatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nombre ha sido $accion'),
          backgroundColor: nuevoEstatus == 'aprobado' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PanelAdminViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (ruta) => false);
              }
            },
          ),
        ],
      ),
      body: viewModel.estaCargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => viewModel.consultarSolicitudes(),
        child: viewModel.solicitudes.isEmpty
            ? _buildVistaVacia()
            : _buildListaSolicitudes(viewModel),
      ),
    );
  }

  // Widget para cuando no hay nada que revisar
  Widget _buildVistaVacia() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.done_all, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay solicitudes pendientes',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text('Desliza hacia abajo para actualizar'),
            ],
          ),
        ),
      ],
    );
  }

  // Widget que construye la lista de tarjetas
  Widget _buildListaSolicitudes(PanelAdminViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: viewModel.solicitudes.length,
      itemBuilder: (context, indice) {
        final solicitud = viewModel.solicitudes[indice];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.store, color: Colors.white),
              ),
              title: Text(
                solicitud['nombre_comercial'] ?? 'Sin nombre',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RFC: ${solicitud['rfc']}'),
                  Text(
                    'ID Usuario: ${solicitud['usuario_id'].toString().substring(0, 8)}...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón Aprobar
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    onPressed: () => _gestionar(viewModel, solicitud, 'aprobado'),
                  ),
                  // Botón Rechazar
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                    onPressed: () => _gestionar(viewModel, solicitud, 'rechazado'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}