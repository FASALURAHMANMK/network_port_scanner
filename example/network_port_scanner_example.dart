// example/network_port_scanner_example.dart
import 'package:flutter/material.dart';
import 'package:network_port_scanner/network_port_scanner.dart';

void main() {
  runApp(const PortScannerExampleApp());
}

class PortScannerExampleApp extends StatelessWidget {
  const PortScannerExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Port Scanner Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PortScannerExample(),
    );
  }
}

class PortScannerExample extends StatefulWidget {
  const PortScannerExample({Key? key}) : super(key: key);

  @override
  State<PortScannerExample> createState() => _PortScannerExampleState();
}

class _PortScannerExampleState extends State<PortScannerExample> {
  final List<String> _openPortIPs = [];
  bool _isScanning = false;
  String _statusMessage = '';
  double _progress = 0.0;
  int _selectedPort = 80;
  final List<int> _commonPorts = [80, 443, 8080, 22, 21, 25, 3306, 3389];

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _openPortIPs.clear();
      _statusMessage = 'Starting scan...';
      _progress = 0.0;
    });

    try {
      // Use the NetworkScanner to scan for open ports
      final List<String> results = await NetworkScanner.scanNetwork(
        port: _selectedPort,
        timeout: 200,
        onProgressUpdate: (progress) {
          setState(() {
            _progress = progress;
            _statusMessage =
                'Scanning: ${(progress * 100).toStringAsFixed(1)}% complete';
          });
        },
      );

      setState(() {
        _openPortIPs.addAll(results);
        if (_openPortIPs.isEmpty) {
          _statusMessage = 'No devices found with port $_selectedPort open';
        } else {
          _statusMessage =
              'Found ${_openPortIPs.length} device(s) with port $_selectedPort open';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isScanning = false;
        _progress = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Port Scanner Example'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Port Scanner',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<int>(
                      value: _selectedPort,
                      hint: const Text('Select Port'),
                      isExpanded: true,
                      items: _commonPorts.map((port) {
                        return DropdownMenuItem<int>(
                          value: port,
                          child: Text('Port $port'),
                        );
                      }).toList(),
                      onChanged: _isScanning
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPort = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    _isScanning
                        ? Column(
                            children: [
                              LinearProgressIndicator(value: _progress),
                              const SizedBox(height: 8),
                              Text(_statusMessage),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isScanning = false;
                                    _statusMessage = 'Scan cancelled';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Text(_statusMessage),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _startScan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Start Scan'),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Devices with Port $_selectedPort Open:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _openPortIPs.isEmpty
                  ? const Center(
                      child: Text('No devices found'),
                    )
                  : ListView.builder(
                      itemCount: _openPortIPs.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.computer),
                            title: Text(_openPortIPs[index]),
                            subtitle: Text('Port $_selectedPort is open'),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_browser),
                              onPressed: () {
                                final url =
                                    'http://${_openPortIPs[index]}:$_selectedPort';
                                // Open URL logic would go here
                                // (typically using url_launcher package)
                                debugPrint('Would open URL: $url');
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
