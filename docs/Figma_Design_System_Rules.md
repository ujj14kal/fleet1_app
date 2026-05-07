# Fleet1 — Figma Design System Rules

This document describes how to map the Fleet1 Flutter codebase to a Figma design system and how to integrate high-fidelity (iOS + Android) designs without breaking app logic.

## 1. Token Definitions

- Colors: canonical source is `lib/core/constants/app_colors.dart` (e.g. `AppColors.primaryNavy`, `AppColors.primaryAmber`).
- Typography: Inter is bundled in `pubspec.yaml` under `fonts:` and used via `google_fonts` in `lib/core/theme/app_theme.dart`.
- Spacing: no centralized spacing file yet — use multiples of 4/8 and add `lib/core/constants/spacing.dart` when extracting tokens.

Recommended token JSON example (for Figma/Dev exchange):

```json
{
  "colors": {
    "primaryNavy": "#1F2F58",
    "primaryAmber": "#FFA800",
    "secondaryRed": "#AF0000",
    "background": "#F8FAFC",
    "supportGreen": "#00BF63",
    "supportDark": "#0F172A"
  },
  "typography": {
    "heading-1": {"fontFamily":"Inter","weight":800,"size":22,"lineHeight":28},
    "body-1": {"fontFamily":"Inter","weight":400,"size":14,"lineHeight":20}
  },
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24
  }
}
```

Use this JSON to create Figma styles (Colors, Text Styles, Spacing Tokens) and export as variables for developers.

## 2. Component Library

- Theme + tokens: `lib/core/theme/app_theme.dart`.
- Shared widgets: `lib/shared/widgets/` contains small components (e.g., `fleet1_app_bar.dart`).
- Feature shells (tabbed apps): `lib/features/manufacturer/m_shell.dart`, `lib/features/transporter/t_shell.dart`.

Integration strategy:

- Create a Figma component set that mirrors shared widgets (`AppBar`, `PrimaryButton`, `Card`, `ListItem`).
- In Flutter, add a `lib/core/ui/` folder containing platform-aware wrappers (we added `platform_widgets.dart`) and gradually replace local widget code with these wrappers.

## 3. Frameworks & Libraries

- Flutter + Material + Cupertino hybrids.
- `google_fonts` for Inter (runtime fetching disabled in `main.dart`).
- `flutter_svg` for vector icons.

Figma mapping:

- Map Material components to Android variant; map Cupertino components to iOS variant. Provide both variants in Figma under separate pages (`Android`, `iOS`).

## 4. Asset Management

- Assets stored in `assets/images/`, `assets/icons/`, and `assets/fonts/` and declared in `pubspec.yaml`.
- Use 1x/2x/3x raster assets for Android/iOS where needed; prefer SVGs for icons.

Figma workflow:

- Export icons from Figma as SVG and place them into `assets/icons/`.
- For raster images, export in required scales and add to `assets/images/`.

## 5. Icon System

- Icons are used via `flutter_svg` and `Icons` directly. There is no centralized icon font.
- Naming convention: kebab-case filenames in `assets/icons/` and reference by path.

## 6. Styling Approach

- Styling is applied through `ThemeData` and local widget styles.
- Responsive: layout is currently adaptive using flex and expanded widgets; for mobile screens, design for 360–430 width and iPhone 14/15 sizes.

Figma guidance:

- Create components with auto-layout and constraints to mirror Flutter layouts (horizontal/vertical stacks, fixed padding tokens).

## 7. Project Structure

- `lib/core/` — global theme, config, router, services.
- `lib/features/` — feature folders (auth, manufacturer, transporter, driver).
- `lib/shared/` — shared widgets and helpers.

## 8. Steps to Integrate Figma Designs Into Code (safe, non-breaking)

1. Create Figma file named `Fleet1 — High‑Fi (iOS & Android)` with two pages: `iOS` and `Android`.
2. Add Color, Text, and Spacing styles using token JSON above.
3. Build component library in Figma for `AppBar`, `PrimaryButton`, `Card`, `ListItem`, `BottomNav`.
4. Export components as SVGs or provide CSS-like token JSON for dev.
5. In the repo, add a `lib/core/ui/` layer (done) containing platform-aware wrappers.
6. Add demo preview routes (`/demo/ios`, `/demo/android`) so designers and developers can validate visuals without changing production flows.
7. Gradually replace existing screen-level visual widgets with `PlatformScaffold`, `PrimaryButton`, and other shared components: do this per-screen and run tests.

## 9. Implementation Examples

- Use a color token from Dart:

```dart
// lib/core/constants/app_colors.dart
static const Color primaryNavy = Color(0xFF1F2F58);
```

- Example usage in a widget:

```dart
Container(
  color: AppColors.primaryNavy,
  padding: const EdgeInsets.all(16),
  child: Text('Title', style: GoogleFonts.inter(color: AppColors.white)),
)
```

## 10. Export & Handoff

- Export Figma tokens as JSON and add to `design/tokens/fleet1.tokens.json` in repo.
- Export icons and images into `assets/icons/` and `assets/images/`.
- Provide an implementation notes doc (this file) and link to demo routes `/demo/ios` and `/demo/android`.

---

If you'd like, I can now:

- Create the public Figma file and populate the `iOS`/`Android` pages with the tokens and components.
- Export token JSON and place it into `design/tokens/` in the repo.
- Continue converting the main screens (Home, Auth, Dashboard, Profile) to use the new `PlatformScaffold` and shared components one-by-one.

Tell me which of those to run next and I'll proceed.
