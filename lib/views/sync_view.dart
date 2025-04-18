import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:projet/services/database_helper.dart';
import 'package:projet/features/sync/services/sync_types.dart';
import '../services/sync_service.dart';
import '../services/firebase_manager.dart';
import '../utils/logger.dart';
import '../features/sync/helpers/sync_stat_grid.dart';
import '../features/sync/helpers/sync_info_row.dart';

class SyncView extends StatefulWidget {
  @override
  _SyncViewState createState() => _SyncViewState();
}

class _SyncViewState extends State<SyncView> {
  final Logger _logger = Logger();
  late SyncService _syncService;
  
  bool _isSyncing = false;
  String _statusMessage = 'Prêt à synchroniser';
  double _progress = 0.0;
  String _lastUploadTime = 'Jamais';
  String _lastDownloadTime = 'Jamais';
  Map<String, dynamic> _syncStats = {};
  StreamSubscription<SyncEvent>? _syncEventSubscription;
  
  int _sliderBatchSize = 50;

  @override
  void initState() {
    super.initState();
    _syncService = SyncService(
      Provider.of<DatabaseHelper>(context, listen: false),
      Provider.of<FirebaseManager>(context, listen: false),
    );
    
    _syncEventSubscription = _syncService.syncEvents.listen(_handleSyncEvent);
    _loadSyncStatus();
  }

  @override
  void dispose() {
    _syncEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final status = await _syncService.getSyncStatus();
      setState(() {
        _lastUploadTime = status['lastUploadDate'];
        _lastDownloadTime = status['lastDownloadDate'];
        _sliderBatchSize = status['maxBatchSize'];
        _isSyncing = status['syncInProgress'];
      });
    } catch (e) {
      _logger.error('Error loading sync status: $e');
    }
  }

  void _handleSyncEvent(SyncEvent event) {
    setState(() {
      switch (event.type) {
        case SyncEventType.started:
          _isSyncing = true;
          _statusMessage = 'Synchronisation démarrée...';
          _progress = 0.0;
          break;
          
        case SyncEventType.uploadStarted:
          _statusMessage = 'Envoi des modifications vers le cloud...';
          _progress = 0.1;
          break;
          
        case SyncEventType.uploadProgress:
          _statusMessage = event.message;
          _progress = 0.1 + ((event.progress ?? 0.0) * 0.4); // 10-50%
          break;
          
        case SyncEventType.downloadStarted:
          _statusMessage = 'Téléchargement des modifications depuis le cloud...';
          _progress = 0.5;
          break;
          
        case SyncEventType.downloadProgress:
          _statusMessage = event.message;
          _progress = 0.5 + ((event.progress ?? 0.0) * 0.4); // 50-90%
          break;
          
        case SyncEventType.completed:
          _isSyncing = false;
          _statusMessage = 'Synchronisation terminée avec succès';
          _progress = 1.0;
          _loadSyncStatus(); // Refresh status data
          break;
          
        case SyncEventType.completedWithErrors:
          _isSyncing = false;
          _statusMessage = 'Synchronisation terminée avec des avertissements: ${event.message}';
          _progress = 1.0;
          _loadSyncStatus();
          break;
          
        case SyncEventType.failed:
          _isSyncing = false;
          _statusMessage = 'Échec de la synchronisation: ${event.message}';
          _progress = 0.0;
          _loadSyncStatus();
          break;
          
        default:
          break;
      }
    });
  }

  Future<void> _startSync() async {
    if (_isSyncing) return; // Avoid multiple syncs
    
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Préparation de la synchronisation...';
      _progress = 0.0;
      _syncStats = {};
    });
    
    try {
      final result = await _syncService.synchronize();
      
      setState(() {
        _syncStats = result.toJson();
      });
      
      // Status is already updated via event subscription
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Erreur de synchronisation: $e';
        _progress = 0.0;
      });
      _logger.error('Error during sync: $e');
    }
  }

  Future<void> _resetSyncState() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réinitialiser la synchronisation'),
        content: Text('Cette action effacera l\'historique de synchronisation, '
            'ce qui forcera une synchronisation complète lors de la prochaine exécution. '
            'Continuer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Réinitialiser'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldReset) {
      try {
        await _syncService.resetSyncState();
        setState(() {
          _lastUploadTime = 'Jamais';
          _lastDownloadTime = 'Jamais';
          _statusMessage = 'État de synchronisation réinitialisé';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réinitialisation réussie')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la réinitialisation: $e')),
        );
      }
    }
  }

  Future<void> _updateBatchSize(int value) async {
    try {
      _syncService.setBatchSize(value);
      setState(() {
        _sliderBatchSize = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de mise à jour: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Synchronisation Cloud'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 600,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'État de la Synchronisation',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow('Dernier envoi vers le cloud:', _lastUploadTime),
                        SizedBox(height: 8),
                        _buildInfoRow('Dernier téléchargement du cloud:', _lastDownloadTime),
                        SizedBox(height: 16),
                        Text(_statusMessage),
                        SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _isSyncing ? _progress : null,
                          minHeight: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Settings card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paramètres',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 16),
                        Text('Taille des lots de synchronisation: $_sliderBatchSize'),
                        Slider(
                          min: 10,
                          max: 100,
                          divisions: 9,
                          value: _sliderBatchSize.toDouble(),
                          onChanged: _isSyncing ? null : (value) {
                            setState(() {
                              _sliderBatchSize = value.round();
                            });
                          },
                          onChangeEnd: _isSyncing ? null : (value) {
                            _updateBatchSize(value.round());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Stats card (visible only after sync)
                if (_syncStats.isNotEmpty) 
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résultats de la dernière synchronisation',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          SizedBox(height: 16),
                          _buildStatGrid(),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: 32),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(_isSyncing ? Icons.hourglass_top : Icons.sync),
                      label: Text(_isSyncing ? 'Synchronisation en cours...' : 'Synchroniser'),
                      onPressed: _isSyncing ? null : _startSync,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    SizedBox(width: 16),
                    OutlinedButton.icon(
                      icon: Icon(Icons.restore),
                      label: Text('Réinitialiser'),
                      onPressed: _isSyncing ? null : _resetSyncState,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return SyncInfoRow(label: label, value: value);
  }
  
  Widget _buildStatGrid() {
    if (_syncStats['stats'] == null) {
      return Text('Aucune statistique disponible');
    }
    final stats = _syncStats['stats'];
    return SyncStatGrid(stats: stats);
  }
}
