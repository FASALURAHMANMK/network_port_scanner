import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:network_port_scanner/network_port_scanner.dart';

@GenerateMocks([])
void main() {
  group('NetworkScanner', () {
    test('checkPort returns expected result for localhost', () async {
      // This test assumes nothing is running on port 1 (typically reserved)
      bool closedPort = await NetworkScanner.checkPort('127.0.0.1', 1, 100);
      expect(closedPort, false);

      // Test that getDeviceIP doesn't throw an exception
      try {
        await NetworkScanner.getDeviceIP();
        // Pass if no exception
        expect(true, true);
      } catch (e) {
        fail('getDeviceIP threw an exception: $e');
      }
    });

    test('scanSinglePort handles errors gracefully', () async {
      // Should return false for invalid IP
      bool result = await NetworkScanner.scanSinglePort('invalid-ip', 80);
      expect(result, false);
    });

    test('scanMultiplePorts returns list of integers', () async {
      // Test with localhost and some common ports
      final result = await NetworkScanner.scanMultiplePorts(
        '127.0.0.1',
        [1, 2, 3], // Typically these ports are closed
      );

      // Just verify the result is a list of integers
      expect(result, isA<List<int>>());
    });
  });
}
