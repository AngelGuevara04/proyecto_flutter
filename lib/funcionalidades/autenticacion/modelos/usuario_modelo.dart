// Representa la estructura de datos básica de un usuario logueado
class UsuarioModelo {
  final String id;
  final String correo;
  final bool esNegocio;

  UsuarioModelo({
    required this.id,
    required this.correo,
    required this.esNegocio,
  });
}
