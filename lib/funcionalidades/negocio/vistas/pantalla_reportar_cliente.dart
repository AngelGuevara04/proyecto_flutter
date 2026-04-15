import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/inicio_negocio_view_model.dart';

class PantallaReportarCliente extends StatefulWidget {
  // Ahora la pantalla exige que le pasemos el pedido que vamos a reportar
  final Map<String, dynamic> pedidoActivo;

  const PantallaReportarCliente({super.key, required this.pedidoActivo});

  @override
  State<PantallaReportarCliente> createState() => _PantallaReportarClienteState();
}

class _PantallaReportarClienteState extends State<PantallaReportarCliente> {
  final _formKey = GlobalKey<FormState>();
  final _detallesCtrl = TextEditingController();

  String _motivo = 'No pagó el pedido';

  void _enviarReporte() async {
    if (_formKey.currentState!.validate()) {
      final vm = context.read<InicioNegocioViewModel>();

      final error = await vm.levantarReporte(
        pedidoId: widget.pedidoActivo['id'],
        clienteEmail: widget.pedidoActivo['cliente_email'] ?? 'correo_desconocido@app.com',
        motivo: _motivo,
        detalles: _detallesCtrl.text.trim(),
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reporte enviado a Soporte. Este usuario será investigado.'), backgroundColor: Colors.green)
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioNegocioViewModel>();
    final nombre = widget.pedidoActivo['nombre_cliente'];
    final correo = widget.pedidoActivo['cliente_email'] ?? 'No disponible';
    final idTicket = widget.pedidoActivo['id'].toString().substring(0, 5).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Incidente'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: vm.estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Icon(Icons.security, size: 60, color: Colors.red)),
              const SizedBox(height: 16),
              const Text('¿Tuviste un problema con este cliente?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Tu seguridad es primero. Al enviar este reporte, nuestro sistema registrará el correo inmutable de este usuario para una posible suspensión de la plataforma.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // Tarjeta no editable con los datos extraídos automáticamente
              Card(
                color: Colors.red.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Datos del Infractor (Capturados)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const Divider(color: Colors.redAccent),
                      Text('Pedido: #$idTicket', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Nombre: $nombre'),
                      Text('Correo (ID Fijo): $correo', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _motivo,
                decoration: const InputDecoration(labelText: 'Motivo principal', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'No pagó el pedido', child: Text('No pagó el pedido')),
                  DropdownMenuItem(value: 'Dirección falsa / No abrió', child: Text('Dirección falsa / No abrió')),
                  DropdownMenuItem(value: 'Agresión verbal o física', child: Text('Agresión verbal o física')),
                  DropdownMenuItem(value: 'Pedido de broma / Falso', child: Text('Pedido de broma / Falso')),
                  DropdownMenuItem(value: 'Otro problema', child: Text('Otro problema')),
                ],
                onChanged: (val) => setState(() => _motivo = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _detallesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Cuéntanos qué pasó (Detalles)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Por favor, danos detalles de lo ocurrido' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _enviarReporte,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enviar Reporte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}