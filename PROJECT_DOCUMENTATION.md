# Contact Navigator - Project Documentation

Contact Navigator is a premium Flutter application designed to revolutionize contact management by integrating advanced location-based features and seamless navigation.

## Overview
The application goes beyond a simple phonebook, allowing users to save multiple locations for each contact, visualize them on an interactive map, and calculate driving routes—all within a single, unified interface.

---

## Architecture
The project follows **Clean Architecture** principles combined with the **BLoC (Business Logic Component)** pattern for state management.

### Layers:
1.  **Core**: Contains shared utilities, theme definitions, routing logic, and service interfaces.
2.  **Data/Services**: Implementations of external services like `ContactService`, `GroupService`, and `MapUtils`.
3.  **Features**: Modularized feature folders (Contacts, Map, Keypad, Categories), each containing its own BLoC, pages, and widgets.

---

## Key Features

### 1. Advanced Contact Management
*   **Multi-Data Support**: Supports multiple phone numbers, emails, and addresses per contact with custom labeling.
*   **Dynamic Groups**: Organize contacts into categories (Work, Family, etc.) with the ability to add multiple contacts to a group simultaneously.
*   **Profile Customization**: Full support for contact photos and detailed notes.

### 2. Interactive Mapping & Navigation
*   **OSM Integration**: Uses OpenStreetMap tiles via `flutter_map` for a high-performance, cost-effective mapping experience.
*   **In-App Routing**: Integrates the **OSRM API** to calculate and visualize driving routes from the user's current GPS position to any contact address.
*   **Multi-Pin Support**: If a contact has multiple addresses, all locations are displayed on the map with individual markers.
*   **Real-time Previews**: Interactive mini-maps inside the Add/Edit contact forms.

### 3. Smart Location Tools
*   **Link Auto-Parsing**: Paste a Google Maps or OSM link into an address field, and the app automatically extracts the coordinates.
*   **Deep URL Resolution**: Supports shortened links (goo.gl, etc.) by following redirects and using geocoding fallbacks for place names.
*   **Reverse Geocoding**: Tap anywhere on the map to instantly get a readable street address.
*   **GPS Sync**: Snap to your current location with a single tap.

### 4. Accessibility & Intelligence
*   **Voice Assistant (TTS)**: Integrated Text-to-Speech system that announces contact names on the map and category titles when navigating, making the app more accessible.
*   **Global Map Search**: A powerful search bar integrated directly into the map tab, allowing users to find any global location using natural language queries.

### 5. Premium UX/UI
*   **Floating Modular Navigation**: A sleek, pill-shaped bottom navigation bar that provides a modern, "floating" aesthetic while maximizing screen real estate.
*   **Dynamic Search**: High-performance, in-memory search with RTL (Right-to-Left) support for Arabic users.
*   **Category Management**: Advanced tools to rename categories and selectively remove contacts from groups without deleting them from the system.
*   **Visual Polish**: Modern design with glassmorphism effects, smooth transitions, and a custom blue-themed color palette.
*   **Direct Interaction**: One-touch calling, messaging, and coordinate copying directly from contact previews.

---

##  Tech Stack
*   **Framework**: Flutter
*   **State Management**: `flutter_bloc`
*   **Mapping**: `flutter_map`, `latlong2`
*   **Location Services**: `geolocator`, `geocoding`
*   **Contact Sync**: `flutter_contacts`
*   **Networking**: `http` (for OSRM routing)
*   **Utilities**: `url_launcher`, `flutter_phone_direct_caller`, `image_picker`

---

##  Project Structure
```text
lib/
├── core/
│   ├── routes/          # App navigation & routes
│   ├── services/        # Service interfaces & implementations
│   ├── theme/           # Color palettes & typography
│   └── utils/           # MapUtils, TextUtils, Debouncers
├── features/
│   ├── contacts/        # List, Add/Edit, Category pages
│   │   ├── bloc/        # Contacts state management
│   │   └── widgets/     # Reusable UI components
│   ├── map/             # Map visualization & routing
│   ├── keypad/          # T9-style dialer
│   └── categories/      # Group management
└── main.dart            # Entry point & global providers
```

---

## Setup & Configuration
1.  **Permissions**: The app requires `READ_CONTACTS`, `WRITE_CONTACTS`, `ACCESS_FINE_LOCATION`, and `CALL_PHONE` permissions (configured in AndroidManifest.xml and Info.plist).
2.  **Dependencies**: Run `flutter pub get` to install all required packages.
3.  **Environment**: The app uses the public OSRM demo server for routing. For production, consider a private OSRM instance.

---

## Implementation Details (Custom Logic)
*   **Coordinate Storage**: Location links are stored as OSM-formatted URLs in the contact's `Website` field to ensure compatibility across different devices.
*   **Debouncing**: Address parsing and searches use a `Debouncer` to prevent excessive API calls and ensure a smooth typing experience.
*   **RTL Detection**: The search bar dynamically detects the input language and adjusts the text direction in real-time.

---

## Frontend & Backend Architecture

