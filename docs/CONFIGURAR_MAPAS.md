# Configurar Google Maps en UniMarket

Solo la pantalla **Direcciones → mapa** (`lib/presentation/pages/addresses/map_address_page.dart`)
usa Google Maps. El resto de mapas de la app (finalizar compra, seguir pedido, tienda,
configurar tienda) usan el **mapa ilustrado del campus** y no necesitan clave.

El proyecto ya trae todo el código preparado; solo falta crear la clave y pegarla.

## 1. Crear el proyecto y la clave en Google Cloud

1. Entra a <https://console.cloud.google.com/> con **unimarketdev@gmail.com**.
2. Usa el mismo proyecto `UniMarket` que creaste para el correo (Gmail API) o crea uno nuevo.
3. **Facturación → Vincular una cuenta de facturación.** Google la exige aunque el uso sea gratis.
4. **APIs y servicios → Biblioteca** y habilita:
   - *Maps SDK for Android*
   - *Maps SDK for iOS* (solo si vas a compilar para iPhone)
   - *Maps JavaScript API* (solo si quieres el mapa en la versión web)
5. **APIs y servicios → Credenciales → Crear credenciales → Clave de API.**

## 2. Restringir la clave (importante)

En la clave recién creada:

- **Restricciones de aplicación → Apps para Android → Agregar:**
  - Nombre del paquete: `com.unimarketdev.app` (el `applicationId` de
    `android/app/build.gradle.kts`).
  - Huella SHA-1 de depuración. En una terminal dentro de la carpeta `android/`:
    ```bash
    ./gradlew signingReport
    ```
    En Windows: `gradlew.bat signingReport`. Copia la línea `SHA1` de la variante `debug`.
- **Restricciones de API:** marca solo las APIs que habilitaste.

Para iOS crea una **segunda** clave con *Restricciones de aplicación → Apps para iOS* y el
bundle ID `com.unimarketdev.app`. Así, si alguien saca la clave de una app, no le sirve en la otra.

Cuando publiques en Play Store, agrega también la huella SHA-1 de la firma de **release**
(Play Console → Configuración → Integridad de la app) a la clave de Android.

Para la web crea **otra** clave restringida por *Referentes HTTP* (por ejemplo
`http://localhost:*/*` mientras desarrollas).

## 3. Pegar la clave en el proyecto

### Android (la que más vas a usar)
Abre `android/local.properties` (ya existe, lo crea Flutter) y agrega al final:

```properties
MAPS_API_KEY=AIzaSy...tu_clave...
```

Este archivo **no se sube a git**. `android/app/build.gradle.kts` lo lee y lo pone en
`AndroidManifest.xml` automáticamente. Ya están agregados los permisos de internet y ubicación.

### iOS (solo en Mac)
Crea `ios/Flutter/Secrets.xcconfig` con:

```
MAPS_API_KEY=AIzaSy...tu_clave_ios...
```

También está ignorado por git. `Info.plist` y `AppDelegate.swift` ya lo usan, y el permiso de
ubicación ya tiene su texto en español.

### Web (opcional)
En `web/index.html` quita el comentario de la línea del script y reemplaza `TU_API_KEY_WEB`.
Las claves web siempre quedan visibles en el navegador, por eso debes restringirla por referente.

## 4. Probar

```bash
flutter clean
flutter pub get
flutter run
```

Entra como Cliente → Perfil → Mis direcciones → agregar dirección → mapa. Debe aparecer el
mapa de Google y, al aceptar el permiso, tu ubicación.

## Problemas comunes

| Síntoma | Causa |
|---|---|
| Mapa gris con el logo de Google | Clave mal pegada, API no habilitada o SHA-1/paquete no coinciden con la restricción |
| `API key not found` en el log | Falta `MAPS_API_KEY` en `android/local.properties` (haz `flutter clean` después de agregarla) |
| No pide permiso de ubicación | Revisa que el emulador tenga ubicación activada (⋯ → Location) |
