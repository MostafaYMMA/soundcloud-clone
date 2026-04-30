import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Legal', style: AppTextStyles.heading2),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Privacy'),
              Tab(text: 'Terms'),
              Tab(text: 'Cookies'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LegalPage(
              title: 'Privacy Policy',
              body:
                  'We respect your privacy. We collect only the data necessary '
                  'to provide our service — account information, usage data, and '
                  'playback history. We do not sell your personal data to third '
                  'parties.\n\n'
                  'Your data may be used to personalise your experience, improve '
                  'our platform, and comply with legal obligations.\n\n'
                  'You may request deletion of your account and all associated '
                  'data at any time by contacting our support team.\n\n'
                  'We use industry-standard encryption to protect data in transit '
                  'and at rest. Access to personal data is restricted to '
                  'authorised personnel only.',
            ),
            _LegalPage(
              title: 'Terms of Use',
              body:
                  'By using this application you agree to these terms. You must '
                  'be at least 13 years old to create an account.\n\n'
                  'You are responsible for all activity that occurs under your '
                  'account. Do not share your credentials with others.\n\n'
                  'You may not use this service to upload, share, or stream '
                  'content that infringes copyright, contains hate speech, or '
                  'violates applicable law.\n\n'
                  'We reserve the right to suspend or terminate accounts that '
                  'violate these terms at our sole discretion.\n\n'
                  'The service is provided "as is" without warranties of any '
                  'kind. We are not liable for interruptions to the service.',
            ),
            _LegalPage(
              title: 'Cookie Policy',
              body:
                  'We use cookies and similar tracking technologies to operate '
                  'and improve our service.\n\n'
                  'Essential cookies are required for the app to function '
                  'correctly — for example, to keep you logged in.\n\n'
                  'Analytics cookies help us understand how users interact with '
                  'the app so we can improve it. These can be disabled in your '
                  'device settings.\n\n'
                  'We do not use advertising cookies or sell cookie data to '
                  'third-party advertisers.\n\n'
                  'By continuing to use the app you consent to our use of '
                  'essential cookies.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String body;

  const _LegalPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
