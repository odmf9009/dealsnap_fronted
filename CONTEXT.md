# DealSnap App — Contexto Completo del Frontend Flutter

> Archivo de referencia para IA y desarrolladores. Leer antes de cualquier tarea.

---

## 1. ¿Qué es este proyecto?

App Flutter multiplataforma (Web / Android / iOS) que consume la API REST del backend DealSnap y muestra ofertas activas y próximas de Amazon con sus códigos promo. Al tocar un producto, copia el código promo al portapapeles y abre el enlace de Amazon.

---

## 2. Stack

| Capa | Tecnología |
|---|---|
| Framework | Flutter 3.29 / Dart 3.7 |
| HTTP client | `package:http ^1.2` |
| Imágenes cacheadas | `cached_network_image ^3.3` |
| Abrir URLs | `url_launcher ^6.3` |
| Tipografía | `google_fonts ^6.2` (Inter) |
| Skeleton loading | `shimmer ^3.0` |
| Grid adaptativo | `flutter_staggered_grid_view ^0.7` |

---

## 3. Estructura de archivos

```
dealsnap_fronted/lib/
├── main.dart                          # Entry point → DealSnapApp → ShellScreen
│
├── theme/
│   └── app_theme.dart                 # AppColors (constantes) + AppTheme (ThemeData)
│
├── models/
│   └── product.dart                   # Product + PromoInfo (fromJson desde backend)
│
├── services/
│   └── api_service.dart               # getDeals(), getUpcoming(), getFilters()
│
├── screens/
│   ├── shell_screen.dart              # Scaffold principal: AppBar + BottomNav 2 tabs
│   ├── deals_screen.dart              # Tab "Hot Deals" — grid infinito con filtros/sort
│   ├── upcoming_screen.dart           # Tab "Coming Soon" — grid con countdown badges
│   └── auth/
│       ├── login_screen.dart          # Visual only (no hace peticiones)
│       └── register_screen.dart       # Visual only (no hace peticiones)
│
└── widgets/
    ├── product_card.dart              # Card de producto (toda la lógica de tap)
    ├── filter_bar.dart                # CategoryFilterBar + DiscountFilterBar
    └── sort_bar.dart                  # SortBar + SortOption enum
```

---

## 4. Paleta de colores (`theme/app_theme.dart`)

```dart
AppColors.brand            = #10B981  // verde esmeralda — acento principal
AppColors.brandDark        = #059669
AppColors.brandLight       = #D1FAE5  // fondo suave verde
AppColors.accent           = #F59E0B  // ámbar — tag "PROMO CODE"
AppColors.accentLight      = #FEF3C7
AppColors.danger           = #EF4444  // rojo — badge de % descuento
AppColors.dangerLight      = #FEE2E2
AppColors.bg               = #F9FAFB  // fondo general (gris muy claro)
AppColors.surface          = #FFFFFF  // fondo de cards
AppColors.surfaceVariant   = #F3F4F6
AppColors.textPrimary      = #111827
AppColors.textSecondary    = #6B7280
AppColors.textMuted        = #9CA3AF
AppColors.divider          = #E5E7EB
AppColors.badgeExclusive   = #8B5CF6  // púrpura — upcoming banner
```

Tipografía: **Inter** (Google Fonts) en todos los pesos.

---

## 5. Modelos (`models/product.dart`)

### PromoInfo
```dart
class PromoInfo {
  final String id;
  final List<String> promoCodes;
  final String title;
  final String? expiresAt;   // ISO 8601 — para promos activas
  final String? startsAt;    // ISO 8601 — solo para upcoming
}
```

### Product
```dart
class Product {
  final String id, asin, title, category, url;
  final String? image;
  final double currentPrice, originalPrice;
  final int discountPercentage;
  final PromoInfo? promo;
  final bool isBestDeal;
  final double? dealScore;
  final String? source;       // "amazon" | "mock"
  
  bool get hasPromoCode => promo?.firstCode != null;
  String? get promoCode => promo?.firstCode;
}
```

---

## 6. Servicio de API (`services/api_service.dart`)

```dart
// URL configurable con --dart-define en build time
static const _base = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:3000',
);

// Para Android emulador: usar 10.0.2.2:3000
// Para dispositivo físico: usar IP de la máquina en la red local
```

Métodos:
```dart
ApiService.getDeals({ page, limit, category, discount })    → DealsResponse
ApiService.getUpcoming({ page, limit, category, discount }) → DealsResponse
ApiService.getFilters()                                      → Map<String, dynamic>
```

`DealsResponse` contiene: `products`, `total`, `page`, `categories`, `discounts`.

---

## 7. Pantallas

### ShellScreen (`screens/shell_screen.dart`)
- AppBar con logo "DealSnap" + botón "Sign in" (va a LoginScreen)
- IndexedStack con los 2 tabs (mantiene estado al cambiar)
- BottomNav custom: "Hot Deals 🔥" / "Coming Soon 🚀"

### DealsScreen (`screens/deals_screen.dart`)
- `CustomScrollView` con `SliverToBoxAdapter` para filtros y `SliverGrid` para productos
- Filtros: `CategoryFilterBar` (desde `/api/promos/filters`) + `DiscountFilterBar`
- `SortBar` — ordena la lista en memoria (no server-side)
- Scroll infinito: carga siguiente página cuando el scroll está a 300px del final
- `RefreshIndicator` (pull to refresh)
- Estados: loading (shimmer) / error (retry) / empty / data

