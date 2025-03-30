import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:logger/logger.dart';

class HomeShopPage extends StatefulWidget {
  const HomeShopPage({super.key});

  @override
  _HomeShopPageState createState() => _HomeShopPageState();
}

class _HomeShopPageState extends State<HomeShopPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _homeShopController = TextEditingController();
  final Logger _logger = Logger();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeShop();
    _logger.i("HomeShopPage initState called");
  }

  Future<void> _loadHomeShop() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _homeShopController.text = userData["homeShop"] ?? "";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingHomeShop}: $e";
        });
      }
      _logger.e("Error loading home shop: $e");
    }
  }

  bool _isValidHomeShop(String homeShop) {
    return homeShop.trim().length >= 2 && homeShop.trim().length <= 30;
  }

  void _validateHomeShop(String value) {
    if (value.isNotEmpty && !_isValidHomeShop(value)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.invalidHomeShopLength;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _saveHomeShop() async {
    String newHomeShop = _homeShopController.text.trim();

    if (newHomeShop.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.enterHomeShop);
      return;
    }

    if (!_isValidHomeShop(newHomeShop)) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.invalidHomeShopLength);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.updateUserData({"homeShop": newHomeShop});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.homeShopSaved)),
        );
        _homeShopController.clear();
        Navigator.pop(context, newHomeShop);
      }
      _logger.i("Home shop saved: $newHomeShop");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.saveFailed}: $e";
        });
      }
      _logger.e("Error saving home shop: $e");
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
          AppLocalizations.of(context)!.homeShopSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _homeShopController,
                    maxLength: 30,
                    onChanged: _validateHomeShop,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.newHomeShop,
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      errorText: _errorMessage,
                    ),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveHomeShop,
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _homeShopController.dispose();
    super.dispose();
  }
}