enum AppEnv {
  development,
  staging,
  production,
}

class Env {
  static const AppEnv current = AppEnv.development;
}
