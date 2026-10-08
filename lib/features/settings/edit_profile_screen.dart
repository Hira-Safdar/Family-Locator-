import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/custom_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  bool _loading = true;
  bool _locked = false;
  bool _showNameError = false;
  String? _error;
  String? _existingPhotoUrl;
  String? _pickedPath;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final doc = await ref.read(userDocProvider(uid).future);
    if (!mounted) return;
    setState(() {
      _nameController.text = doc?['name'] as String? ?? '';
      _existingPhotoUrl = doc?['photoUrl'] as String?;
      _loading = false;
    });
  }

  Future<void> _showPhotoSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 70,
    );
    if (file == null || !mounted) return;
    setState(() => _pickedPath = file.path);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    setState(() {
      _locked = true;
      _showNameError = false;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            name: name,
            photoFilePath: _pickedPath,
          );
      ref.invalidate(userDocProvider);
      ref.invalidate(userNameProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locked = false;
        _error = e is Failure ? e.message : 'Could not save changes.';
      });
    }
  }

  Widget _initialLetter() {
    final name = _nameController.text.trim();
    return Text(
      name.isEmpty ? '?' : name[0].toUpperCase(),
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _avatarChild() {
    final path = _pickedPath;
    if (path != null) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: 88,
        height: 88,
      );
    }
    final stored = _existingPhotoUrl;
    if (stored == null || stored.isEmpty) return _initialLetter();

    if (stored.startsWith('data:')) {
      final comma = stored.indexOf(',');
      Uint8List? bytes;
      if (comma != -1) {
        try {
          bytes = base64Decode(stored.substring(comma + 1));
        } catch (_) {
          bytes = null;
        }
      }
      if (bytes == null) return _initialLetter();
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 88,
        height: 88,
        errorBuilder: (_, _, _) => _initialLetter(),
      );
    }
    return Image.network(
      stored,
      fit: BoxFit.cover,
      width: 88,
      height: 88,
      errorBuilder: (_, _, _) => _initialLetter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _nameController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.background,
                        child: ClipOval(child: _avatarChild()),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _locked ? null : _showPhotoSheet,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  enabled: !_locked,
                  maxLength: 40,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Display name',
                    counterText: '',
                    errorText:
                        _showNameError && name.isEmpty ? 'Enter your name' : null,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Save',
                  isLoading: _locked,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
