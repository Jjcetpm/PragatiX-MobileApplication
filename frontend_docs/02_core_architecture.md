# Core Architecture

This document covers the foundational elements of the Flutter frontend, including the app entry point, configuration, and overarching architectural patterns.

## Architecture Style

The application follows a **Hybrid Layered/Feature-based Architecture**. It organizes code primarily by functional features (e.g., `admin/`, `captain/`, `student/`, `teacher/`), but within those modules, it uses layered concepts (`models/`, `pages/`, `services/`, `widgets/`). 

### State Management
The project heavily relies on the **Provider** pattern (`ChangeNotifierProvider`, `MultiProvider`). It uses both:
- **Global Providers**: Injected at the root (`XpProvider`, `BadgeProvider`) to maintain state across the entire app session.
- **Scoped Providers**: Instantiated inside specific pages (`ActivityProvider` in `ActivityListPage`) acting more like a ViewModel in MVVM, scoped only to the lifecycle of that feature flow.

### Navigation Pattern
Navigation is primarily imperative, relying heavily on `Navigator.push` and `Navigator.pop` with inline `MaterialPageRoute` callbacks, rather than named routes or declarative routers (like `go_router`).

### Data Flow & API Communication
The application uses raw `http` calls encapsulated mostly within `Service` classes. JSON serialization is handled manually through factory constructors (`fromJson`) inside the model classes, which contain complex fallback logic to handle variations in backend API responses.

---

## File Documentation

### lib/main.dart

**File Name:** `main.dart`
**Full Path:** `lib/main.dart`
**Purpose:** Application entry point. Initializes the Flutter app, sets up global state providers, and defines the initial route.
**Module:** Core
**Imports:** 
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `providers/xp_provider.dart`
- `providers/badge_provider.dart`
- `screens/login/login_page.dart`
**Exports:** None
**Classes:** 
- `MyApp` (extends `StatelessWidget`)
**Functions:** 
- `main()`
**Providers used:** `XpProvider`, `BadgeProvider`
**Services used:** None directly
**Repositories used:** None directly
**Models used:** None directly
**Widgets used:** `MultiProvider`, `ChangeNotifierProvider`, `MaterialApp`, `LoginPage`
**Routes connected:** Home route (`/`) mapped to `LoginPage`
**API endpoints called:** None
**State management:** Initializes `Provider` tree at the root.
**Navigation source:** OS Launcher
**Navigation destination:** `LoginPage`
**Dependencies:** `provider` package
**Files depending on this file:** None
**Reusable components:** None
**Complexity:** Low
**Code responsibility:** Bootstrapping the application and injecting global state.

---

### lib/core/config/api_config.dart

**File Name:** `api_config.dart`
**Full Path:** `lib/core/config/api_config.dart`
**Purpose:** Centralized configuration for backend API endpoints.
**Module:** Core
**Imports:** None
**Exports:** None
**Classes:** 
- `ApiConfig`
**Functions:** None
**Fields:** 
- `static const String baseUrl`
**Providers used:** None
**Services used:** None
**Repositories used:** None
**Models used:** None
**Widgets used:** None
**Routes connected:** None
**API endpoints called:** None
**State management:** None
**Navigation source:** None
**Navigation destination:** None
**Dependencies:** None
**Files depending on this file:** All Services and Repositories across the application.
**Reusable components:** Yes (Configuration constant).
**Complexity:** Very Low.
**Code responsibility:** Storing the base URL (`http://10.11.223.133:8080`) to ensure all network requests point to the correct backend server environment.
