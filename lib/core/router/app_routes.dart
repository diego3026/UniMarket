// lib/core/router/app_routes.dart
//
// Todas las rutas de la app en un solo lugar.
// Usa `context.go(...)` para cambiar de sección y `context.push(...)` para
// abrir una pantalla encima (con botón atrás).
class AppRoutes {
  AppRoutes._();

  // ── Acceso ────────────────────────────────────────────────
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const recoverPassword = '/recover-password';
  static const confirmEmail = '/confirm-email';

  // ── Cliente (pestañas) ────────────────────────────────────
  static const home = '/home';
  static const promos = '/promos';
  static const orders = '/orders';
  static const favorites = '/favorites';

  // ── Cliente (pantallas) ───────────────────────────────────
  static const search = '/search';
  static const notifications = '/notifications';
  static const product = '/product/:id';
  static String productPath(String id) => '/product/$id';
  static const store = '/store/:id';
  static String storePath(String id) => '/store/$id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderTracking = '/order/:id';
  static String orderTrackingPath(String id) => '/order/$id';
  static const orderSuccess = '/order/:id/success';
  static String orderSuccessPath(String id) => '/order/$id/success';
  static const orderReview = '/order/:id/review';
  static String orderReviewPath(String id) => '/order/$id/review';

  // ── Perfil y ajustes (todos los roles) ────────────────────
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const addresses = '/addresses';
  static const addAddress = '/addresses/new';
  static const mapAddress = '/addresses/map';
  static const paymentMethods = '/payment-methods';
  static const settings = '/settings';
  static const settingsApp = '/settings/app';
  static const settingsOrders = '/settings/orders';
  static const settingsNotifications = '/settings/notifications';
  static const settingsPrivacy = '/settings/privacy';
  static const becomeSeller = '/become-seller';
  static const help = '/help';

  // ── Emprendedor ───────────────────────────────────────────
  static const sellerHome = '/seller';
  static const sellerMenu = '/seller/menu';
  static const sellerPromos = '/seller/promos';
  static const sellerPromoForm = '/seller/promo-form';
  static const sellerSettings = '/seller/settings';
  static const sellerStats = '/seller/stats';
  static const sellerProfile = '/seller/profile';
  static const sellerNewProduct = '/seller/products/new';
  static const sellerSchedule = '/seller/schedule';
  static const sellerBank = '/seller/bank';
  static const sellerDocuments = '/seller/documents';
  static const sellerManagement = '/seller/management';

  // ── Administrador ─────────────────────────────────────────
  static const adminHome = '/admin';
  static const adminUsers = '/admin/users';
  static const adminBusinesses = '/admin/businesses';
  static const adminReports = '/admin/reports';
  static const adminProducts = '/admin/products';

  static const publicRoutes = {
    onboarding,
    login,
    register,
    recoverPassword,
    confirmEmail,
  };
}
