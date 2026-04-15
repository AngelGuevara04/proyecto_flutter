import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
    Future.microtask(
            () => context.read<PanelAdminViewModel>().cargarDatosTabActual());
  }

  // ── Solicitudes ──
  void _mostrarDetallesSolicitud(
      PanelAdminViewModel viewModel, dynamic solicitud) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.store, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(solicitud['nombre_comercial'] ?? 'Sin nombre',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              Text('Propietario: ${solicitud['propietario'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Text('RFC: ${solicitud['rfc'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Dirección:', style: TextStyle(color: Colors.grey)),
              Text(solicitud['direccion'] ?? 'N/A',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
              const Text('Documentos Adjuntos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Identificación Oficial',
                    style: TextStyle(fontSize: 14)),
                subtitle: const Text('Toca para abrir',
                    style: TextStyle(fontSize: 12)),
                trailing:
                const Icon(Icons.open_in_browser, color: Colors.blue),
                onTap: () =>
                    _abrirEnNavegador(solicitud['url_identificacion']),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Comprobante de Domicilio',
                    style: TextStyle(fontSize: 14)),
                subtitle: const Text('Toca para abrir',
                    style: TextStyle(fontSize: 12)),
                trailing:
                const Icon(Icons.open_in_browser, color: Colors.blue),
                onTap: () => _abrirEnNavegador(
                    solicitud['url_comprobante_domicilio']),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mostrarDialogoRechazoSolicitud(viewModel, solicitud);
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Rechazar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await viewModel.gestionarSolicitud(
                      solicitud['id'].toString(),
                      solicitud['usuario_id'],
                      'aprobado');
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Aprobar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEnNavegador(String? url) async {
    if (url != null && url.startsWith('http')) {
      try {
        await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay archivo válido')));
    }
  }

  void _mostrarDetallesUsuario(dynamic usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Información del Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${usuario['nombre']}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Text('Email: ${usuario['email']}'),
            const SizedBox(height: 8),
            Text(
                'Rol en la App: ${usuario['rol'].toString().toUpperCase()}'),
            Text('Estatus: ${usuario['estatus'].toString().toUpperCase()}'),
            const SizedBox(height: 16),
            if ((usuario['total_reportes'] ?? 0) > 0)
              Text('Reportes Acumulados: ${usuario['total_reportes']}',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ── Detalle completo del reporte ──
  void _mostrarDetalleReporte(dynamic reporte) {
    final totalReportes =
    (reporte['total_reportes_reportado'] ?? 1) as int;
    final esPeligroso = totalReportes >= 10;
    final esBan = totalReportes >= 15;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning,
                color: esBan
                    ? Colors.red
                    : esPeligroso
                    ? Colors.orange
                    : Colors.amber),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Detalle del Reporte',
                    style: TextStyle(fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Usuario reportado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: esBan
                      ? Colors.red.shade50
                      : esPeligroso
                      ? Colors.orange.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: esBan
                          ? Colors.red.shade200
                          : esPeligroso
                          ? Colors.orange.shade200
                          : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usuario Reportado:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(reporte['cliente_email'] ?? 'Desconocido',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          esBan
                              ? Icons.block
                              : esPeligroso
                              ? Icons.warning
                              : Icons.info_outline,
                          size: 16,
                          color: esBan
                              ? Colors.red
                              : esPeligroso
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          esBan
                              ? '⛔ BAN AUTOMÁTICO ($totalReportes reportes)'
                              : '$totalReportes reporte(s) acumulado(s)',
                          style: TextStyle(
                            color: esBan
                                ? Colors.red
                                : esPeligroso
                                ? Colors.orange
                                : Colors.grey,
                            fontWeight: esBan || esPeligroso
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pedido relacionado
              if (reporte['pedido_id'] != null) ...[
                const Text('Pedido relacionado:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  '#${reporte['pedido_id'].toString().substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
              ],

              // Motivo
              const Text('Motivo del reporte:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(reporte['motivo'] ?? 'Sin motivo',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // Detalles
              const Text('Descripción detallada:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                    reporte['detalles'] ?? 'Sin detalles adicionales',
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _mostrarDialogoRechazoSolicitud(
      PanelAdminViewModel viewModel, dynamic solicitud) {
    final controlMotivo = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Explica al taquero qué documentos están mal para que los corrija:'),
            const SizedBox(height: 10),
            TextField(
              controller: controlMotivo,
              maxLines: 3,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                  'Ej. Tu RFC no coincide o la foto es borrosa...'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (controlMotivo.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final error = await viewModel.gestionarSolicitud(
                  solicitud['id'].toString(),
                  solicitud['usuario_id'],
                  'rechazado',
                  controlMotivo.text);
              if (mounted && error != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: const Text('Confirmar Rechazo'),
          ),
        ],
      ),
    );
  }

  void _confirmarSuspension(
      PanelAdminViewModel viewModel, dynamic usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Suspender Cuenta'),
        content:
        Text('¿Estás seguro de suspender a ${usuario['nombre']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  void _confirmarResolucionApelacion(
      PanelAdminViewModel viewModel, dynamic apelacion, bool aprobar) {
    // Si tiene ban permanente no se puede desbanear
    final banPermanente = apelacion['ban_permanente'] == true;
    if (aprobar && banPermanente) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⛔ Desbaneo no permitido'),
          content: const Text(
              'Este usuario fue baneado automáticamente por acumular 15 o más reportes. El desbaneo manual no está disponible para bans permanentes.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            aprobar ? '✅ Aprobar y Desbanear' : '❌ Rechazar Apelación'),
        content: Text(aprobar
            ? '¿Devolver acceso a ${apelacion['nombre']}?'
            : 'La cuenta seguirá suspendida.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: aprobar ? Colors.green : Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await viewModel.resolverApelacion(
                  apelacion['id'].toString(),
                  apelacion['usuario_id'],
                  aprobar);
            },
            child: Text(aprobar ? 'Desbanear' : 'Rechazar'),
          ),
        ],
      ),
    );
  }

  // ── Build principal ──
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PanelAdminViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración',
            style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  Supabase.instance.client.auth.signOut())
        ],
      ),
      body: viewModel.estaCargando
          ? const Center(
          child: CircularProgressIndicator(color: Colors.blueGrey))
          : RefreshIndicator(
          onRefresh: () => viewModel.cargarDatosTabActual(),
          child: _construirCuerpo(viewModel)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: viewModel.indiceTab,
        onTap: viewModel.cambiarTab,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.approval), label: 'Nuevos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront), label: 'Negocios'),
          BottomNavigationBarItem(
              icon: Icon(Icons.report_problem), label: 'Reportes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.forum), label: 'Apelación'),
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

  Widget _buildSolicitudes(PanelAdminViewModel viewModel) {
    if (viewModel.solicitudesPendientes.isEmpty) {
      return const Center(
          child: Text('No hay solicitudes pendientes',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: viewModel.solicitudesPendientes.length,
      itemBuilder: (context, i) {
        final sol = viewModel.solicitudesPendientes[i];
        return Card(
          margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.storefront,
                color: Colors.orange, size: 36),
            title: Text(sol['nombre_comercial'] ?? 'Sin nombre',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Toca para ver el expediente\nRFC: ${sol['rfc'] ?? 'N/A'}'),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.grey, size: 16),
            onTap: () => _mostrarDetallesSolicitud(viewModel, sol),
          ),
        );
      },
    );
  }

  Widget _buildDirectorio(PanelAdminViewModel viewModel,
      List<dynamic> lista, IconData icono) {
    if (lista.isEmpty) {
      return const Center(
          child: Text('No hay registros',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final item = lista[i];
        final bool estaSuspendido = item['suspendido'] == true;
        final int reportes = item['total_reportes'] ?? 0;
        final bool enPeligro = reportes >= 10;
        final bool esBan = reportes >= 15;

        return Card(
          color: estaSuspendido
              ? Colors.grey[300]
              : (esBan
              ? Colors.red[100]
              : enPeligro
              ? Colors.red[50]
              : Colors.white),
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: estaSuspendido
                    ? Colors.grey
                    : (esBan
                    ? Colors.red
                    : enPeligro
                    ? Colors.orange
                    : Colors.blueGrey),
                child: Icon(icono, color: Colors.white)),
            title: Text(item['nombre'] ?? 'Desconocido',
                style: TextStyle(
                    decoration: estaSuspendido
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.bold)),
            subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['email'] ?? ''),
                  if (reportes > 0)
                    Text(
                      esBan
                          ? '⛔ BAN AUTOMÁTICO ($reportes reportes)'
                          : '🚨 Reportes: $reportes',
                      style: TextStyle(
                          color: esBan ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.bold),
                    )
                ]),
            trailing: estaSuspendido
                ? const Text('BANEADO',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold))
                : IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () =>
                    _confirmarSuspension(viewModel, item)),
            onTap: () => _mostrarDetallesUsuario(item),
          ),
        );
      },
    );
  }

  // ── Reportes: solo muestra al reportado con detalles ──
  Widget _buildReportes(PanelAdminViewModel viewModel) {
    if (viewModel.reportes.isEmpty) {
      return const Center(
          child: Text('Cero reportes. Todo tranquilo.',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: viewModel.reportes.length,
      itemBuilder: (context, i) {
        final rep = viewModel.reportes[i];
        final totalReportes =
        (rep['total_reportes_reportado'] ?? 1) as int;
        final esBan = totalReportes >= 15;
        final esPeligroso = totalReportes >= 10;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: esBan
              ? Colors.red.shade50
              : esPeligroso
              ? Colors.orange.shade50
              : Colors.white,
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: esBan
                  ? Colors.red
                  : esPeligroso
                  ? Colors.orange
                  : Colors.amber,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              rep['cliente_email'] ?? 'Desconocido',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motivo: ${rep['motivo'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  esBan
                      ? '⛔ BAN AUTOMÁTICO — $totalReportes reportes'
                      : '📊 $totalReportes reporte(s) acumulado(s)',
                  style: TextStyle(
                    color: esBan
                        ? Colors.red
                        : esPeligroso
                        ? Colors.orange
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () => _mostrarDetalleReporte(rep),
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
              ButtonSegment(
                  value: 0,
                  label: Text('Pendientes'),
                  icon: Icon(Icons.mail)),
              ButtonSegment(
                  value: 1,
                  label: Text('Historial'),
                  icon: Icon(Icons.history)),
            ],
            selected: {viewModel.indiceSubTabApelacion},
            onSelectionChanged: (set) =>
                viewModel.cambiarSubTabApelacion(set.first),
          ),
        ),
        Expanded(child: _buildListaApelaciones(viewModel)),
      ],
    );
  }

  Widget _buildListaApelaciones(PanelAdminViewModel viewModel) {
    final lista = viewModel.indiceSubTabApelacion == 0
        ? viewModel.apelacionesPendientes
        : viewModel.apelacionesHistorico;
    final esHistorial = viewModel.indiceSubTabApelacion == 1;

    if (lista.isEmpty) {
      return Center(
          child: Text(
              esHistorial
                  ? 'No hay historial'
                  : 'No hay apelaciones por revisar',
              style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final ap = lista[i];
        final estatus = ap['estatus'] ?? 'desconocido';
        final banPermanente = ap['ban_permanente'] == true;

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
                    Icon(
                        esHistorial
                            ? Icons.lock
                            : Icons.mark_email_read,
                        color:
                        esHistorial ? Colors.grey : Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('De: ${ap['nombre'] ?? 'Usuario'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16))),
                    if (esHistorial)
                      Chip(
                        label: Text(estatus.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                        backgroundColor:
                        estatus == 'aprobada'
                            ? Colors.green
                            : Colors.red,
                      ),
                    // Indicador de ban permanente
                    if (banPermanente)
                      const Chip(
                        label: Text('BAN PERM.',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10)),
                        backgroundColor: Colors.red,
                      ),
                  ],
                ),
                Text(ap['email'] ?? 'Sin email',
                    style: const TextStyle(color: Colors.grey)),

                // Advertencia de ban permanente
                if (banPermanente) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                        Border.all(color: Colors.red.shade200)),
                    child: const Row(
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Ban permanente por 15+ reportes. El desbaneo manual no está disponible.',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(),
                const Text('Justificación:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ap['motivo'] ?? 'Sin justificación',
                    style: const TextStyle(fontStyle: FontStyle.italic)),

                if (!esHistorial) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Si tiene ban permanente el botón de perdonar está deshabilitado
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: banPermanente
                                ? Colors.grey
                                : Colors.green,
                            foregroundColor: Colors.white),
                        onPressed: banPermanente
                            ? () => _confirmarResolucionApelacion(
                            viewModel, ap, true)
                            : () => _confirmarResolucionApelacion(
                            viewModel, ap, true),
                        icon: Icon(
                            banPermanente ? Icons.block : Icons.check_circle,
                            size: 16),
                        label: Text(
                            banPermanente ? 'No disponible' : 'Perdonar'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white),
                        onPressed: () => _confirmarResolucionApelacion(
                            viewModel, ap, false),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Rechazar'),
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