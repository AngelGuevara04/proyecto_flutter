import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/completar_perfil_view_model.dart';

class PantallaCompletarPerfil extends StatefulWidget {
  const PantallaCompletarPerfil({super.key});

  @override
  State<PantallaCompletarPerfil> createState() => _PantallaCompletarPerfilState();
}

class _PantallaCompletarPerfilState extends State<PantallaCompletarPerfil> {
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();

  final _usuarioRedCtrl = TextEditingController();
  String _plataformaSeleccionada = 'Facebook';
  final List<String> _opcionesPlataformas = ['Facebook', 'Instagram', 'TikTok', 'X (Twitter)', 'WhatsApp'];

  bool _confirmaEfectivo = false;

  @override
  void dispose() {
    _telefonoCtrl.dispose(); _correoCtrl.dispose(); _tiempoCtrl.dispose(); _usuarioRedCtrl.dispose();
    super.dispose();
  }

  void _guardar(CompletarPerfilViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    final error = await viewModel.guardarPerfil(
        _telefonoCtrl.text.trim(), _correoCtrl.text.trim(), _tiempoCtrl.text.trim(), _confirmaEfectivo
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      await Supabase.instance.client.auth.refreshSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompletarPerfilViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configura tu Taquería'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personaliza tu perfil comercial para aparecer en el mapa.', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
            const Divider(height: 30),

            // 1. FOTOS DEL LOCAL
            const Text('Fotos del Local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Mínimo 2 de interior y 1 de exterior', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: viewModel.fotoExterior != null ? Colors.green : Colors.orange,
                side: BorderSide(color: viewModel.fotoExterior != null ? Colors.green : Colors.orange),
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: viewModel.seleccionarFotoExterior,
              icon: Icon(viewModel.fotoExterior != null ? Icons.check_circle : Icons.camera_alt),
              label: Text(viewModel.fotoExterior != null ? 'Foto Exterior Lista' : 'Subir 1 Foto Exterior'),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: viewModel.fotosInterior.length >= 2 ? Colors.green : Colors.orange,
                side: BorderSide(color: viewModel.fotosInterior.length >= 2 ? Colors.green : Colors.orange),
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: viewModel.seleccionarFotosInterior,
              icon: Icon(viewModel.fotosInterior.length >= 2 ? Icons.check_circle : Icons.photo_library),
              label: Text('Subir Fotos Interior (${viewModel.fotosInterior.length}/2)'),
            ),
            if (viewModel.fotosInterior.isNotEmpty)
              ...viewModel.fotosInterior.asMap().entries.map((entry) => ListTile(
                dense: true,
                leading: const Icon(Icons.image, size: 20),
                title: Text('Foto Interior ${entry.key + 1}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => viewModel.eliminarFotoInterior(entry.key),
                ),
              )),

            const Divider(height: 40),

            // 2. CONTACTO Y ENTREGAS
            const Text('Contacto y Tiempos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),

            TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Número de Teléfono Móvil',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _correoCtrl, decoration: const InputDecoration(labelText: 'Correo Público (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _tiempoCtrl, decoration: const InputDecoration(labelText: 'Tiempo de Preparación/Entrega (Ej. 20 min)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer))),

            const Divider(height: 40),

            // 3. REDES SOCIALES (CON LA CORRECCIÓN DEL OVERFLOW)
            const Text('Redes Sociales (Opcionales)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true, // <--- MAGIA 1: Evita que el contenedor crezca más de la cuenta
                    value: _plataformaSeleccionada,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: _opcionesPlataformas.map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, overflow: TextOverflow.ellipsis) // <--- MAGIA 2: Pone "..." si el texto es muy largo
                    )).toList(),
                    onChanged: (val) => setState(() => _plataformaSeleccionada = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _usuarioRedCtrl,
                    decoration: const InputDecoration(labelText: 'Usuario / Link', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero, // <--- Ayuda a ganar unos píxeles extra
                  icon: const Icon(Icons.add_circle, color: Colors.orange, size: 36),
                  onPressed: () {
                    viewModel.agregarRedSocial(_plataformaSeleccionada, _usuarioRedCtrl.text);
                    _usuarioRedCtrl.clear();
                  },
                ),
              ],
            ),

            if (viewModel.redesSociales.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: viewModel.redesSociales.asMap().entries.map((entry) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.link, color: Colors.blue),
                    title: Text('${entry.value['plataforma']}: ${entry.value['usuario']}'),
                    trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => viewModel.eliminarRedSocial(entry.key)),
                  )).toList(),
                ),
              ),

            const Divider(height: 40),

            // 4. CONFIRMACIÓN
            CheckboxListTile(
              title: const Text('Confirmo que los cobros se realizarán en Efectivo al entregar el pedido.', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _confirmaEfectivo,
              activeColor: Colors.orange,
              onChanged: (val) => setState(() => _confirmaEfectivo = val ?? false),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(55)),
              onPressed: viewModel.estaCargando ? null : () => _guardar(viewModel),
              child: viewModel.estaCargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Finalizar y Abrir Taquería', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}