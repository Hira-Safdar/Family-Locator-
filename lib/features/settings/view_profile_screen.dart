import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/profile_avatar.dart';

class ViewProfileScreen extends ConsumerStatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  ConsumerState<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends ConsumerState<ViewProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _editing = false;
  bool _locked = false;
  bool _showNameError = false;
  bool _removePhoto = false;
  String? _error;
  String? _pickedPath;
  String? _photoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEdit(String? currentName, String? currentPhotoUrl, String? phone) {
    setState(() {
      _nameController.text = currentName ?? '';
      _phoneController.text = phone ?? '';
      _photoUrl = currentPhotoUrl;
      _pickedPath = null;
      _removePhoto = false;
      _error = null;
      _showNameError = false;
      _editing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _locked = false;
      _pickedPath = null;
      _removePhoto = false;
      _error = null;
      _showNameError = false;
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

    final file = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 70,
    );
    if (file == null || !mounted) return;
    setState(() {
      _pickedPath = file.path;
      _removePhoto = false;
    });
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
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: name,
            photoFilePath: _pickedPath,
            phone: _phoneController.text.trim(),
            removePhoto: _removePhoto,
          );
      ref.invalidate(userProfileProvider);
      ref.invalidate(userDocProvider);
      ref.invalidate(userNameProvider);
      if (!mounted) return;
      setState(() {
        _locked = false;
        _editing = false;
        _pickedPath = null;
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locked = false;
        _error = e is Failure ? e.message : 'Could not save changes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).value;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profileAsync = ref.watch(userProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Profile' : 'My Profile')),
      body: _editing
          ? _editBody(theme)
          : profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('Could not load your profile. Please try again.'),
              ),
              data: (profile) {
                final name = profile?.name ?? '';
                final email = profile?.email ?? '';
                final phone = profile?.phone ?? '';
                return _viewBody(theme, profile?.photoUrl, name, email, phone);
              },
            ),
    );
  }

  Widget _viewBody(
    ThemeData theme,
    String? photoUrl,
    String name,
    String email,
    String phone,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: ProfileAvatar(name: name, photoUrl: photoUrl, radius: 56),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            name.isEmpty ? 'Your profile' : name,
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textLight,
              ),
            ),
          ),
        ],
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: context.palette.textLight,
                ),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        CustomButton(
          label: 'Edit Profile',
          onPressed: () => _startEdit(name, photoUrl, phone),
        ),
      ],
    );
  }

  Widget _editBody(ThemeData theme) {
    final name = _nameController.text.trim();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Center(child: _editAvatar()),
        if (!_removePhoto &&
            (_pickedPath != null || (_photoUrl?.isNotEmpty ?? false))) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: _locked
                  ? null
                  : () => setState(() {
                      _removePhoto = true;
                      _pickedPath = null;
                    }),
              icon: Icon(Icons.delete_outline, color: context.palette.error),
              label: Text(
                'Remove photo',
                style: TextStyle(color: context.palette.error),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          enabled: !_locked,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Display name',
            counterText: '',
            errorText: _showNameError && name.isEmpty
                ? 'Enter your name'
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          enabled: !_locked,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Phone (optional)',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.error,
            ),
          ),
        ],
        const SizedBox(height: 24),
        CustomButton(label: 'Save', isLoading: _locked, onPressed: _save),
        TextButton(
          onPressed: _locked ? null : _cancelEdit,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _editAvatar() {
    final path = _pickedPath;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (path != null)
          CircleAvatar(
            radius: 48,
            backgroundColor: context.palette.background,
            backgroundImage: FileImage(File(path)),
          )
        else
          ProfileAvatar(
            name: _nameController.text.trim(),
            photoUrl: _removePhoto ? null : _photoUrl,
            radius: 48,
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: context.palette.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _locked ? null : _showPhotoSheet,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: context.palette.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
