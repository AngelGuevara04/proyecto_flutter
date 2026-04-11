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
    Future.microtask(() => context.read<PanelAdminViewModel>().cargarDatosTabActual());
  }

  void _confirmarSuspension(PanelAdminViewModel viewModel, dynamic usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Suspender Cuenta'),
        content: Text('¿Estás seguro de suspender a ${usuario['nombre']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await viewModel.suspenderCuenta(usuario['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Cuenta suspendida')));
              }
            },
            child: const Text('Sí, Suspender'),
          ),
        ],
      ),
    );
  }

  void _confirmarResolucionApelacion(PanelAdminViewModel viewModel, dynamic apelacion, bool aprobar) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprobar ? '✅ Aprobar y Desbanear' : '❌ Rechazar Apelación'),
        content: Text(aprobar
            ? '¿Devolver acceso a ${apelacion['nombre']}?'
            : 'La cuenta seguirá suspendida.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: aprobar ? Colors.green : Colors.red,
                foregroundColor: Colors.white
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final msg = await viewModel.resolverApelacion(apelacion['id'].toString(), apelacion['usuario_id'], aprobar);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? '')));
              }
            },
            child: Text(aprobar ? 'Desbanear' : 'Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PanelAdminViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: viewModel.estaCargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => viewModel.cargarDatosTabActual(),
        child: _construirCuerpo(viewModel),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: viewModel.indiceTab,
        onTap: viewModel.cambiarTab,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.approval), label: 'Nuevos'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Negocios'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Apelación'),
        ],
      ),
    );
  }

  Widget _construirCuerpo(PanelAdminViewModel viewModel) {
    switch (viewModel.indiceTab) {
      case 0: return _buildSolicitudes(viewModel);
      case 1: return _buildDirectorio(viewModel, viewModel.soloUsuarios, Icons.person);
      case 2: return _buildDirectorio(viewModel, viewModel.soloNegocios, Icons.store);
      case 3: return _buildReportes(viewModel);
      case 4: return _buildApelaciones(viewModel);
      default: return const Center(child: Text('Vista no encontrada'));
    }
  }

  Widget _buildSolicitudes(PanelAdminViewModel viewModel) {
    if (viewModel.solicitudesPendientes.isEmpty) return const Center(child: Text('No hay solicitudes'));
    return ListView.builder(
      itemCount: viewModel.solicitudesPendientes.length,
      itemBuilder: (context, i) {
        final sol = viewModel.solicitudesPendientes[i];
        return ListTile(
          leading: const Icon(Icons.store, color: Colors.orange),
          title: Text(sol['nombre_comercial']),
          subtitle: Text('RFC: ${sol['rfc']}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => viewModel.gestionarSolicitud(sol['id'].toString(), sol['usuario_id'], 'aprobado')),
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => viewModel.gestionarSolicitud(sol['id'].toString(), sol['usuario_id'], 'rechazado')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectorio(PanelAdminViewModel viewModel, List<dynamic> lista, IconData icono) {
    if (lista.isEmpty) return const Center(child: Text('No hay registros'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final item = lista[i];
        final bool estaSuspendido = item['suspendido'] == true;
        final int reportes = item['total_reportes'] ?? 0;
        final bool enPeligro = reportes >= 15;

        return Card(
          color: estaSuspendido ? Colors.grey[300] : (enPeligro ? Colors.red[50] : Colors.white),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: estaSuspendido ? Colors.grey : (enPeligro ? Colors.red : Colors.blueGrey),
              child: Icon(icono, color: Colors.white),
            ),
            title: Text(item['nombre'], style: TextStyle(decoration: estaSuspendido ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['email']),
                if (reportes > 0) Text('🚨 Reportes: $reportes', style: TextStyle(color: enPeligro ? Colors.red : Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: estaSuspendido
                ? const Text('BANEADO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                : IconButton(icon: const Icon(Icons.block, color: Colors.red), onPressed: () => _confirmarSuspension(viewModel, item)),
          ),
        );
      },
    );
  }

  Widget _buildReportes(PanelAdminViewModel viewModel) {
    if (viewModel.reportes.isEmpty) return const Center(child: Text('Cero reportes. Todo tranquilo.'));
    return ListView.builder(
      itemCount: viewModel.reportes.length,
      itemBuilder: (context, i) {
        final rep = viewModel.reportes[i];
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Motivo: ${rep['motivo']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const Divider(),
                // AQUÍ ESTÁ EL CAMBIO PARA LEER DESDE EL RPC
                Text('Reportador: ${rep['reportador_email'] ?? 'Desconocido'}'),
                Text('Reportado: ${rep['reportado_email'] ?? 'Desconocido'}', style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApelaciones(PanelAdminViewModel viewModel) {
    if (viewModel.apelaciones.isEmpty) return const Center(child: Text('No hay apelaciones por revisar'));
    return ListView.builder(
      itemCount: viewModel.apelaciones.length,
      itemBuilder: (context, i) {
        final ap = viewModel.apelaciones[i];
        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_email_read, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text('De: ${ap['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  ],
                ),
                Text(ap['email'], style: const TextStyle(color: Colors.grey)),
                const Divider(),
                const Text('Justificación:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ap['motivo'], style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => _confirmarResolucionApelacion(viewModel, ap, true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Perdonar'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => _confirmarResolucionApelacion(viewModel, ap, false),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Rechazar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
