import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/panel_admin_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // ----------------------------------------------------------------------
  // DIÁLOGOS DE INTERACCIÓN (NUEVOS Y ACTUALIZADOS)
  // ----------------------------------------------------------------------

  // NUEVO: EXPEDIENTE COMPLETO DE LA SOLICITUD
  void _mostrarDetallesSolicitud(PanelAdminViewModel viewModel, dynamic solicitud) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.store, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(solicitud['nombre_comercial'] ?? 'Sin nombre', style: const TextStyle(fontSize: 20))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              Text('Propietario: ${solicitud['propietario'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('RFC: ${solicitud['rfc'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Dirección:', style: TextStyle(color: Colors.grey)),
              Text(solicitud['direccion'] ?? 'N/A', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),

              const Text('Documentos Adjuntos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),

              // CONEXIÓN AL NAVEGADOR
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Identificación Oficial'),
                subtitle: const Text('Toca para abrir documento'),
                trailing: const Icon(Icons.open_in_browser, color: Colors.blue),
                onTap: () async {
                  final url = solicitud['url_identificacion'];
                  if (url != null && url.startsWith('http')) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay archivo válido')));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Comprobante de Domicilio'),
                subtitle: const Text('Toca para abrir documento'),
                trailing: const Icon(Icons.open_in_browser, color: Colors.blue),
                onTap: () async {
                  final url = solicitud['url_comprobante_domicilio'];
                  if (url != null && url.startsWith('http')) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay archivo válido')));
                  }
                },
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mostrarDialogoRechazoSolicitud(viewModel, solicitud);
                },
                icon: const Icon(Icons.close),
                label: const Text('Rechazar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await viewModel.gestionarSolicitud(solicitud['id'].toString(), solicitud['usuario_id'], 'aprobado');
                },
                icon: const Icon(Icons.check),
                label: const Text('Aprobar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // NUEVO: EXPEDIENTE BÁSICO DEL USUARIO/NEGOCIO (Directorio)
  void _mostrarDetallesUsuario(dynamic usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Información del Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${usuario['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Text('Email: ${usuario['email']}'),
            const SizedBox(height: 8),
            Text('Rol en la App: ${usuario['rol'].toString().toUpperCase()}'),
            Text('Estatus: ${usuario['estatus'].toString().toUpperCase()}'),
            const SizedBox(height: 16),
            if ((usuario['total_reportes'] ?? 0) > 0)
              Text('Reportes Acumulados: ${usuario['total_reportes']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _mostrarDialogoRechazoSolicitud(PanelAdminViewModel viewModel, dynamic solicitud) {
    final controlMotivo = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Explica al taquero qué documentos están mal para que los corrija:'),
            const SizedBox(height: 10),
            TextField(
              controller: controlMotivo,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej. Tu RFC no coincide o la foto es borrosa...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (controlMotivo.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final error = await viewModel.gestionarSolicitud(solicitud['id'].toString(), solicitud['usuario_id'], 'rechazado', controlMotivo.text);
              if (mounted && error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
            },
            child: const Text('Confirmar Rechazo'),
          ),
        ],
      ),
    );
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
              await viewModel.suspenderCuenta(usuario['id']);
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
        content: Text(aprobar ? '¿Devolver acceso a ${apelacion['nombre']}?' : 'La cuenta seguirá suspendida.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: aprobar ? Colors.green : Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await viewModel.resolverApelacion(apelacion['id'].toString(), apelacion['usuario_id'], aprobar);
            },
            child: Text(aprobar ? 'Desbanear' : 'Rechazar'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ESTRUCTURA DE LA PANTALLA
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PanelAdminViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Supabase.instance.client.auth.signOut())],
      ),
      body: viewModel.estaCargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: () => viewModel.cargarDatosTabActual(), child: _construirCuerpo(viewModel)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: viewModel.indiceTab,
        onTap: viewModel.cambiarTab,
        selectedItemColor: Colors.orange, unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, selectedFontSize: 12, unselectedFontSize: 10,
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
      case 4: return _buildModuloApelaciones(viewModel);
      default: return const Center(child: Text('Vista no encontrada'));
    }
  }

  // ----------------------------------------------------------------------
  // CONSTRUCCIÓN DE LAS LISTAS
  // ----------------------------------------------------------------------

  // ACTUALIZADO: Las solicitudes ahora son tarjetas cliqueables
  Widget _buildSolicitudes(PanelAdminViewModel viewModel) {
    if (viewModel.solicitudesPendientes.isEmpty) return const Center(child: Text('No hay solicitudes pendientes'));
    return ListView.builder(
      itemCount: viewModel.solicitudesPendientes.length,
      itemBuilder: (context, i) {
        final sol = viewModel.solicitudesPendientes[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.storefront, color: Colors.orange, size: 36),
            title: Text(sol['nombre_comercial'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Toca para ver el expediente\nRFC: ${sol['rfc'] ?? 'N/A'}'),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            // Al tocar la tarjeta, se abre el expediente completo
            onTap: () => _mostrarDetallesSolicitud(viewModel, sol),
          ),
        );
      },
    );
  }

  // ACTUALIZADO: El directorio ahora abre el perfil del usuario al tocarlo
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
            leading: CircleAvatar(backgroundColor: estaSuspendido ? Colors.grey : (enPeligro ? Colors.red : Colors.blueGrey), child: Icon(icono, color: Colors.white)),
            title: Text(item['nombre'], style: TextStyle(decoration: estaSuspendido ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['email']), if (reportes > 0) Text('🚨 Reportes: $reportes', style: TextStyle(color: enPeligro ? Colors.red : Colors.orange, fontWeight: FontWeight.bold))]),
            trailing: estaSuspendido ? const Text('BANEADO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : IconButton(icon: const Icon(Icons.block, color: Colors.red), onPressed: () => _confirmarSuspension(viewModel, item)),
            // Al tocar, muestra detalles del usuario
            onTap: () => _mostrarDetallesUsuario(item),
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
                Row(children: [const Icon(Icons.warning, color: Colors.amber), const SizedBox(width: 8), Expanded(child: Text('Motivo: ${rep['motivo']}', style: const TextStyle(fontWeight: FontWeight.bold)))]),
                const Divider(),
                Text('Reportador: ${rep['reportador_email'] ?? 'Desconocido'}'),
                Text('Reportado: ${rep['reportado_email'] ?? 'Desconocido'}', style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuloApelaciones(PanelAdminViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Pendientes'), icon: Icon(Icons.mail)),
              ButtonSegment(value: 1, label: Text('Historial'), icon: Icon(Icons.history)),
            ],
            selected: {viewModel.indiceSubTabApelacion},
            onSelectionChanged: (set) => viewModel.cambiarSubTabApelacion(set.first),
          ),
        ),
        Expanded(child: _buildListaApelaciones(viewModel)),
      ],
    );
  }

  Widget _buildListaApelaciones(PanelAdminViewModel viewModel) {
    final lista = viewModel.indiceSubTabApelacion == 0 ? viewModel.apelacionesPendientes : viewModel.apelacionesHistorico;
    final esHistorial = viewModel.indiceSubTabApelacion == 1;

    if (lista.isEmpty) return Center(child: Text(esHistorial ? 'No hay historial' : 'No hay apelaciones por revisar'));

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final ap = lista[i];
        final estatus = ap['estatus'];

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: esHistorial ? 1 : 4,
          color: esHistorial ? Colors.grey[100] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(esHistorial ? Icons.lock : Icons.mark_email_read, color: esHistorial ? Colors.grey : Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text('De: ${ap['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (esHistorial)
                      Chip(
                        label: Text(estatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: estatus == 'aprobada' ? Colors.green : Colors.red,
                      )
                  ],
                ),
                Text(ap['email'], style: const TextStyle(color: Colors.grey)),
                const Divider(),
                const Text('Justificación:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ap['motivo'], style: const TextStyle(fontStyle: FontStyle.italic)),

                if (!esHistorial) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _confirmarResolucionApelacion(viewModel, ap, true),
                        icon: const Icon(Icons.check_circle), label: const Text('Perdonar'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => _confirmarResolucionApelacion(viewModel, ap, false),
                        icon: const Icon(Icons.cancel), label: const Text('Rechazar'),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
