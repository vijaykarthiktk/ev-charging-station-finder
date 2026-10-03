import 'package:postgres/postgres.dart';

/// Postgres connection settings. Override per environment with
/// `--dart-define`: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD.
/// Defaults match docker-compose.yml and the Homebrew setup in README.
class DbConfig {
  const DbConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  factory DbConfig.fromEnvironment() => DbConfig(
        host: const String.fromEnvironment('DB_HOST',
            defaultValue: '127.0.0.1'),
        port: int.fromEnvironment('DB_PORT', defaultValue: 5432),
        database: const String.fromEnvironment('DB_NAME',
            defaultValue: 'chargefind'),
        username: const String.fromEnvironment('DB_USER',
            defaultValue: 'chargefind'),
        password: const String.fromEnvironment('DB_PASSWORD',
            defaultValue: 'chargefind'),
      );

  Endpoint get endpoint => Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      );

  ConnectionSettings get settings => const ConnectionSettings(
        connectTimeout: Duration(seconds: 5),
        // Local/dev Postgres runs without TLS certificates; a managed
        // instance with TLS should switch this to SslMode.require.
        sslMode: SslMode.disable,
      );
}
