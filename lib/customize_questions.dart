import 'package:flutter/material.dart';
import 'config.dart';
import 'main.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const concern = Color(0xFFA56D24);
const emergency = Color(0xFFC53030);

class CustomizeQuestionsTab extends StatefulWidget {
  const CustomizeQuestionsTab({super.key});

  @override
  State<CustomizeQuestionsTab> createState() => _CustomizeQuestionsTabState();
}

class _CustomizeQuestionsTabState extends State<CustomizeQuestionsTab> {
  // Common elder-care question presets
  final List<Map<String, dynamic>> _presets = [
    {
      'title': 'Meals Check',
      'text': 'Have you eaten your meal?',
      'options': [
        {'key': '1', 'label': 'Yes', 'concern': false},
        {'key': '2', 'label': 'No', 'concern': true},
      ],
    },
    {
      'title': 'Medication Reminder',
      'text': 'Have you taken your medicines on time?',
      'options': [
        {'key': '1', 'label': 'Yes', 'concern': false},
        {'key': '2', 'label': 'No', 'concern': true},
      ],
    },
    {
      'title': 'Wellbeing & Mood',
      'text': 'How are you feeling right now?',
      'options': [
        {'key': '1', 'label': 'Feeling good', 'concern': false},
        {'key': '2', 'label': 'A bit tired', 'concern': false},
        {'key': '3', 'label': 'Need help / Unwell', 'concern': true},
      ],
    },
    {
      'title': 'Water & Hydration',
      'text': 'Have you had enough water to drink today?',
      'options': [
        {'key': '1', 'label': 'Yes, drank well', 'concern': false},
        {'key': '2', 'label': 'Not enough', 'concern': true},
      ],
    },
  ];

  Future<void> _toggleEnabled(Map<String, dynamic> q, bool enabled) async {
    await db.from('questions').update({'enabled': enabled}).eq('id', q['id']);
  }

  Future<void> _deleteQuestion(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('Amma will no longer be asked this question during automated check-in calls.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: emergency),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await db.from('questions').delete().eq('id', id);
    }
  }

  Future<void> _onReorder(List<Map<String, dynamic>> questions, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = questions.removeAt(oldIndex);
    questions.insert(newIndex, item);

    // Update positions in batch
    for (var i = 0; i < questions.length; i++) {
      final pos = i + 1;
      await db.from('questions').update({'position': pos}).eq('id', questions[i]['id']);
    }
  }