### Frontend (Client-Side)
The frontend is built entirely in **Flutter**, utilizing a declarative UI approach.
*   **Rendering Engine**: Skia/Impeller (standard Flutter).
*   **State Management**: `flutter_bloc` provides a reactive flow. The UI emits **Events**, the BLoC processes them and yields **States**, which the UI consumes via `BlocBuilder` and `BlocListener`.
*   **Navigation**: Uses named routes and a custom `AppRoutes` configuration for deep linking and tab switching.

### Backend (Services & Data)
This project uses a **Decentralized Backend** approach:
*   **Primary Data Store**: The device's native contacts database, accessed via `flutter_contacts`. This ensures privacy and offline availability.
*   **Routing Engine**: External **OSRM (Open Source Routing Machine)** REST API. It processes coordinate pairs and returns geometry data for navigation.
*   **Tile Server**: **OpenStreetMap (OSM)** serves map tiles via HTTPS, eliminating the need for a proprietary mapping backend like Google Maps.
*   **Geocoding**: Utilizes the `geocoding` package which leverages native Android/iOS system services for address lookup.

---

## System Analysis

### Functional Requirements
1.  **FR1**: The system shall allow users to store multiple addresses and phone numbers per contact.
2.  **FR2**: The system shall visualize all contact locations on a map using custom markers.
3.  **FR3**: The system shall calculate driving routes from the user's GPS position to a selected contact destination.
4.  **FR4**: The system shall support T9-style predictive searching for contacts.
5.  **FR5**: The system shall provide RTL support for multi-lingual search queries.

### Use Case Diagram (Summary)
*   **User -> Manage Contacts**: Create, Read, Update, Delete (CRUD) operations.
*   **User -> Navigate**: Select contact pin -> Request route -> Visualize path.
*   **User -> Search**: Type query -> Filter in-memory list -> View results.
*   **System -> Sync**: Fetch native device contacts -> Map to internal models.

---

## System Design

### Data Flow (Sequence)
1.  **Input**: User enters an address link in `AddContactPage`.
2.  **Processing**: `MapUtils` parses the link -> `geocoding` fetches the human-readable address.
3.  **Storage**: `ContactService` packages data into a `Contact` object -> persists to device DB.
4.  **Visualization**: `MapTab` listens to the `ContactsBloc` -> triggers a map re-render with new markers.

### UI Design Principles
*   **Consistency**: Shared component library (e.g., `_buildField`) ensures a uniform look.
*   **Responsiveness**: Layouts use `Flex` and `MediaQuery` to adapt to different screen sizes.
*   **Accessibility**: High-contrast colors (Navy Blue vs. White) and large interactive touch targets.

---

## Extended Project Context (For Final Book)

### 1. Problem Statement
Managing contacts in modern smartphones is often limited to textual data (names, numbers). While map applications exist, the "link" between a personal contact and a real-world location is often broken, requiring users to switch back and forth between apps. Existing solutions rarely support multiple locations for a single contact or provide integrated, in-app routing without heavy API costs.

### 2. Motivation & Goals
The goal of **Contact Navigator** is to bridge the gap between contact management and geographic navigation.
*   **Goal 1**: Provide a high-performance, cost-effective navigation system using Open Source tools (OSM/OSRM).
*   **Goal 2**: Enable complex data structures (multi-location, multi-number) without sacrificing simplicity.
*   **Goal 3**: Optimize for bilingual environments (Arabic/English) with RTL-aware UI components.

### 3. Non-Functional Requirements
*   **Performance (NFR1)**: In-memory search filtering must respond in under 100ms.
*   **Security (NFR2)**: All contact data must remain on the device's local storage; no personal data should be sent to external servers except for coordinate-based routing.
*   **Reliability (NFR3)**: The application must handle intermittent GPS signals gracefully by providing a "last known location" fallback.
*   **Scalability (NFR4)**: The mapping system should support hundreds of markers simultaneously without significant frame drops (aiming for 60fps).

### 4. Comparative Analysis: OSM vs. Google Maps
During the design phase, OpenStreetMap (OSM) was selected over Google Maps for the following reasons:
| Feature | OpenStreetMap (Chosen) | Google Maps |
| :--- | :--- | :--- |
| **Cost** | Free / Open Source | Usage-based billing (High cost for scale) |
| **Privacy** | High (Self-hostable) | Data shared with third-party |
| **Customization** | Full control over Tile Providers | Limited to Google's styles |
| **Routing** | OSRM (Flexible API) | Directions API (Strict limits) |

### 5. Implementation Algorithms
#### Address Debouncing
To optimize network usage, a **Debouncer Algorithm** is implemented. When a user pastes a link or types an address, the system waits for 500ms of inactivity before triggering the geocoding/parsing logic, preventing redundant API calls.

#### Link Parsing Regex
A custom multi-pattern **Regular Expression** system is used in `MapUtils` to detect and extract coordinates from various URL structures (e.g., `google.com/maps?q=...`, `osm.org/#map=...`).

---

## Future Work
*   **Offline Maps**: Support for downloading map tiles for use in areas with no data connection.
*   **Proximity Alerts**: Notifications when the user is physically near a contact's saved location.
*   **Group Routing**: Calculating the most efficient path to visit multiple contact locations in one trip (Traveling Salesman Problem implementation).
*   **Cloud Sync**: Optional, end-to-end encrypted backup for contact locations across devices.
