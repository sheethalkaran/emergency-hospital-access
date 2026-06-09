# Emergency Hospital Access System

A smart mobile and web application designed to help emergency responders and patients quickly identify and access the most appropriate healthcare facility based on proximity, medical specialties, facility availability, and emergency bed capacity.

## Project Context

This repository contains the **Emergency Hospital Access System**, a key module of the **E-Challan and Emergency Ambulance Services** project.

The parent project aims to enhance emergency response efficiency by addressing common challenges faced by ambulances, such as traffic congestion and delays caused by vehicles failing to provide the right-of-way. The system incorporates real-time ambulance alert mechanisms to notify nearby vehicles, automated detection and enforcement of traffic violations through e-challan generation for vehicles obstructing ambulance movement, and intelligent healthcare support services to assist emergency responders during critical situations.

The **Emergency Hospital Access System** focuses on enabling ambulance personnel and patients to identify suitable hospitals based on factors such as location, available emergency facilities, medical specialties, and bed availability. The application provides features including hospital discovery, emergency bed booking, navigation support, and AI-assisted health guidance to facilitate informed decision-making and improve access to timely medical care.

By integrating emergency traffic management with healthcare accessibility services, the overall solution aims to reduce emergency response times, optimize healthcare resource utilization, and improve patient outcomes.

## Overview

Emergency Hospital Access System is a full-stack healthcare application that provides the following functionalities:

- **Find Nearby Hospitals Instantly** - Locate hospitals based on the user's current location and proximity.
- **Filter by Requirements** - Search hospitals using criteria such as facilities, specialties, state, and district.
- **Check Bed Availability** - View emergency bed availability information before reaching the hospital.
- **Access Hospital Information** - Obtain detailed hospital information, including contact details and emergency services.
- **Book Emergency Beds** - Reserve emergency beds through a streamlined booking process.
- **Receive Health Guidance** - Utilize an AI-powered chatbot for general health guidance and facility recommendations.
- **Navigate Using Interactive Maps** - View hospital locations and access navigation support through map integration.
- **Manage Bookings Efficiently** - Track booking details and download confirmation documents for reference.

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
emergency-hospital-access/
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


## API Endpoints

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
