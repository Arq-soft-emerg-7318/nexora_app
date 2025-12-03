class AppConfig {
  // Base URL para API backend
  static String apiBase = 'http://192.168.18.157:8080';

  // Endpoint para el servicio de IA (generador)
  static String aiBase = 'http://192.168.18.157:3000';

  // Optional keys for local development ONLY. Do NOT check real keys into source control.
  // These are intended for quick local testing; prefer using environment variables for servers.
  static String? groqKey;
  static String? hfToken;

  static void setGroqKey(String key) => groqKey = key;
  static void setHfToken(String token) => hfToken = token;

  /// Cambiar en tiempo de ejecución si es necesario (por ejemplo para pruebas)
  static void setApiBase(String url) => apiBase = url;
  static void setAiBase(String url) => aiBase = url;
}
