import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const concern = Color(0xFFA56D24);
const emergency = Color(0xFFC53030);

class FamilyRespondersSheet extends StatefulWidget {
  final String elderName;

  const FamilyRespondersSheet({super.key, required this.elderName});

  @override
  State<FamilyRespondersSheet> createState() => _FamilyRespondersSheetState();
}

class _FamilyRespondersSheetState extends State<FamilyRespondersSheet> {
  static const _prefKey = 'koode_responders_network';
  List<Map<String, dynamic>> _responders = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadResponders();
  }

  Future<void> _loadResponders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List list = jsonDecode(raw);
        setState(() {
          _responders = List<Map<String, dynamic>>.from(list);
          _loaded = true;
        });
        return;
      } catch (_) {}
    }

    // Default seeded circle
    _responders = [
      {
        'id': '1',
        'name': 'Rahul Nair',
        'role': 'Son (Abroad - Dubai)',
        'phone': '+971501234567',
        'tier': 1,
        'badge': 'Primary Caregiver',
      },
      {
        'id': '2',
        'name': 'Ananya Nair',
        'role': 'Daughter (Bengaluru)',
        'phone': '+919847112233',
        'tier': 1,
        'badge': 'Family Admin',
      },
      {
        'id': '3',
        'name': 'Suresh Uncle',
        'role': 'Next-door Neighbor (Kochi)',
        'phone': '+919447001122',
        'tier': 2,
        'badge': 'Key Holder (2 mins away)',
      },
      {
        'id': '4',
        'name': 'Dr. Preethi Mathew',
        'role': 'Family Physician',
        'phone': '+919846334455',
        'tier': 2,
        'badge': 'Local Doctor',
      },
      {
        'id': '5',
        'name': 'Emergency Ambulance Kerala',
        'role': 'Govt Emergency Response',
        'phone': '108',
        'tier': 3,
        'badge': 'Tier 3 Medical',
      },
      {
        'id': '6',
        'name': 'National Emergency Helpline',
        'role': 'Police & Multi-agency',
        'phone': '112',
        'tier': 3,
        'badge': 'Tier 3 Police',
      },
    ];

    await _save();
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(_responders));
  }

  void _addResponderDialog() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int tier = 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Add Trusted Responder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'e.g. Vinod Kumar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Relationship / Role',
                    hintText: 'e.g. Neighbor, Grandchild in US, Caretaker',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'e.g. +919876543210',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Escalation Tier', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: tier,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('Tier 1: Immediate Family (Children abroad/local)'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Tier 2: Trusted Neighbors & Local Relatives'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('Tier 3: Emergency & Medical Services'),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => tier = v ?? 2),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                setState(() {
                  _responders.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameCtrl.text.trim(),
                    'role': roleCtrl.text.trim().isEmpty ? 'Trusted Contact' : roleCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'tier': tier,
                    'badge': tier == 1 ? 'Family' : tier == 2 ? 'Neighbor/Relative' : 'Emergency',
                  });
                });
                await _save();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add to Circle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver & Responder Circle'),
        actions: [
          IconButton(
            tooltip: 'Add contact',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _addResponderDialog,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sage.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: sage, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3-Tier Escalation Network for ${widget.elderName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: olive),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'If an emergency is unacknowledged, Koode automatically notifies Tier 1 -> Tier 2 -> Tier 3 responders.',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildTierSection(
                  tier: 1,
                  title: 'Tier 1: Immediate Family (Living Abroad & Locally)',
                  subtitle: 'First alerts sent via call, WhatsApp & push notifications',
                  badgeColor: olive,
                ),

                _buildTierSection(
                  tier: 2,
                  title: 'Tier 2: Trusted Neighbors & Local Relatives',
                  subtitle: 'Physical key holders nearby in Kerala who can check Amma within minutes',
                  badgeColor: concern,
                ),

                _buildTierSection(
                  tier: 3,
                  title: 'Tier 3: Emergency & Medical Services',
                  subtitle: 'Direct ambulance (108) and emergency services (112) automated speed-dial',
                  badgeColor: emergency,
                ),

                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  onPressed: _addResponderDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Neighbor or Family Member'),
                ),
              ],
            ),
    );
  }

  Widget _buildTierSection({
    required int tier,
    required String title,
    required String subtitle,
    required Color badgeColor,
  }) {
    final list = _responders.where((r) => r['tier'] == tier).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: olive)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          ...list.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: badgeColor.withValues(alpha: 0.12),
                    child: Text(
                      r['name'].toString().isNotEmpty ? r['name'][0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                  ),
                  title: Text(r['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${r['role']}\n${r['phone']} · ${r['badge'] ?? ''}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: sage),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${r['name']} (${r['phone']})...')),
                          );
                        },
                      ),
                      if (tier != 3)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.black45),
                          onPressed: () async {
                            setState(() => _responders.removeWhere((item) => item['id'] == r['id']));
                            await _save();
                          },
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
