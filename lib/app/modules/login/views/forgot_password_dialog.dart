import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/app_buttons.dart';

/// Asks for the account's email; closes with it (trimmed) or null on Cancel.
/// Owns its TextEditingController so it is disposed only after the dialog's
/// exit animation (see CLAUDE.md).
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    if (!GetUtils.isEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    closeRoute(email);
  }

  @override
  Widget build(BuildContext context) {
    final size = SizeConfig.defaultSize;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Reset password', style: AppTextStyle.h5(size)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your account's email. We'll send a link to set a new password on the web.",
            style: AppTextStyle.body(size),
          ),
          SizedBox(height: size * 1.4),
          TextField(
            key: const Key('forgotPasswordEmailField'),
            controller: _email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'name@company.com',
              errorText: _error,
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: navyMid),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(size)),
            ),
          ),
        ],
      ),
      actionsPadding: EdgeInsets.fromLTRB(size * 2, 0, size * 2, size * 2),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => closeRoute(),
                child: Text('Cancel', style: AppTextStyle.plain(color: Colors.grey)),
              ),
            ),
            SizedBox(width: size),
            Expanded(
              flex: 2,
              child: KeyedSubtree(
                key: const Key('forgotPasswordSendButton'),
                child: navyButton(size, 'Send link', onPressed: _submit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
