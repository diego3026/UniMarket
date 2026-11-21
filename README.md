# UNIMARKET

Aplicación móvil (Flutter) del marketplace de emprendedores de la Universidad del Magdalena.
El backend es una API en FastAPI (repositorio `BackEnd-Unimarket`, prefijo `/api/v1`).

## Ejecutar

```bash
flutter pub get
flutter run
```

### Modo demo (sin backend)
En el login hay accesos rápidos **Cliente**, **Emprendedor** y **Admin**. También puedes escribir:

| Rol | Usuario | Contraseña |
|---|---|---|
| Cliente | `1234` | `1234` |
| Emprendedor | `emp` | `emp` |
| Admin | `admin` | `admin` |

La sesión se guarda en el dispositivo; usa **Perfil → Cerrar sesión** para cambiar de rol.

## Diseño

- Tema global en `lib/core/theme/app_theme.dart` y colores en `lib/constants/app_colors.dart`
  (morado `#4320A2` + amarillo `#F2C849` para el cliente, naranja `#FF8A00` para el emprendedor, según el Figma).
- Tipografía: Plus Jakarta Sans (`google_fonts`).
- Componentes reutilizables en `lib/presentation/widgets/ui/` (tarjetas de producto y tienda, banners,
  chips, estados vacíos, selector de cantidad, etc.).
- Datos de ejemplo (emprendimientos y productos en COP) en `lib/data/datasources/mock/catalog_mock_data.dart`.

## Navegación

Toda la navegación está en `lib/core/router/` con `go_router`:
- `app_routes.dart`: lista de rutas.
- `app_router.dart`: pantallas de cada ruta y redirecciones (onboarding → login → inicio según rol).

Usa `context.go(AppRoutes.x)` para cambiar de sección y `context.push(AppRoutes.x)` para abrir encima.

| Rol | Barra inferior | Pantallas que se abren encima |
|---|---|---|
| Acceso | — | Onboarding, Login, Registro, Recuperar contraseña, Confirmar correo |
| Cliente | Inicio · Promos · **Bolsa** · Pedidos · Favoritos | Búsqueda, Tienda, Producto, Bolsa, Checkout, Pago, Confirmación, Detalle/Seguimiento/Calificar pedido, Notificaciones, Perfil, Editar perfil, Direcciones, Métodos de pago, Ajustes (+4 subpantallas), Quiero ser emprendedor/a, Ayuda |
| Emprendedor | Tienda · Menú · Ganancias · Perfil | Crear producto, Horario, Datos bancarios, Documentos, Gestión del negocio |
| Admin | Panel · Usuarios · Negocios · Reportes | Gestionar productos, Perfil |

## Google Maps

Solo la pantalla de agregar dirección usa Google Maps; los demás mapas son un mapa ilustrado
del campus que no necesita clave. Para activarlo agrega `MAPS_API_KEY=...` en
`android/local.properties`. Paso a paso en [`docs/CONFIGURAR_MAPAS.md`](docs/CONFIGURAR_MAPAS.md).

## Pruebas

```bash
flutter test
```

`test/market_test.dart` cubre promociones, cupones, flujo de pedidos y bolsa.

## Estructura

- `lib/core/`: router, tema, inyección de dependencias (GetIt), utilidades.
- `lib/domain/` y `lib/data/`: entidades, repositorios y fuentes de datos (por ahora simuladas).
- `lib/presentation/`: páginas (`pages/`), estado (`viewmodels/`, Cubits) y widgets.
  - `viewmodels/market/market_cubits.dart`: estado compartido cliente ↔ emprendedor
    (configuración de tiendas, promociones y cupones, pedidos, billetera).
- `lib/data/datasources/mock/`: datos de ejemplo (tiendas, productos, campus, pedidos).
- `docs/`: diseño de base de datos, ruta del proyecto, guía de mapas e imágenes del proyecto.

Pendiente: conectar las fuentes de datos con la API de FastAPI y ordenar la arquitectura
(ver `docs/RUTA_DEL_PROYECTO.md`).
