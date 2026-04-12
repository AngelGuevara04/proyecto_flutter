import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/subir_documentos_view_model.dart';

class PantallaSubirDocumentos extends StatefulWidget {
  const PantallaSubirDocumentos({super.key});

  @override
  State<PantallaSubirDocumentos> createState() => _PantallaSubirDocumentosState();
}

class _PantallaSubirDocumentosState extends State<PantallaSubirDocumentos> {
  final _nombreCtrl = TextEditingController();
  final _propietarioCtrl = TextEditingController();
  final _rfcCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final vm = context.read<SubirDocumentosViewModel>();
      await vm.cargarSolicitudPrevia();
      if (vm.solicitudPrevia != null) {
        _nombreCtrl.text = vm.solicitudPrevia!['nombre_comercial'] ?? '';
        _propietarioCtrl.text = vm.solicitudPrevia!['propietario'] ?? '';
        _rfcCtrl.text = vm.solicitudPrevia!['rfc'] ?? '';
        _direccionCtrl.text = vm.solicitudPrevia!['direccion'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _propietarioCtrl.dispose(); _rfcCtrl.dispose(); _direccionCtrl.dispose();
    super.dispose();
  }

  void _enviar(SubirDocumentosViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    final error = await viewModel.enviarSolicitudFase1(
      _nombreCtrl.text.trim(), _propietarioCtrl.text.trim(),
      _rfcCtrl.text.trim(), _direccionCtrl.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      await Supabase.instance.client.auth.refreshSession();
    }
  }

  Widget _botonArchivo(String titulo, bool tieneArchivoNuevo, bool tieneArchivoViejo, VoidCallback alPresionar) {
    // Lógica para saber si está listo
    final estaListo = tieneArchivoNuevo || tieneArchivoViejo;
    String texto = 'Subir $titulo';
    if (tieneArchivoNuevo) texto = 'Archivo Nuevo Seleccionado';
    else if (tieneArchivoViejo) texto = 'Archivo Anterior Guardado (Toca para cambiar)';

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: estaListo ? Colors.green : Colors.blueGrey,
        side: BorderSide(color: estaListo ? Colors.green : Colors.blueGrey),
        minimumSize: const Size.fromHeight(50),
      ),
      icon: Icon(estaListo ? Icons.check_circle : Icons.upload_file),
      label: Text(texto, textAlign: TextAlign.center),
      onPressed: alPresionar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubirDocumentosViewModel>();

    // Revisamos si ya había un archivo en la base de datos
    final tieneIdVieja = viewModel.solicitudPrevia?['url_identificacion'] != null;
    final tieneCompViejo = viewModel.solicitudPrevia?['url_comprobante_domicilio'] != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud (Fase 1)')),
      body: viewModel.estaCargando && viewModel.solicitudPrevia == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (viewModel.esRechazado)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Solicitud Rechazada', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          Text(viewModel.motivoRechazo, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('Completa tus datos legales para la revisión.', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 20),
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Comercial', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _propietarioCtrl, decoration: const InputDecoration(labelText: 'Nombre del Propietario', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _rfcCtrl, decoration: const InputDecoration(labelText: 'RFC', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _direccionCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Dirección Completa', border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // BOTONES CONECTADOS AL SELECTOR DE ARCHIVOS
            _botonArchivo(
              'Identificación Oficial',
              viewModel.archivoIdentificacion != null,
              tieneIdVieja,
                  () => viewModel.seleccionarArchivo(true), // TRUE = Es ID
            ),
            const SizedBox(height: 12),
            _botonArchivo(
              'Comprobante de Domicilio',
              viewModel.archivoComprobante != null,
              tieneCompViejo,
                  () => viewModel.seleccionarArchivo(false), // FALSE = Es Comprobante
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
              onPressed: viewModel.estaCargando ? null : () => _enviar(viewModel),
              child: viewModel.estaCargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar para revisión'),
            ),
          ],
        ),
      ),
    );
  }
}