import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// Vistas
import 'funcionalidades/autenticacion/vistas/pantalla_login.dart';
import 'funcionalidades/autenticacion/vistas/pantalla_registro.dart';
import 'funcionalidades/autenticacion/vistas/pantalla_recuperar_contrasena.dart';
import 'funcionalidades/autenticacion/vistas/pantalla_cuenta_suspendida.dart';
import 'funcionalidades/cliente/vistas/pantalla_inicio_cliente.dart';
import 'funcionalidades/negocio/vistas/pantalla_inicio_negocio.dart';
import 'funcionalidades/perfil/vistas/pantalla_perfil.dart';
import 'funcionalidades/validacion_negocio/vistas/pantalla_subir_documentos.dart';
import 'funcionalidades/validacion_negocio/vistas/pantalla_en_revision.dart';
import 'funcionalidades/validacion_negocio/vistas/pantalla_completar_perfil.dart'; // NUEVO IMPORT
import 'funcionalidades/administrador/vistas/pantalla_panel_admin.dart';

// ViewModels
import 'funcionalidades/autenticacion/vista_modelos/login_view_model.dart';
import 'funcionalidades/autenticacion/vista_modelos/registro_view_model.dart';
import 'funcionalidades/autenticacion/vista_modelos/recuperar_contrasena_view_model.dart';
import 'funcionalidades/autenticacion/vista_modelos/apelacion_view_model.dart';
import 'funcionalidades/cliente/vista_modelos/inicio_cliente_view_model.dart';
import 'funcionalidades/negocio/vista_modelos/inicio_negocio_view_model.dart';
import 'funcionalidades/perfil/vista_modelos/perfil_view_model.dart';
import 'funcionalidades/validacion_negocio/vista_modelos/subir_documentos_view_model.dart';
import 'funcionalidades/validacion_negocio/vista_modelos/completar_perfil_view_model.dart'; // NUEVO IMPORT
import 'funcionalidades/administrador/vista_modelos/panel_admin_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qrzbpuzkcoenjxdheeus.supabase.co',
    anonKey: 'sb_publishable_PsgT7XI44o5qftL8Pp4J3Q_bVlovTXX',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TacoHub',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const SemaforoPrincipal(),
        '/registro': (context) => ChangeNotifierProvider(create: (_) => RegistroViewModel(), child: const PantallaRegistro()),
        '/recuperar_contrasena': (context) => ChangeNotifierProvider(create: (_) => RecuperarContrasenaViewModel(), child: const PantallaRecuperarContrasena()),
        '/perfil': (context) => ChangeNotifierProvider(create: (_) => PerfilViewModel(), child: const PantallaPerfil()),
      },
    );
  }
}

class SemaforoPrincipal extends StatelessWidget {
  const SemaforoPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final session = snapshot.data?.session;
        final user = session?.user;

        if (session != null && user != null) {
          final metadatos = user.userMetadata ?? {};
          final rol = metadatos['rol']?.toString() ?? 'usuario';
          final estatusAprobacion = metadatos['estatus_aprobacion']?.toString();
          final perfilCompletado = metadatos['perfil_completado'] == true; // NUEVA LECTURA
          final suspendido = metadatos['suspendido'] == true;

          if (suspendido) return ChangeNotifierProvider(create: (_) => ApelacionViewModel(), child: const PantallaCuentaSuspendida());

          if (rol == 'admin') {
            return ChangeNotifierProvider(create: (_) => PanelAdminViewModel(), child: const PantallaPanelAdmin());
          }
          else if (rol == 'negocio') {
            if (estatusAprobacion == 'aprobado') {
              // AQUÍ ESTÁ LA MAGIA: Si está aprobado pero no completó perfil, lo frena.
              if (perfilCompletado) {
                return ChangeNotifierProvider(create: (_) => InicioNegocioViewModel(), child: const PantallaInicioNegocio());
              } else {
                return ChangeNotifierProvider(create: (_) => CompletarPerfilViewModel(), child: const PantallaCompletarPerfil());
              }
            } else if (estatusAprobacion == 'pendiente') {
              return const PantallaEnRevision();
            } else {
              return ChangeNotifierProvider(create: (_) => SubirDocumentosViewModel(), child: const PantallaSubirDocumentos());
            }
          }
          else {
            return ChangeNotifierProvider(create: (_) => InicioClienteViewModel(), child: const PantallaInicioCliente());
          }
        }
        return ChangeNotifierProvider(create: (_) => LoginViewModel(), child: const PantallaLogin());
      },
    );
  }
}