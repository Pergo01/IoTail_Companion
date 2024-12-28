import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsAndConditionsText extends StatelessWidget {
  const TermsAndConditionsText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'By logging in, you agree to our ',
            style:
                Theme.of(context).textTheme.bodyMedium, // Adjusted theme style
          ),
          TextSpan(
            text: 'Terms & Conditions',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary, // Highlighted color for the link
                  decoration:
                      TextDecoration.underline, // Underline for the link
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showMarkdownDialog(context, 'Terms & Conditions',
                    'assets/terms_and_conditions.md');
              },
          ),
          TextSpan(
            text: ' and ',
            style:
                Theme.of(context).textTheme.bodyMedium, // Adjusted theme style
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary, // Highlighted color for the link
                  decoration:
                      TextDecoration.underline, // Underline for the link
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showMarkdownDialog(
                    context, 'Privacy Policy', 'assets/privacy_policy.md');
              },
          ),
        ],
      ),
    );
  }

  Future<void> _showMarkdownDialog(
      BuildContext context, String title, String assetPath) async {
    final content = await rootBundle.loadString(assetPath);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Markdown(
              data: content,
              selectable: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
