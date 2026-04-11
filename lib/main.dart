import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// 1. Importamos las Vistas Clásicas
import 'funcionalidades/autenticacion/vistas/pantalla_login.dart';
import 'funcionalidades/autenticacion/vistas/pantalla_registro.dart';
import 'funcionalidades/cliente/vistas/pantalla_inicio_cliente.dart';
import 'funcionalidades/negocio/vistas/pantalla_inicio_negocio.dart';
import 'funcionalidades/perfil/vistas/pantalla_perfil.dart';

// 2. Importamos las NUEVAS Vistas de Admin y Validación
import 'funcionalidades/validacion_negocio/vistas/pantalla_subir_documentos.dart';
import 'funcionalidades/validacion_negocio/vistas/pantalla_en_revision.dart';
import 'funcionalidades/administrador/vistas/pantalla_panel_admin.dart';

// 3. Importamos los ViewModels Clásicos
import 'funcionalidades/autenticacion/vista_modelos/login_view_model.dart';
import 'funcionalidades/autenticacion/vista_modelos/registro_view_model.dart';
import 'funcionalidades/cliente/vista_modelos/inicio_cliente_view_model.dart';
import 'funcionalidades/negocio/vista_modelos/inicio_negocio_view_model.dart';
import 'funcionalidades/perfil/vista_modelos/perfil_view_model.dart';

// 4. Importamos los NUEVOS ViewModels
import 'funcionalidades/validacion_negocio/vista_modelos/subir_documentos_view_model.dart';
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
    // Obtenemos la sesión actual
    final sesion = Supabase.instance.client.auth.currentSession;
    final usuario = Supabase.instance.client.auth.currentUser;

    String rutaInicial = '/';

    if (sesion != null && usuario != null) {
      final metadatos = usuario.userMetadata ?? {};

      final rol = metadatos['rol']?.toString() ?? 'usuario';
      final estatusAprobacion = metadatos['estatus_aprobacion']?.toString();

      if (rol == 'admin') {
        rutaInicial = '/admin';
      } else if (rol == 'negocio') {
        if (estatusAprobacion == 'aprobado') {
          rutaInicial = '/home_negocio';
        } else if (estatusAprobacion == 'pendiente') {
          rutaInicial = '/en_revision';
        } else {
          rutaInicial = '/subir_documentos';
        }
      } else {
        rutaInicial = '/home';
      }
    }

    return MaterialApp(
      key: ValueKey(rutaInicial),
      debugShowCheckedModeBanner: false,
      title: 'TacoHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: rutaInicial,
      routes: {
        // Rutas de Autenticación
        '/': (context) => ChangeNotifierProvider(
          create: (_) => LoginViewModel(),
          child: const PantallaLogin(),
        ),
        '/registro': (context) => ChangeNotifierProvider(
          create: (_) => RegistroViewModel(),
          child: const PantallaRegistro(),
        ),

        // Rutas de Cliente y Perfil
        '/home': (context) => ChangeNotifierProvider(
          create: (_) => InicioClienteViewModel(),
          child: const PantallaInicioCliente(),
        ),
        '/perfil': (context) => ChangeNotifierProvider(
          create: (_) => PerfilViewModel(),
          child: const PantallaPerfil(),
        ),

        // Rutas de Taquería (Ya aprobada)
        '/home_negocio': (context) => ChangeNotifierProvider(
          create: (_) => InicioNegocioViewModel(),
          child: const PantallaInicioNegocio(),
        ),

        // NUEVAS RUTAS: Validación en el "Limbo"
        '/subir_documentos': (context) => ChangeNotifierProvider(
          create: (_) => SubirDocumentosViewModel(),
          child: const PantallaSubirDocumentos(),
        ),
        '/en_revision': (context) => const PantallaEnRevision(), // No necesita ViewModel

        // NUEVA RUTA: Administrador
        '/admin': (context) => ChangeNotifierProvider(
          create: (_) => PanelAdminViewModel(),
          child: const PantallaPanelAdmin(),
        ),
      },
    );
  }
}