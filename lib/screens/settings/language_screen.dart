import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const _languages = [
    ('English', true),
    ('Arabic (العربية)', false),
    ('French (Français)', false),
    ('German (Deutsch)', false),
    ('Spanish (Español)', false),
    ('Portuguese (Português)', false),
    ('Italian (Italiano)', false),
    ('Japanese (日本語)', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Language', style: AppTextStyles.heading2),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select your preferred language.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _languages.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final (name, isActive) = _languages[index];
                return ListTile(
                  tileColor: AppColors.surface,
                  title: Text(
                    name,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isActive
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 22,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                  onTap: isActive
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Only English is available for now.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
