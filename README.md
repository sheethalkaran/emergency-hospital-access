# Emergency Hospital Access

A smart mobile and web application that helps users quickly find and reach the nearest appropriate hospital based on real-time facility availability, bed capacity, and distance, ensuring emergency patients get to the right place at the right time.

## Overview

### Emergency Hospital Access is a full-stack emergency healthcare application that provides the following functionalities:
- **Find nearby hospitals instantly** based on current location and distance
- **Filter by requirements** - Search hospitals with specific facilities and specialties
- **Check real-time bed availability** - View available emergency beds before reaching the hospital
- **Reach the right hospital** - Get precise hospital locations and contact information
- **Book emergency beds** - Reserve a bed at the selected hospital
- **Get health guidance** - Integrated AI chatbot for emergency health advice
- **View on map** - Interactive map showing hospital locations
- **Download confirmations** - Instant confirmation PDFs for reference

## Features

### Frontend (Flutter)
- **Hospital Search & Filter**: Advanced search with state, district, category, and specialty filters
- **Location-Based Search**: Find nearby hospitals using GPS
- **Hospital Details**: Comprehensive hospital information with beds, facilities, and specialties
- **Emergency Bed Booking**: Easy-to-use booking form for emergency bed reservations
- **Interactive Map**: View hospitals on Google Maps
- **Health Chatbot**: AI-powered assistant providing health guidance and facility recommendations
- **Booking Management**: Track bookings and download confirmation PDFs
- **Responsive UI**: Works on mobile (iOS/Android) and web browsers

### Backend (Node.js & MongoDB)
- **RESTful API**: Complete API endpoints for hospitals, bookings, and search
- **Advanced Search**: Text search across multiple hospital fields
- **Geospatial Queries**: Find hospitals within a specified radius
- **Database**: MongoDB for efficient data storage and retrieval
- **PDF Generation**: Automatic confirmation form generation
- **Data Import**: Excel file upload for bulk hospital data import
- **Real-time Updates**: Bed availability tracking

## Tech Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **HTTP Client**: http package
- **Location Services**: Geolocator
- **UI Libraries**: Google Fonts, Material Design 3
- **Map Integration**: Google Maps
- **PDF Handling**: url_launcher

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB
- **ORM**: Mongoose
- **File Upload**: Multer
- **PDF Generation**: PDFKit
- **Excel Processing**: XLSX
- **CORS**: Enabled for cross-origin requests

## Project Structure

```
hospital-search/
├── frontend/                          # Flutter Application
│   ├── lib/
│   │   ├── main.dart                 # App entry & state management
│   │   ├── screens/                  # UI Screens
│   │   │   ├── home_screen.dart
│   │   │   ├── hospital_detail_screen.dart
│   │   │   ├── booking_form_screen.dart
│   │   │   ├── chatbot_screen.dart
│   │   │   └── map_screen.dart
│   │   ├── services/                 # API & Business Logic
│   │   │   ├── api_service.dart      # HTTP requests & API calls
│   │   │   ├── chatbot_service.dart  # Health guidance logic
│   │   │   └── location_service.dart # Location handling
│   │   ├── models/                   # Data Models
│   │   │   └── hospital.dart
│   │   ├── widgets/                  # Reusable Components
│   │   │   ├── hospital_card.dart
│   │   │   └── chatbot_messages.dart
│   │   ├── config/
│   │   │   └── environment.dart
│   │   ├── android/                  # Android platform specific
│   │   ├── ios/                      # iOS platform specific
│   │   ├── web/                      # Web platform specific
│   │   └── pubspec.yaml              # Dependencies
│   └── README.md
│
├── backend/                           # Node.js Backend
│   ├── server.js                      # Main server file
│   ├── package.json                   # Dependencies
│   ├── config/
│   ├── utils/
│   │   └── pdfGenerator.js            # PDF generation utility
│   ├── data/
│   │   └── hospitals.csv              # Sample hospital data
│   └── temp/                          # Temporary files
│
└── .gitignore                         # Git ignore rules
```


## 📡 API Endpoints

### Hospital Operations
- `GET /api/health` - Server health check
- `GET /api/hospitals` - Get all hospitals
- `GET /api/hospitals/:id` - Get hospital details
- `GET /api/hospitals/nearby?lat=<lat>&lng=<lng>&radius=<km>` - Find nearby hospitals
- `GET /api/hospitals/search?state=&district=&name=` - Advanced search
- `GET /api/hospitals/stats` - Hospital statistics

### Booking Operations
- `POST /api/bookings` - Create new booking
- `GET /api/bookings/:id` - Get booking details
- `POST /api/bookings/:id/confirm` - Confirm booking
- `POST /api/bookings/:id/cancel` - Cancel booking
- `GET /api/bookings/:id/download-confirmation` - Download PDF confirmation

### Data Management
- `POST /api/hospitals/import` - Import hospitals from Excel file

## Database Schema

### Hospital Collection
```javascript
{
  srNo: String,
  name: String (indexed),
  category: String,
  state: String (indexed),
  district: String (indexed),
  address: String,
  telephone: String,
  emergencyNum: String,
  email: String,
  website: String,
  specialties: [String],
  facilities: [String],
  totalBeds: Number,
  availableBeds: Number (indexed),
  location: { type: Point, coordinates: [lng, lat] }, // GeoJSON
  timestamps: { createdAt, updatedAt }
}
```

### Booking Collection
```javascript
{
  hospitalId: ObjectId (ref: Hospital),
  patientName: String,
  patientAge: Number,
  patientGender: String,
  contactPhone: String,
  emergencyType: String,
  medicalCondition: String,
  status: String, // pending, confirmed, cancelled
  confirmationToken: String,
  bookingDate: Date,
  confirmationDate: Date,
  timestamps: { createdAt, updatedAt }
}
```


## Project Context

This application forms an integral component of the IoT-Based Smart Ambulance Assist System, with the objective of improving emergency response efficiency through automated vehicle alerting, real-time detection and enforcement of traffic right-of-way violations, and intelligent hospital recommendation based on proximity, medical facilities, and real-time bed availability.