### UpcomingScreen (`screens/upcoming_screen.dart`)
- Igual que DealsScreen pero:
  - Banner púrpura "⏰ Coming Soon" al tope
  - Filtros vienen del campo `filters` de la respuesta de `/upcoming`
  - `ProductCard(isUpcoming: true)` → muestra badge "🚀 Launches in Xd Xh"

### LoginScreen / RegisterScreen (`screens/auth/`)
- **Solo visuales** — los formularios no hacen peticiones al backend todavía
- Layout responsive: centra en pantallas anchas (`isWide = width > 600`)
- Google sign-in button (sin funcionalidad)
- Navegación: Login ↔ Register con `Navigator.pushReplacement`

---

## 8. Widgets

### ProductCard (`widgets/product_card.dart`)

**Comportamiento al tocar (`_onTap`):**
1. Si tiene promo code → `Clipboard.setData` + SnackBar verde
2. Siempre → `launchUrl(uri, mode: LaunchMode.externalApplication)`

**Estructura visual:**
```
┌────────────────────────┐
│  [Imagen producto]     │  ← AspectRatio 1:1, CachedNetworkImage
│  [60% OFF] badge       │  ← Positioned top-left, rojo
│            [★] badge   │  ← Positioned top-right, ámbar (solo si isBestDeal)
├────────────────────────┤
│  [PROMO CODE] tag      │  ← ámbar, solo si hasPromoCode
│  Título del producto   │  ← 2 líneas, truncado
│  $14.99  ~~$39.99~~    │  ← verde + tachado gris
│  [⏱ Expires in 3d]    │  ← badge dinámico (rojo/ámbar/verde según urgencia)
└────────────────────────┘
```

Para upcoming: el badge final muestra `[🚀 Launches in 5d 3h]` en púrpura.

**Colores del badge de tiempo:**
- ≤2 días restantes → `AppColors.danger` (rojo)
- ≤7 días → `AppColors.accent` (ámbar)
- Más → `AppColors.brand` (verde)

### CategoryFilterBar (`widgets/filter_bar.dart`)
- Pills horizontales con emoji + texto
- Emojis asignados por palabra clave en el nombre de la categoría
- Al seleccionar: fondo verde, texto blanco; al deseleccionar: vuelve a neutral
- `onChanged(null)` limpia el filtro

### DiscountFilterBar
- Pills de porcentaje: "20%+ OFF", "30%+ OFF", etc.
- Colores: seleccionado = fondo rojo, texto blanco; normal = fondo rojo claro, texto rojo

### SortBar (`widgets/sort_bar.dart`)
- Muestra `"X deals"` + botón con el sort actual
- `_showSortSheet()` → `showModalBottomSheet` con 4 opciones
- `SortOption` enum: `relevance | priceLow | priceHigh | discountHigh`

---

## 9. Compilar y ejecutar

```bash
# Web
flutter run -d chrome
flutter build web --dart-define=API_BASE=https://tu-backend.com

# Android (emulador)
flutter run -d emulator-5554 --dart-define=API_BASE=http://10.0.2.2:3000

# Android (dispositivo físico, misma red)
flutter run -d <device-id> --dart-define=API_BASE=http://192.168.X.X:3000

# iOS
flutter run -d <device-id>

# Análisis estático
flutter analyze
```

---

## 10. Conexión con el Backend

El backend corre en `http://localhost:3000`. El frontend consume exactamente 3 endpoints:

| Endpoint | Cuándo |
|---|---|
| `GET /api/promos/deals` | DealsScreen — carga inicial + filtros + paginación |
| `GET /api/promos/upcoming` | UpcomingScreen |
| `GET /api/promos/filters` | DealsScreen — para poblar los filtros de categoría |

El backend debe estar corriendo (`npm run dev` en `dealsnap_backend/`) y con datos en MongoDB para que la app funcione.

---

## 11. Lo que falta implementar (próximos pasos)

- [ ] Auth real: conectar LoginScreen con `POST /api/users/login`
- [ ] Gestión de estado (Riverpod recomendado) para token JWT y usuario
- [ ] Pantalla de detalle de producto (`/api/products/:asin`)
- [ ] Favoritos (`/api/favorites`) con persistencia local
- [ ] Notificaciones push con Firebase Messaging
- [ ] Deep links para compartir productos
- [ ] Modo oscuro (los colores ya tienen estructura para soportarlo)
- [ ] Deploy: Flutter web → Vercel/Firebase Hosting

---

## 12. Decisiones de diseño importantes

**No se usa state management library todavía.** Cada screen es un `StatefulWidget` que maneja su propio estado. Cuando se agregue auth y favoritos, migrar a Riverpod.

**Sort es client-side.** El backend no soporta parámetro `sort`, por lo que el ordenamiento se aplica sobre los resultados ya cargados en memoria. Para datasets grandes, esto es un compromiso aceptable porque los filtros de categoría/descuento reducen el conjunto antes de sortear.

**IndexedStack para los tabs.** Preserva el scroll y el estado de cada tab al cambiar entre ellos, evitando refetch innecesario.

**CachedNetworkImage.** Las imágenes de Amazon son pesadas — el caché evita refetch en scroll y mejora percepción de velocidad significativamente.
