import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:logger/logger.dart';

class DartboardPage extends StatefulWidget {
  const DartboardPage({super.key});

  @override
  _DartboardPageState createState() => _DartboardPageState();
}

class _DartboardPageState extends State<DartboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();
  String _selectedDartBoard = "";
  bool _isSaving = false;
  List<String> _dartBoards = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDartboard();
    _loadDartboardList();
    _logger.i("DartboardPage initState called");
  }

  @override
  void dispose() {
    _logger.i("DartboardPage dispose called");
    super.dispose();
  }

  Future<void> _loadDartboard() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _selectedDartBoard = userData["dartBoard"] ?? AppLocalizations.of(context)!.dartlive;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingDartboard}: $e";
        });
      }
      _logger.e("Error loading dartboard: $e");
    }
  }

  Future<void> _loadDartboardList() async {
    try {
      List<String> boards = await _firestoreService.getDartboardList();
      if (boards.isNotEmpty && mounted) {
        setState(() {
          _dartBoards = boards;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.noDartboardList;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingDartboardList}: $e";
        });
      }
      _logger.e("Error loading dartboard list: $e");
    }
  }

  Future<void> _saveDartboard() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _firestoreService.updateUserData({
        "dartBoard": _selectedDartBoard,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.dartboardSaved)),
        );
        Navigator.pop(context, _selectedDartBoard);
      }
      _logger.i("Dartboard saved: $_selectedDartBoard");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.saveFailed}: $e";
        });
      }
      _logger.e("Error saving dartboard: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.dartboardSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _errorMessage != null
                  ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
                  : _dartBoards.isEmpty
                  ? Center(
                child: Text(
                  AppLocalizations.of(context)!.noDartboardList,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _dartBoards.length,
                itemBuilder: (context, index) {
                  String dartBoard = _dartBoards[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: RadioListTile<String>(
                      title: Text(
                        _translateDartBoard(context, dartBoard),
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      value: dartBoard,
                      groupValue: _selectedDartBoard,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDartBoard = value;
                          });
                        }
                      },
                      activeColor: Theme.of(context).primaryColor,
                      selected: _selectedDartBoard == dartBoard,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
            if (_errorMessage != null && _dartBoards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveDartboard,
                  icon: _isSaving
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    AppLocalizations.of(context)!.save,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateDartBoard(BuildContext context, String board) {
    switch (board) {
      case "다트라이브":
        return AppLocalizations.of(context)!.dartlive;
      case "피닉스":
        return AppLocalizations.of(context)!.phoenix;
      case "그란보드":
        return AppLocalizations.of(context)!.granboard;
      case "홈보드":
        return AppLocalizations.of(context)!.homeboard;
      default:
        return board;
    }
  }
}