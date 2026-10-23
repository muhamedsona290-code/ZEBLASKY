import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'main.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const sageLight = Color(0xFFE8F3EB);
const concern = Color(0xFFA56D24);
const emergency = Color(0xFFC53030);

class CustomizeElderTab extends StatefulWidget {
  const CustomizeElderTab({super.key});

  @override
  State<CustomizeElderTab> createState() => _CustomizeElderTabState();
}

class _CustomizeElderTabState extends State<CustomizeElderTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _consent = true;
  DateTime? _consentAt;
  bool _loaded = false;
  bool _saving = false;
  String? _phoneValidationMessage;
  bool _isPhoneValid = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row = await db.from('elders').select().eq('id', elderId).maybeSingle();
    if (row != null && mounted) {
      final phone = (row['phone'] ?? '+91').toString();
      final name = (row['name'] ?? 'Lakshmi Amma').toString();
      final consentVal = row['consent'] == true;
      final consentAtStr = row['consent_at']?.toString();

      setState(() {
        _nameCtrl.text = name;
        _phoneCtrl.text = phone;
        _consent = consentVal;
        _consentAt = consentAtStr != null ? DateTime.tryParse(consentAtStr)?.toLocal() : null;
        _loaded = true;
      });
      _validatePhone(phone);
    }
  }

  void _validatePhone(String val) {
    final cleaned = val.trim();
    if (cleaned.isEmpty) {
      setState(() {
        _phoneValidationMessage = 'Phone number is required';
        _isPhoneValid = false;
      });
      return;
    }

    // RegEx for Indian mobile: +91 followed by 10 digits starting with 6-9
    final reg = RegExp(r'^\+91[6-9]\d{9}$');
    if (reg.hasMatch(cleaned)) {
      setState(() {
        _phoneValidationMessage = 'Valid Indian mobile number (+91XXXXXXXXXX)';
        _isPhoneValid = true;
      });
    } else {
      setState(() {
        _phoneValidationMessage = 'Must be +91 followed by 10 digits (e.g. +919876543210)';
        _isPhoneValid = false;
      });
    }
  }

  void _autoFixPhone() {
    var raw = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.startsWith('91') && raw.length == 12) {
      raw = raw.substring(2);
    }
    if (raw.length == 10) {
      _phoneCtrl.text = '+91$raw';
      _validatePhone(_phoneCtrl.text);
    }
  }

  Future<void> _save() async {
    _validatePhone(_phoneCtrl.text);
    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the phone number format before saving.')),
      );
      return;
    }

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elder name cannot be empty.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final nowUtc = DateTime.now().toUtc();
      await db.from('elders').upsert({
        'id': elderId,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'consent': _consent,
        'consent_at': nowUtc.toIso8601String(),
      });
      setState(() => _consentAt = nowUtc.toLocal());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elder profile & phone number saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5F1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sage.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: sage, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This phone number is synchronized across all family devices, automated schedules, and Exotel voice check-ins.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Elder Name Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elder Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: olive),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Lakshmi Amma',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Phone Number Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Primary Phone Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: olive),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Automated IVR calls and SMS alerts will be sent to this number.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  onChanged: _validatePhone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number (+91 format)',
                    hintText: '+919876543210',
                    prefixIcon: const Icon(Icons.phone_iphone),
                    border: const OutlineInputBorder(),
                    suffixIcon: _isPhoneValid
                        ? const Icon(Icons.check_circle, color: sage)
                        : const Icon(Icons.error_outline, color: concern),
                  ),
                ),
                if (_phoneValidationMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _phoneValidationMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isPhoneValid ? sage : emergency,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _autoFixPhone,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Format to +91', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Consent Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Consent & Authorization',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: olive),
                    ),
                    Switch(
                      value: _consent,
                      activeThumbColor: sage,
                      onChanged: (v) => setState(() => _consent = v),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lakshmi Amma has given consent to receive automated check-in voice calls, emergency escalation alerts, and neighbor notifications.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                if (_consentAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Consent recorded: ${DateFormat('d MMMM y, h:mm a').format(_consentAt!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Save Button
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: olive,
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save),
          label: Text(
            _saving ? 'Saving changes…' : 'Save Elder Details & Phone',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
