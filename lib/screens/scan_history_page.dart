import 'dart:io';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/scan.dart';
import 'scan_detail_page.dart';

class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({super.key});

  @override
  State<ScanHistoryPage> createState() =>
      _ScanHistoryPageState();
}

class _ScanHistoryPageState
    extends State<ScanHistoryPage> {

  late Future<List<Scan>> _scans;

  @override
  void initState() {
    super.initState();

    _loadScans();
  }

  void _loadScans() {
    _scans = DatabaseHelper.instance.getAllScans();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadScans();
    });

    await _scans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xff008d55),
        iconTheme: IconThemeData(
          color: Colors.white
        ),
      ),

      body: FutureBuilder<List<Scan>>(
        future: _scans,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading scans:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final scans = snapshot.data ?? [];

          if (scans.isEmpty) {
            return const Center(
              child: Text(
                'No scans yet.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xff008d55)
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Color(0xff008d55),

            child: ListView.builder(
              itemCount: scans.length,

              itemBuilder: (context, index) {
                final scan = scans[index];

                return ListTile(
                  leading: _buildThumbnail(
                    scan.imagePath,
                  ),

                  title: Text(
                    'Scan #${scan.id}',
                  ),

                  subtitle: Text(
                    _formatDate(scan.scannedAt),
                  ),

                  trailing: const Icon(
                    Icons.chevron_right,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanDetailPage(
                          scanId: scan.id!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(String imagePath) {
    final file = File(imagePath);

    if (!file.existsSync()) {
      return const SizedBox(
        width: 60,
        height: 60,
        child: Icon(
          Icons.image_not_supported,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),

      child: Image.file(
        file,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}