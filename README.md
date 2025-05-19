# Network Port Scanner

[![pub package](https://img.shields.io/pub/v/network_port_scanner.svg)](https://pub.dev/packages/network_port_scanner)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter package for scanning local networks to discover devices with specific open ports. Works on both Wi-Fi and Ethernet connections.

## Features

- Scan your local network for devices with specific open ports
- Check if a specific port is open on a particular IP address
- Scan multiple ports on a single device
- Works on both Wi-Fi and Ethernet connections
- Configurable scan parameters (timeout, IP range, etc.)
- Progress tracking with callback function
- Support for Flutter mobile, desktop, and web platforms

## Getting Started

### Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  network_port_scanner: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Android Permissions

For Android, add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

The location permission is required on Android 10+ to access network information. Your app will need to request location permission at runtime:

```dart
import 'package:permission_handler/permission_handler.dart';

// Request location permission
await Permission.location.request();
```

### iOS Permissions

For iOS, add the following to your `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to your local network to scan for devices.</string>
```

## Usage

### Basic Network Scan

Scan your local network for devices with a specific port open:

```dart
import 'package:network_port_scanner/network_port_scanner.dart';

// Scan for devices with port 8080 open
List<String> results = await NetworkScanner.scanNetwork(
  port: 8080,
  onProgressUpdate: (progress) {
    print('Scan progress: ${(progress * 100).toStringAsFixed(1)}%');
  },
);

// Print results
print('Found ${results.length} devices with port 8080 open:');
for (String ip in results) {
  print('- $ip');
}
```

### Check a Single IP and Port

```dart
bool isOpen = await NetworkScanner.scanSinglePort('192.168.1.1', 80);
print('Port 80 on 192.168.1.1 is ${isOpen ? 'open' : 'closed'}');
```

### Scan Multiple Ports on a Device

```dart
List<int> openPorts = await NetworkScanner.scanMultiplePorts(
  '192.168.1.1',
  [80, 443, 8080, 22, 21],
);

print('Open ports on 192.168.1.1:');
for (int port in openPorts) {
  print('- Port $port is open');
}
```

### Advanced Configuration

```dart
List<String> results = await NetworkScanner.scanNetwork(
  port: 22,
  timeout: 300,               // Timeout in milliseconds
  customSubnet: '10.0.0',     // Custom subnet to scan
  startHost: 50,              // Start from IP .50
  endHost: 100,               // End at IP .100
  skipDeviceIP: true,         // Skip scanning the device's own IP
  onProgressUpdate: (progress) {
    updateProgressBar(progress); // Update UI with progress
  },
);
```

## Complete Example

See the [example](https://github.com/FASALURAHMANMK/network_port_scanner/tree/main/example) folder for a complete example application.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request