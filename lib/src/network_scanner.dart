import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

/// A utility class for network port scanning.
///
/// This class provides methods to scan local networks for devices with specific
/// ports open. It supports both Wi-Fi and Ethernet connections and allows
/// configuring various scan parameters.
class NetworkScanner {
  /// Scans the network for devices with the specified port open.
  ///
  /// Parameters:
  /// - [port]: The TCP port number to scan for (required)
  /// - [timeout]: Connection timeout in milliseconds (default: 200ms)
  /// - [onProgressUpdate]: Optional callback function that reports scan progress from 0.0 to 1.0
  /// - [customSubnet]: Specify a custom subnet to scan (e.g., "192.168.1")
  /// - [startHost]: First host ID to scan in the subnet (default: 1)
  /// - [endHost]: Last host ID to scan in the subnet (default: 254)
  /// - [skipDeviceIP]: Whether to skip scanning the current device's IP (default: true)
  ///
  /// Returns a list of IP addresses with the specified port open.
  ///
  /// Example:
  /// ```dart
  /// List<String> results = await NetworkScanner.scanNetwork(
  ///   port: 8080,
  ///   timeout: 300,
  ///   onProgressUpdate: (progress) {
  ///     print('Scan progress: ${(progress * 100).toStringAsFixed(1)}%');
  ///   },
  /// );
  /// ```
  static Future<List<String>> scanNetwork({
    required int port,
    int timeout = 200, // milliseconds
    Function(double)? onProgressUpdate,
    String? customSubnet,
    int startHost = 1,
    int endHost = 254,
    bool skipDeviceIP = true,
  }) async {
    final List<String> openPortIPs = [];

    try {
      // Determine subnet to scan
      String subnet;
      if (customSubnet != null) {
        subnet = customSubnet;
      } else {
        // Get device IP address
        String? deviceIP = await getDeviceIP();

        if (deviceIP == null) {
          throw Exception('Failed to get device IP address');
        }

        // Extract the subnet from the IP
        subnet = deviceIP.substring(0, deviceIP.lastIndexOf('.'));
      }

      // Validate host range
      if (startHost < 1 ||
          startHost > 254 ||
          endHost < 1 ||
          endHost > 254 ||
          startHost > endHost) {
        throw Exception('Invalid host range. Must be between 1 and 254.');
      }

      int totalHosts = endHost - startHost + 1;
      int scannedHosts = 0;

      // Create a list of futures for scanning each IP
      List<Future<void>> scanFutures = [];

      // Get device IP to skip it (optional)
      String? deviceIP;
      if (skipDeviceIP) {
        deviceIP = await getDeviceIP();
      }

      // Scan IP addresses in the specified range
      for (int i = startHost; i <= endHost; i++) {
        final ipToScan = '$subnet.$i';

        // Skip scanning our own IP (optional)
        if (skipDeviceIP && deviceIP != null && ipToScan == deviceIP) {
          scannedHosts++;
          if (onProgressUpdate != null) {
            onProgressUpdate(scannedHosts / totalHosts);
          }
          continue;
        }

        scanFutures.add(checkPort(ipToScan, port, timeout).then((isOpen) {
          if (isOpen) {
            openPortIPs.add(ipToScan);
          }
          scannedHosts++;
          if (onProgressUpdate != null) {
            onProgressUpdate(scannedHosts / totalHosts);
          }
        }));
      }

      // Wait for all scans to complete
      await Future.wait(scanFutures);

      return openPortIPs;
    } catch (e) {
      throw Exception('Error during network scan: ${e.toString()}');
    }
  }

  /// Checks if a specific port is open on a given IP address.
  ///
  /// Parameters:
  /// - [ip]: The IP address to check
  /// - [port]: The port number to check
  /// - [timeout]: Connection timeout in milliseconds
  ///
  /// Returns true if the port is open, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool isOpen = await NetworkScanner.checkPort("192.168.1.1", 80, 200);
  /// ```
  static Future<bool> checkPort(String ip, int port, int timeout) async {
    try {
      // Try to connect to the socket with a timeout
      final socket = await Socket.connect(ip, port,
          timeout: Duration(milliseconds: timeout));

      // If we get here, the connection was successful
      socket.destroy();
      return true;
    } catch (e) {
      // Failed to connect, port is closed or host unreachable
      return false;
    }
  }

  /// Gets the device's IP address (works for both Wi-Fi and Ethernet).
  ///
  /// Returns the device's IP address, or null if it could not be determined.
  ///
  /// Example:
  /// ```dart
  /// String? deviceIP = await NetworkScanner.getDeviceIP();
  /// print('Device IP: $deviceIP');
  /// ```
  static Future<String?> getDeviceIP() async {
    // First try the network_info_plus package (primarily for Wi-Fi)
    try {
      final info = NetworkInfo();
      final String? wifiIP = await info.getWifiIP();

      if (wifiIP != null && wifiIP.isNotEmpty && !wifiIP.startsWith('127.')) {
        return wifiIP;
      }
    } catch (e) {
      print('Error getting Wi-Fi IP: $e');
    }

    // If network_info_plus fails, try getting IP from network interfaces (works for Ethernet)
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // Find the first non-loopback IPv4 address
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting network interfaces: $e');
    }

    return null;
  }

  /// Scans for a single specific port on a single IP address.
  ///
  /// This is a convenience method that combines the functionality of
  /// [checkPort] with proper error handling.
  ///
  /// Parameters:
  /// - [ip]: The IP address to scan
  /// - [port]: The port number to scan
  /// - [timeout]: Connection timeout in milliseconds (default: 200ms)
  ///
  /// Returns true if the port is open, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool serverRunning = await NetworkScanner.scanSinglePort("192.168.1.5", 8080);
  /// ```
  static Future<bool> scanSinglePort(String ip, int port,
      {int timeout = 200}) async {
    try {
      return await checkPort(ip, port, timeout);
    } catch (e) {
      return false;
    }
  }

  /// Scans multiple ports on a single IP address.
  ///
  /// Parameters:
  /// - [ip]: The IP address to scan
  /// - [ports]: List of port numbers to scan
  /// - [timeout]: Connection timeout in milliseconds (default: 200ms)
  /// - [onProgressUpdate]: Optional callback function that reports scan progress from 0.0 to 1.0
  ///
  /// Returns a list of open port numbers.
  ///
  /// Example:
  /// ```dart
  /// List<int> openPorts = await NetworkScanner.scanMultiplePorts(
  ///   "192.168.1.1",
  ///   [80, 443, 8080, 22],
  /// );
  /// ```
  static Future<List<int>> scanMultiplePorts(
    String ip,
    List<int> ports, {
    int timeout = 200,
    Function(double)? onProgressUpdate,
  }) async {
    final List<int> openPorts = [];

    try {
      int totalPorts = ports.length;
      int scannedPorts = 0;

      List<Future<void>> scanFutures = [];

      for (int port in ports) {
        scanFutures.add(checkPort(ip, port, timeout).then((isOpen) {
          if (isOpen) {
            openPorts.add(port);
          }
          scannedPorts++;
          if (onProgressUpdate != null) {
            onProgressUpdate(scannedPorts / totalPorts);
          }
        }));
      }

      await Future.wait(scanFutures);

      return openPorts;
    } catch (e) {
      throw Exception('Error during port scan: ${e.toString()}');
    }
  }
}
