import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trusted_contact.dart';
import '../theme/koode_theme.dart';
import '../widgets/contact_action_tile.dart';
import '../widgets/elder_selector.dart';

class FamilySupportTab extends StatefulWidget {
  final ElderInfo currentElder;

  const FamilySupportTab({super.key, required this.currentElder});

  @override
  State<FamilySupportTab> createState() => _FamilySupportTabState();
}

class _FamilySupportTabState extends State<FamilySupportTab> {
  static const _prefKey = 'koode_responders_network';
  List<TrustedContact> _contacts = [];

  // Notification Preferences state
  bool _urgentAlertsSound = true;
  bool _concernNotifications = true;
  bool _missedCheckinAlerts = true;
  bool _dailySummaryDigest = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urgentAlertsSound = prefs.getBool('notif_urgent') ?? true;
      _concernNotifications = prefs.getBool('notif_concern') ?? true;
      _missedCheckinAlerts = prefs.getBool('notif_missed') ?? true;
      _dailySummaryDigest = prefs.getBool('notif_summary') ?? false;
    });
  }

  Future<void> _saveNotificationPref(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List list = jsonDecode(raw);
        setState(() {
          _contacts = list.map((x) => TrustedContact.fromJson(Map<String, dynamic>.from(x))).toList();
        });
        return;
      } catch (_) {}
    }

    // Default 3-tier verified escalation network
    _contacts = [
      // Tier 1: Family
      const TrustedContact(
        id: '1',
        name: 'Rahul Nair',
        relationship: 'Son (Dubai - Primary Caregiver)',
        phone: '+971501234567',
        tier: 1,
        locationNote: 'Direct video/voice contact',
        isPrimary: true,
      ),
      const TrustedContact(
        id: '2',
        name: 'Ananya Nair',
        relationship: 'Daughter (Bengaluru)',
        phone: '+919847112233',
        tier: 1,
        locationNote: 'Family Admin',
      ),
      // Tier 2: Neighbors & Local Doctor
      const TrustedContact(
        id: '3',
        name: 'Suresh Uncle',
        relationship: 'Next-door Neighbor (Kochi)',
        phone: '+919447001122',
        tier: 2,
        locationNote: 'Key holder (2 mins away)',
      ),
      const TrustedContact(
        id: '4',
        name: 'Dr. Preethi Mathew',
        relationship: 'Family Physician',
        phone: '+919846334455',
        tier: 2,
        locationNote: 'Ernakulam Clinic',
      ),
      // Tier 3: Emergency Services
      const TrustedContact(
        id: '5',
        name: 'Emergency Ambulance Kerala',
        relationship: 'Government Emergency Medical Response',
        phone: '108',
        tier: 3,
        locationNote: 'Statewide 24/7 Dispatch',
      ),
      const TrustedContact(
        id: '6',
        name: 'Kerala Police Senior Citizens Helpline',
        relationship: 'Elder Protection & Emergency',
        phone: '112',
        tier: 3,
        locationNote: 'Toll-free 24/7',
      ),
    ];
    setState(() {});
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    int tier = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: KoodeColors.surface,
          title: const Text(
            'Add Trusted Contact',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: relCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    hintText: 'e.g. Neighbor / Daughter',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'e.g. +91XXXXXXXXXX',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / Response notes',
                    hintText: 'e.g. 5 mins walk / Spare key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: tier,
                  decoration: const InputDecoration(labelText: 'Escalation Tier', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Tier 1: Family Member')),
                    DropdownMenuItem(value: 2, child: Text('Tier 2: Neighbor / Doctor')),
                    DropdownMenuItem(value: 3, child: Text('Tier 3: Emergency Service')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => tier = v);
                  },
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
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                final newContact = TrustedContact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  relationship: relCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  tier: tier,
                  locationNote: locCtrl.text.trim(),
                );
                setState(() => _contacts.add(newContact));
                Navigator.pop(ctx);
              },
              child: const Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tier1 = _contacts.where((c) => c.tier == 1).toList();
    final tier2 = _contacts.where((c) => c.tier == 2).toList();
    final tier3 = _contacts.where((c) => c.tier == 3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support & Contacts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: KoodeColors.secondaryText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Support Network",
                  style: KoodeTheme.displayTitle,
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: KoodeColors.olive,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add Contact', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '3-Tier Rapid Escalation Network coordinates family, trusted neighbors, and emergency responders when help is requested.',
          style: TextStyle(fontSize: 14, color: KoodeColors.secondaryText, height: 1.3),
        ),
        const SizedBox(height: 18),

        // Notification Preferences Section (Section 4.5)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KoodeColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KoodeColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 20, color: KoodeColors.olive),
                  SizedBox(width: 8),
                  Text(
                    'Notification Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KoodeColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Understand which alerts are critical and how you receive them.',
                style: TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
              ),
              const SizedBox(height: 12),
              const Divider(color: KoodeColors.divider),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: KoodeColors.emergency,
                title: const Text('Urgent Emergency Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Bypass mute / DND for critical incidents and fall triggers', style: TextStyle(fontSize: 12)),
                value: _urgentAlertsSound,
                onChanged: (v) {
                  setState(() => _urgentAlertsSound = v);
                  _saveNotificationPref('notif_urgent', v);
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: KoodeColors.concern,
                title: const Text('Check-in Concerns', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Alert when Lakshmi Amma indicates missed food/meds', style: TextStyle(fontSize: 12)),
                value: _concernNotifications,
                onChanged: (v) {
                  setState(() => _concernNotifications = v);
                  _saveNotificationPref('notif_concern', v);
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: KoodeColors.olive,
                title: const Text('Missed Check-in Warnings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Notify when automated check-in call is unanswered', style: TextStyle(fontSize: 12)),
                value: _missedCheckinAlerts,
                onChanged: (v) {
                  setState(() => _missedCheckinAlerts = v);
                  _saveNotificationPref('notif_missed', v);
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: KoodeColors.olive,
                title: const Text('Daily Wellbeing Digest', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Receive a gentle evening summary of check-ins', style: TextStyle(fontSize: 12)),
                value: _dailySummaryDigest,
                onChanged: (v) {
                  setState(() => _dailySummaryDigest = v);
                  _saveNotificationPref('notif_summary', v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tier 1 Section
        const Row(
          children: [
            Icon(Icons.favorite_rounded, size: 18, color: KoodeColors.olive),
            SizedBox(width: 6),
            Text('Tier 1: Family Circle (Notified First)', style: KoodeTheme.sectionTitle),
          ],
        ),
        const SizedBox(height: 8),
        ...tier1.map((c) => ContactActionTile(
              contact: c,
              onCall: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${c.name} (${c.phone})…')),
                );
              },
              onMessage: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Messaging ${c.name} (${c.phone})…')),
                );
              },
            )),
        const SizedBox(height: 16),

        // Tier 2 Section
        const Row(
          children: [
            Icon(Icons.home_work_rounded, size: 18, color: KoodeColors.concern),
            SizedBox(width: 6),
            Text('Tier 2: Neighbors & Local Doctor (Escalates after 30s)', style: KoodeTheme.sectionTitle),
          ],
        ),
        const SizedBox(height: 8),
        ...tier2.map((c) => ContactActionTile(
              contact: c,
              onCall: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling responder ${c.name} (${c.phone})…')),
                );
              },
              onMessage: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Messaging responder ${c.name} (${c.phone})…')),
                );
              },
            )),
        const SizedBox(height: 16),

        // Tier 3 Section
        const Row(
          children: [
            Icon(Icons.emergency_rounded, size: 18, color: KoodeColors.emergency),
            SizedBox(width: 6),
            Text('Tier 3: Emergency Dispatch & Helplines (24/7)', style: KoodeTheme.sectionTitle),
          ],
        ),
        const SizedBox(height: 8),
        ...tier3.map((c) => ContactActionTile(
              contact: c,
              onCall: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Emergency direct call to ${c.phone} (${c.name})…')),
                );
              },
              onMessage: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Emergency message dispatch to ${c.phone}…')),
                );
              },
            )),
        const SizedBox(height: 32),
      ],
    );
  }
}
