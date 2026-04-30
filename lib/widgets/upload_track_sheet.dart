import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/track_provider.dart';

class UploadTrackSheet extends ConsumerStatefulWidget {
  const UploadTrackSheet({super.key});

  @override
  ConsumerState<UploadTrackSheet> createState() => _UploadTrackSheetState();
}

class _UploadTrackSheetState extends ConsumerState<UploadTrackSheet> {
  String? filePath;
  String? fileName;

  String? coverImagePath;
  String? coverImageName;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      allowMultiple: false,
    );

    if (result == null) return;

    final pickedPath = result.files.single.path;

    if (pickedPath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected audio file.')),
      );
      return;
    }

    setState(() {
      filePath = pickedPath;
      fileName = result.files.single.name;
    });
  }

  Future<void> pickCoverImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );

    if (result == null) return;

    final pickedPath = result.files.single.path;

    if (pickedPath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected cover image.')),
      );
      return;
    }

    setState(() {
      coverImagePath = pickedPath;
      coverImageName = result.files.single.name;
    });
  }

  Future<void> upload() async {
    final String title = titleController.text.trim();
    final String description = descController.text.trim();

    if (filePath == null || filePath!.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an audio file and enter a title.'),
        ),
      );
      return;
    }

    try {
      await ref
          .read(createTrackProvider.notifier)
          .create(
            title: title,
            description: description,
            filePath: filePath!,
            coverImagePath: coverImagePath,
          );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      final String message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(createTrackProvider);
    final bool isUploading = uploadState.isLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload Track',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),

              GestureDetector(
                onTap: isUploading ? null : pickCoverImage,
                child: Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: coverImagePath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white70,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add cover',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(coverImagePath!),
                            width: 135,
                            height: 135,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              if (coverImagePath != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: isUploading ? null : pickCoverImage,
                  icon: const Icon(Icons.edit, size: 17),
                  label: Text(
                    coverImageName == null ? 'Change cover' : 'Change cover',
                  ),
                ),
              ],

              const SizedBox(height: 18),

              TextField(
                controller: titleController,
                enabled: !isUploading,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: descController,
                enabled: !isUploading,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : pickAudioFile,
                  icon: const Icon(Icons.audio_file),
                  label: Text(fileName ?? 'Pick Audio File'),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isUploading ? null : upload,
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}