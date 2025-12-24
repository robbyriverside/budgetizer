import 'package:flutter/material.dart';

class LoadDataDialog extends StatefulWidget {
  const LoadDataDialog({super.key});

  @override
  State<LoadDataDialog> createState() => _LoadDataDialogState();
}

class _LoadDataDialogState extends State<LoadDataDialog> {
  bool _isLoading = false;
  double _progress = 0.0;
  String _status = "Select a source to load";

  Future<void> _startLoad() async {
    setState(() {
      _isLoading = true;
      _status = "Connecting to Bank...";
      _progress = 0.1;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _status = "Parsing Transactions...";
      _progress = 0.4;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _status = "Analyzing Vendor Tags...";
      _progress = 0.7;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _status = "Done!";
      _progress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Load Financial Data",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select a source to import your transaction history.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white10,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status,
                    style: const TextStyle(color: Colors.tealAccent),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildSourceOption(
                    icon: Icons.account_balance,
                    title: "Connect Bank Account",
                    subtitle: "Via Plaid or similar",
                    onTap: _startLoad,
                  ),
                  const SizedBox(height: 10),
                  _buildSourceOption(
                    icon: Icons.upload_file,
                    title: "Upload Statement",
                    subtitle: "CSV, QIF, OFX",
                    onTap: _startLoad,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
