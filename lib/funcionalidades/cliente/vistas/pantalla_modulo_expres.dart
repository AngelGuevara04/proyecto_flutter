import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/expres_view_model.dart';
import '../vista_modelos/pedido_cliente_view_model.dart';
import 'pantalla_rastrear_pedido.dart';

class PantallaModuloExpres extends StatefulWidget {
  // Parámetros opcionales para cuando viene de un pedido rechazado
  final String descripcionInicial;
  final String direccionInicial;
  final String referenciasInicial;
  final String telefonoInicial;

  const PantallaModuloExpres({
    super.key,
    this.descripcionInicial = '',
    this.direccionInicial = '',
    this.referenciasInicial = '',
    this.telefonoInicial = '',
  });

  @override
  State<PantallaModuloExpres> createState() =>
      _PantallaModuloExpresState();
}

class _PantallaModuloExpresState extends State<PantallaModuloExpres> {
  late TextEditingController _descripcionCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _referenciasCtrl;
  late TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl =
        TextEditingController(text: widget.descripcionInicial);
    _telefonoCtrl =
        TextEditingController(text: widget.telefonoInicial);
    _referenciasCtrl =
        TextEditingController(text: widget.referenciasInicial);

    // Dirección: usar la del pedido rechazado o la del perfil
    if (widget.direccionInicial.isNotEmpty) {
      _direccionCtrl =
          TextEditingController(text: widget.direccionInicial);
    } else {
      final meta =
          Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
      final calle = meta['calle'] ?? '';
      final colonia = meta['colonia'] ?? '';
      final ciudad = meta['ciudad'] ?? '';
      _direccionCtrl = TextEditingController(
          text: calle.isNotEmpty
              ? '$calle, $colonia, $ciudad'.trim()
              : '');
    }

    Future.microtask(
            () => context.read<ExpresViewModel>().obtenerUbicacion());
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _direccionCtrl.dispose();
    _referenciasCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpresViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Exprés ⚡'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.deepOrange, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Describe lo que quieres y la primera taquería disponible cerca de ti lo tomará.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ubicación status
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: vm.tieneUbicacion
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    vm.tieneUbicacion
                        ? Icons.location_on
                        : Icons.location_off,
                    color:
                    vm.tieneUbicacion ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vm.tieneUbicacion
                        ? 'Ubicación obtenida ✅'
                        : vm.estaCargando
                        ? 'Obteniendo ubicación...'
                        : 'Sin ubicación',
                    style: TextStyle(
                      color:
                      vm.tieneUbicacion ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!vm.tieneUbicacion && !vm.estaCargando)
                    TextButton(
                      onPressed: () => vm.obtenerUbicacion(),
                      child: const Text('Reintentar',
                          style: TextStyle(color: Colors.deepOrange)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Descripción
            const Text('¿Qué quieres ordenar?',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                'Ej. 5 tacos de pastor con todo, 2 quesadillas...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Datos entrega
            const Text('Datos de entrega',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.location_on, color: Colors.deepOrange),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenciasCtrl,
              decoration: const InputDecoration(
                labelText: 'Referencias (opcional)',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.info_outline, color: Colors.deepOrange),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Número de contacto (10 dígitos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone, color: Colors.deepOrange),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Pago en efectivo al recibir.',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: vm.estaCargando
                  ? null
                  : () async {
                // Validar teléfono
                final tel = _telefonoCtrl.text.trim();
                if (tel.length != 10 ||
                    !RegExp(r'^[0-9]+$').hasMatch(tel)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'El número de teléfono debe tener exactamente 10 dígitos'),
                          backgroundColor: Colors.red));
                  return;
                }

                final error = await vm.crearPedidoExpres(
                  descripcion: _descripcionCtrl.text,
                  direccionEntrega: _direccionCtrl.text,
                  referencias: _referenciasCtrl.text,
                  telefonoContacto: tel,
                );
                if (!mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red));
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => PedidoClienteViewModel(),
                        child: PantallaRastrearPedido(
                            pedidoId: vm.pedidoActivoId!),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flash_on),
              label: vm.estaCargando
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Buscar taquería exprés',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}