class UserData {
  final String name;
  final String email;
  final String password;
  final bool isBusiness;

  UserData({
    required this.name,
    required this.email,
    required this.password,
    required this.isBusiness,
  });
}

class UserStorage {
  static final List<UserData> _users = [
    UserData(
      name: 'Cliente Prueba',
      email: 'cliente@gmail.com',
      password: '123',
      isBusiness: false,
    ),
    UserData(
      name: 'Taqueria Prueba',
      email: 'taqueria@gmail.com',
      password: '123',
      isBusiness: true,
    ),
  ];

  static void addUser(UserData user) {
    _users.add(user);
  }

  static UserData? login(String email, String password) {
    try {
      return _users.firstWhere(
        (u) => u.email == email && u.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}
