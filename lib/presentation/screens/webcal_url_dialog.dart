import 'package:material_ui/material_ui.dart';

import '../localization/app_strings.dart';

class WebcalUrlDialog extends StatefulWidget {
  const WebcalUrlDialog({super.key});

  @override
  State<WebcalUrlDialog> createState() => _WebcalUrlDialogState();
}

class _WebcalUrlDialogState extends State<WebcalUrlDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AlertDialog(
      title: Text(strings.connectWebcal),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: strings.webcalUrl),
          validator: (value) {
            final url = Uri.tryParse(value?.trim() ?? '');
            if (url == null ||
                url.host.isEmpty ||
                (url.scheme != 'webcal' && url.scheme != 'https')) {
              return strings.webcalUrl;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(strings.connectWebcal),
        ),
      ],
    );
  }
}