  void _showSimulatorModal(Map<String, dynamic> q) {
    final opts = List<Map<String, dynamic>>.from(
      (q['options'] as List).map((o) => Map<String, dynamic>.from(o)),
    );
    final text = q['text'].toString();
    final audio = q['audio_url']?.toString();

    String? simulationResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSimState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: olive.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.dialpad, color: olive, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amma Phone Keypad Preview', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: olive)),
                          Text('Test how Lakshmi Amma interacts with this question', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F382E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Voice Prompt Audio:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          if (audio != null && audio.isNotEmpty)
                            const Row(
                              children: [
                                Icon(Icons.volume_up, size: 14, color: Colors.greenAccent),
                                SizedBox(width: 4),
                                Text('Malayalam Audio Set', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Tap a keypad number to simulate Amma’s answer:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: opts.map((o) {
                    final isConcern = o['concern'] == true;
                    return InkWell(
                      onTap: () {
                        setSimState(() {
                          simulationResult = isConcern
                              ? 'Pressed ${o['key']} ("${o['label']}"): ⚠️ CONCERN ALERT! Triggers immediate emergency escalation to family & neighbors.'
                              : 'Pressed ${o['key']} ("${o['label']}"): ✓ Normal healthy response. Recorded as FINE.';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isConcern ? const Color(0xFFFEF3E2) : const Color(0xFFE8F3EB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConcern ? concern : sage,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isConcern ? concern : sage,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  o['key'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              o['label'].toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            if (isConcern) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.warning_amber, size: 16, color: concern),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (simulationResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: simulationResult!.contains('⚠️') ? const Color(0xFFFFF1F0) : const Color(0xFFE8F3EB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: simulationResult!.contains('⚠️') ? emergency : sage,
                      ),
                    ),
                    child: Text(
                      simulationResult!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: simulationResult!.contains('⚠️') ? Colors.red.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editQuestion({Map<String, dynamic>? q, required int pos}) async {
    final text = TextEditingController(text: q?['text'] ?? '');
    final audio = TextEditingController(text: q?['audio_url'] ?? '');
    final opts = q == null
        ? [
            {'key': '1', 'label': 'Yes', 'concern': false},
            {'key': '2', 'label': 'No', 'concern': true},
          ]
        : (q['options'] as List).map((o) => Map<String, dynamic>.from(o)).toList();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(q == null ? 'Add Check-in Question' : 'Edit Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (q == null) ...[
                  const Text('Quick Template Suggestions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _presets.map((p) {
                      return ActionChip(
                        label: Text(p['title'] as String, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          set(() {
                            text.text = p['text'] as String;
                            opts.clear();
                            opts.addAll(
                              (p['options'] as List).map((o) => Map<String, dynamic>.from(o)),
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: text,
                  decoration: const InputDecoration(
                    labelText: 'Question Amma will hear',
                    hintText: 'e.g. Have you taken your night BP medication?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audio,
                  decoration: const InputDecoration(
                    labelText: 'Malayalam voice audio URL (optional)',
                    hintText: 'https://.../malayalam_prompt.mp3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Keypad Options (1 to 9):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: olive),
                ),
                const Text(
                  'Assign keys Amma can press on her phone keypad. Mark alert if chosen.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < opts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        DropdownButton<String>(
                          value: opts[i]['key'],
                          items: [
                            for (var k = 1; k <= 9; k++)
                              DropdownMenuItem(value: '$k', child: Text('Key $k')),
                          ],
                          onChanged: (v) => set(() => opts[i]['key'] = v),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: opts[i]['label'],
                            decoration: const InputDecoration(
                              hintText: 'Answer label (e.g. Yes)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => opts[i]['label'] = v,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Mark as Concern Alert (escalates to family if pressed)',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                activeColor: concern,
                                value: opts[i]['concern'] == true,
                                onChanged: (v) => set(() => opts[i]['concern'] = v),
                              ),
                              const Text('Alert', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        if (opts.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.black45),
                            onPressed: () => set(() => opts.removeAt(i)),
                          ),
                      ],
                    ),
                  ),
                if (opts.length < 9)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Keypad Option'),
                    onPressed: () {
                      final used = opts.map((o) => o['key']).toSet();
                      set(() => opts.add({
                            'key': [for (var k = 1; k <= 9; k++) '$k'].firstWhere((k) => !used.contains(k), orElse: () => '9'),
                            'label': '',
                            'concern': false,
                          }));
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
              style: FilledButton.styleFrom(backgroundColor: olive),
              onPressed: () async {
                final keys = opts.map((o) => o['key']).toList();
                if (text.text.trim().isEmpty ||
                    opts.any((o) => (o['label'] as String).trim().isEmpty) ||
                    keys.toSet().length != keys.length) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please fill question, all answers, and ensure keypad numbers are unique.')),
                  );
                  return;
                }
                final row = {
                  'text': text.text.trim(),
                  'audio_url': audio.text.trim().isEmpty ? null : audio.text.trim(),
                  'options': opts,
                  'enabled': q?['enabled'] ?? true,
                };
                if (q == null) {
                  await db.from('questions').insert({
                    ...row,
                    'elder_id': elderId,
                    'position': pos,
                  });
                } else {
                  await db.from('questions').update(row).eq('id', q['id']);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Question'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.from('questions').stream(primaryKey: ['id']).eq('elder_id', elderId).order('position'),
      builder: (context, snapshot) {
        final qs = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sage.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.format_list_numbered, color: sage, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Drag & reorder questions to change IVR calling sequence. Toggle on/off to enable or disable questions.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (qs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('No custom questions yet. Add one below.'),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: qs.length,
                // ignore: deprecated_member_use
                onReorder: (oldIdx, newIdx) => _onReorder(List.from(qs), oldIdx, newIdx),
                itemBuilder: (context, index) {
                  final q = qs[index];
                  final isEnabled = q['enabled'] != false;
                  final opts = (q['options'] as List).map((o) => Map<String, dynamic>.from(o)).toList();

                  return Card(
                    key: ValueKey(q['id']),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isEnabled ? Colors.black.withValues(alpha: 0.08) : Colors.black12,
                      ),
                    ),
                    color: isEnabled ? Colors.white : const Color(0xFFF7F7F6),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isEnabled ? olive : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  q['text'].toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isEnabled ? Colors.black87 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isEnabled,
                                activeThumbColor: sage,
                                onChanged: (v) => _toggleEnabled(q, v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Keypad Options Badges
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: opts.map((o) {
                              final isConcern = o['concern'] == true;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isConcern ? const Color(0xFFFEF3E2) : const Color(0xFFE8F3EB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isConcern ? concern.withValues(alpha: 0.3) : sage.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Key ${o['key']}: ${o['label']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isConcern ? concern : sage,
                                      ),
                                    ),
                                    if (isConcern) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.warning_amber, size: 12, color: concern),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: olive),
                                onPressed: () => _showSimulatorModal(q),
                                icon: const Icon(Icons.play_circle_outline, size: 18),
                                label: const Text('Preview Keypad', style: TextStyle(fontSize: 13)),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit question',
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: olive),
                                    onPressed: () => _editQuestion(q: q, pos: q['position'] as int),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete question',
                                    icon: const Icon(Icons.delete_outline, size: 20, color: emergency),
                                    onPressed: () => _deleteQuestion(q['id'] as String),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: olive,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _editQuestion(
                pos: qs.isEmpty ? 1 : (qs.last['position'] as int) + 1,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add New Question', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
