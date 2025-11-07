import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/repertoire.dart';
import '../../data/services/database_helper.dart';
import '../providers/repertoire_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';

/// Screen for adding or editing a repertoire
class AddRepertoireScreen extends StatefulWidget {
  final Repertoire? repertoire;

  const AddRepertoireScreen({super.key, this.repertoire});

  @override
  State<AddRepertoireScreen> createState() => _AddRepertoireScreenState();
}

class _AddRepertoireScreenState extends State<AddRepertoireScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController();
  late final _descriptionController = TextEditingController();
  late final _eventDateController = TextEditingController();

  bool _isSaving = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  /// Initialize form with existing repertoire data if editing
  void _initializeForm() {
    if (widget.repertoire != null) {
      final repertoire = widget.repertoire!;
      _nameController.text = repertoire.name;
      _descriptionController.text = repertoire.description ?? '';
      if (repertoire.eventDate != null) {
        _selectedDate = repertoire.eventDate;
        _eventDateController.text = repertoire.eventDateDisplay;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  /// Save the repertoire to database (create or update)
  Future<void> _saveRepertoire() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final databaseHelper = DatabaseHelper();

      if (widget.repertoire != null) {
        // Update existing repertoire
        final updatedRepertoire = widget.repertoire!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          eventDate: _selectedDate,
          updatedAt: DateTime.now(),
        );

        final rowsAffected = await databaseHelper.updateRepertoire(
          updatedRepertoire,
        );

        if (rowsAffected > 0) {
          final repertoireProvider = Provider.of<RepertoireProvider>(
            context,
            listen: false,
          );
          await repertoireProvider.loadRepertoires();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Répertoire modifié avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('Failed to update repertoire in database');
        }
      } else {
        // Create new repertoire
        final repertoire = Repertoire.create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          eventDate: _selectedDate,
        );

        final repertoireId = await databaseHelper.insertRepertoire(repertoire);

        if (repertoireId != null) {
          final repertoireProvider = Provider.of<RepertoireProvider>(
            context,
            listen: false,
          );
          await repertoireProvider.loadRepertoires();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Répertoire créé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('Failed to save repertoire to database');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Show date picker for event date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _eventDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? Color(AppColors.backgroundDark)
          : Color(AppColors.backgroundLight),
      appBar: AppBar(
        backgroundColor: isDark
            ? Color(AppColors.backgroundDark)
            : Color(AppColors.backgroundLight),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.repertoire != null
              ? 'Modifier le répertoire'
              : 'Créer un répertoire',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            color: Colors.orange,
            onPressed: _isSaving ? null : _saveRepertoire,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              Text(
                'Nom du répertoire *',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Entrez le nom du répertoire',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom du répertoire est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              Text(
                'Description',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Description optionnelle du répertoire',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event date field
              Text(
                'Date de l\'événement',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _eventDateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Sélectionner une date',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveRepertoire,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.repertoire != null ? 'Modifier' : 'Créer',
                          style: AppTextStyles.buttonLarge,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
