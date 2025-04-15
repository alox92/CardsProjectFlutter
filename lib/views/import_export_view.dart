import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../utils/logger.dart';

class ImportExportView extends StatefulWidget {
  @override
  _ImportExportViewState createState() => _ImportExportViewState();
}

class _ImportExportViewState extends State<ImportExportView> {
  final Logger _logger = Logger();
  bool _isBusy = false;
  String _statusMessage = '';
  bool _hasError = false;
  double _progress = 0.0;

  Future<void> _exportCards() async {
    setState(() {
      _isBusy = true;
      _statusMessage = 'Préparation de l\'export...';
      _progress = 0.0;
      _hasError = false;
    });

    try {
      final db = Provider.of<DatabaseHelper>(context, listen: false);
      
      setState(() {
        _statusMessage = 'Génération du CSV...';
        _progress = 0.3;
      });
      
      final csv = await db.exportToCsv();
      
      setState(() {
        _statusMessage = 'Choix de l\'emplacement...';
        _progress = 0.5;
      });
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter les cartes (CSV)',
        fileName: 'flashcards_${DateTime.now().toIso8601String()}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _statusMessage = 'Enregistrement...';
          _progress = 0.8;
        });
        
        final file = File(result);
        await file.writeAsString(csv);
        
        _logger.info('Export réussi vers: $result');
        
        setState(() {
          _statusMessage = 'Export réussi!';
          _progress = 1.0;
        });
      } else {
        setState(() {
          _statusMessage = 'Export annulé';
          _progress = 0.0;
        });
      }
    } catch (e) {
      _logger.error('Erreur lors de l\'export: $e');
      setState(() {
        _statusMessage = 'Erreur: $e';
        _hasError = true;
      });
    } finally {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isBusy = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Importation / Exportation'),
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text('Exporter vers CSV'),
                onPressed: _exportCards,
              ),
              SizedBox(height: 16),
              if (_isBusy) ...[
                LinearProgressIndicator(value: _progress),
                SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _hasError ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
