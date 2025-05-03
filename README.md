
# Secured Cloud-Based Environmental Monitoring System

This project implements a secure, scalable, and modular Internet of Things (IoT) solution for real-time environmental monitoring. By combining Bluetooth Low Energy (BLE), WiFi (via MQTT over TLS), and LTE-M connectivity (Thingy:91), the system enables reliable collection, encryption, transmission, and visualization of environmental parameters such as temperature, humidity, oxygen concentration, and light intensity. The architecture is designed to balance security, power efficiency, and real-time performance while integrating predictive analytics using machine learning.

Developed as part of the IEIT3516 IoT Systems 2 course, this project highlights deep integration across embedded systems, cloud platforms, secure communications, and mobile development.

---

## Table of Contents

- [Features](#features)
- [System Architecture](#system-architecture)
- [Hardware Components](#hardware-components)
- [Software Stack](#software-stack)
- [AI Integration](#ai-integration)
- [Security Implementation](#security-implementation)
- [Flutter Dashboard](#flutter-dashboard)
- [Testing and Validation](#testing-and-validation)
- [Future Improvements](#future-improvements)
- [Potential Use Cases](#potential-use-cases)
- [Team](#team)

---

## Features

- Secure BLE Communication with AES-CBC encryption and BLE bonding
- MQTT over TLS for cloud data publishing (via Raspberry Pi broker)
- Flutter App Dashboard with real-time and historical data visualization
- AI Predictions using multivariable linear regression (in-app and Python)
- Cloud Sync with Firebase and nRF Cloud
- Fully modular design for ESP32 memory efficiency

---

## System Architecture

The system was intentionally modular to account for memory limitations on ESP32 devices. Instead of combining BLE and MQTT on a single microcontroller, we decoupled the design for optimal performance and security.

```
[ESP32 #1] -- BLE --> 
                   │
[ESP32 #2] -- BLE -->     [ESP32 BLE Gateway]
                               ↓ Decrypt (AES)
                               ↓
                        [ESP32 MQTT Publisher]
                               ↓ MQTT over TLS
                          [Raspberry Pi Broker]
                               ↓
                     [Firebase / nRF Cloud / MQTT]
                               ↓
                    [Flutter App (Android/Web)]
```

- BLE Servers: Two ESP32s read from environmental sensors and send encrypted BLE packets.
- BLE Gateway: A separate ESP32 decrypts the BLE notifications and prints JSON to serial.
- MQTT Publisher: Another ESP32 reads real or simulated data and securely publishes via TLS.
- Firebase/nRF Cloud: Secure cloud storage and analytics.
- Flutter App: Mobile dashboard for end users.

---

## Hardware Components

- ESP32 Microcontrollers: Dual-core with integrated BLE and WiFi, used for sensor interfaces and gateways.
- Raspberry Pi (Broker): Acts as the local MQTT broker with TLS and authentication.
- Nordic Thingy:91: Provides LTE-M connectivity in low-range environments.
- Sensors:
  - DHT22 and DHT11 for temperature/humidity
  - Analog light sensor
  - DFRobot Gravity Oxygen Sensor (SEN0465)

---

## Software Stack

- Embedded Code: C++ (Arduino Framework)
- Mobile Dashboard: Flutter with Firebase integration
- Cloud Storage: Firebase Realtime Database + nRF Cloud for LTE devices
- MQTT: PubSubClient over TLS on port 8883
- AI Models: Trained in Python (scikit-learn), deployed as multivariable regression in Flutter

---

## AI Integration

The system includes a machine learning component that allows the user to predict temperature based on other environmental parameters.

- Offline Training:
  - Random Forest Regressor
  - Feature selection using correlation heatmaps
- Live App Deployment:
  - Multivariable Linear Regression in Flutter
  - CSV upload supported for dynamic training
- Inputs: Humidity, pressure, and light intensity
- Output: Predicted temperature

---

## Security Implementation

Security was a foundational aspect of this system:

### BLE:
- AES-128-CBC encryption with PKCS#7 padding
- Passkey bonding and secure pairing
- Encrypted characteristic notifications

### MQTT:
- TLS encryption (port 8883)
- CA-signed certificates (optional)
- Username/password authentication

### Cloud:
- HTTPS for Firebase and nRF Cloud
- Firebase API key access controlled via app settings

---

## Flutter Dashboard

The Flutter-based mobile app features:

- Real-time chart visualization using fl_chart
- Toggle views: cards, tables, analytics, team, settings
- Local export and shared preferences management
- Prediction engine for temperature forecasting
- Dark and light theme switching
- Responsive layout for mobile and tablet
- CSV export of sensor logs

---

## Testing and Validation

Each subsystem was independently tested due to memory limitations of ESP32:

| Component     | Result                                                                 |
|---------------|------------------------------------------------------------------------|
| BLE Security  | Encrypted communication verified; unauthorized pairing blocked         |
| MQTT Broker   | Verified TLS handshake; tested both valid/invalid certs and credentials|
| Flutter App   | Stable connection; gracefully handled Firebase errors or disconnects   |
| Sensor Readings | DHT22 humidity sensor showed consistent faults and was documented    |

Latency from sensor to app display: ~3 seconds.

---

## Future Improvements

- UART communication between BLE Gateway and MQTT Publisher
- Merge BLE and MQTT into a single FreeRTOS-based device (if memory permits)
- Hostname-based TLS verification for MQTT broker
- Anomaly detection and time-series forecasting
- Real-time alert notifications (e.g., abnormal oxygen levels)
- Detailed power profiling and battery optimization
- Geolocation view for sensor nodes in app

---

## Potential Use Cases

- Smart Agriculture: Track environmental parameters to optimize irrigation, planting cycles.
- Air Quality Monitoring: Detect and log oxygen levels and pollution indicators in real-time.
- Disaster Warning Systems: Identify early changes in humidity, temperature, pressure.
- Industrial Monitoring: Monitor safe conditions in confined environments (e.g., O₂ levels).

---

## Team

- Kaushal Khadka
- Aleksandr Moskalev
- Harikant Sharma

