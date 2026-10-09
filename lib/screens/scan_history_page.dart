import 'dart:io';

import 'package:flutter/material.dart';

import '../services/image_storage_service.dart';
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
    _scans = DatabaseHelper.instance.getAllScans();
  }

  void _loadScans() async {
    setState(() {
      _scans = DatabaseHelper.instance.getAllScans();
    });
  }

  Future<void> _deleteScan(Scan scan) async {
    if (scan.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Scan?'),
          content: const Text(
            'This will permanently delete this scan, '
            'its predictions, and its saved image.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      // Remove the scan and its predictions from SQLite.
      await DatabaseHelper.instance.deleteScan(scan.id!);

      // Remove the saved image.
      await ImageStorageService.deleteImage(scan.imagePath);

      // Refresh the displayed history.
      _loadScans();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete scan: $e'),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    final future = DatabaseHelper.instance.getAllScans();

    setState(() {
      _scans = future;
    });

    await future;
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
                    'Scan #${scans.length - index}',
                  ),

                  subtitle: Text(
                    _formatDate(scan.scannedAt),
                  ),

                  // trailing: const Icon(
                  //   Icons.chevron_right,
                  // ),

                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete scan',
                    onPressed: () => _deleteScan(scan),
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanDetailPage(
                          scanId: scan.id!,
                          displayNumber: scans.length - index,
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