import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:logger/logger.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();
  int _selectedRating = 1;
  bool _isSaving = false;
  bool _isLoaded = false;
  int _maxRating = 30;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRating();
    _loadMaxRating();
    _logger.i("RatingPage initState called");
  }

  @override
  void dispose() {
    _logger.i("RatingPage dispose called");
    super.dispose();
  }

  Future<void> _loadRating() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _selectedRating = userData["rating"] ?? 1;
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingRating}: $e";
          _isLoaded = true;
        });
      }
      _logger.e("Error loading rating: $e");
    }
  }

  Future<void> _loadMaxRating() async {
    try {
      setState(() {
        _maxRating = 30; // Firestore 대신 로컬에서 고정
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingMaxRating}: $e";
        });
      }
      _logger.e("Error loading max rating: $e");
    }
  }

  Future<void> _saveRating() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.updateUserData({
        "rating": _selectedRating,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.ratingSaved)),
        );
        Navigator.pop(context, _selectedRating);
      }
      _logger.i("Rating saved: $_selectedRating");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.saveFailed}: $e";
        });
      }
      _logger.e("Error saving rating: $e");
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
          AppLocalizations.of(context)!.ratingSettings,
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
              child: _errorMessage != null && !_isLoaded
                  ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
                  : !_isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _maxRating,
                itemBuilder: (context, index) {
                  final rating = index + 1;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: RadioListTile<int>(
                      title: Text(
                        "${AppLocalizations.of(context)!.rating} $rating",
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      value: rating,
                      groupValue: _selectedRating,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRating = value;
                          });
                        }
                      },
                      activeColor: Theme.of(context).primaryColor,
                      selected: _selectedRating == rating,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
            if (_errorMessage != null && _isLoaded)
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
                  onPressed: _isSaving ? null : _saveRating,
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
}