import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/composer_api_service.dart';
import '../../data/composition_models.dart';

/// User input form for the AI Music Compositor.
class CompositionForm extends StatefulWidget {
  const CompositionForm({
    required this.onSubmit,
    required this.isLoading,
    ComposerApiService? apiService,
    super.key,
  }) : _apiService = apiService;

  final void Function({
    required String prompt,
    String? style,
    String? key,
    String? mode,
    int? tempoBpm,
    int? bars,
    required bool useLlm,
  }) onSubmit;

  final bool isLoading;
  final ComposerApiService? _apiService;

  @override
  State<CompositionForm> createState() => _CompositionFormState();
}

class _CompositionFormState extends State<CompositionForm> {
  late final ComposerApiService _api = widget._apiService ?? ComposerApiService();
  final TextEditingController _promptCtrl = TextEditingController(
    text: 'A hopeful uplifting lo-fi piano piece for a sunny morning',
  );
  String _style = 'auto';
  String _key = 'auto';
  String _mode = 'auto';
  double _tempo = 110;
  double _bars = 16;
  bool _useLlm = true;
  bool _isRandomizing = false;

  static const List<String> _styles = [
    'auto', 'pop', 'rock', 'jazz', 'blues', 'lofi', 'cinematic',
    'classical', 'electronic', 'folk', 'ambient',
  ];
  static const List<String> _keys = [
    'auto', 'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B',
  ];
  static const List<String> _modes = [
    'auto', 'major', 'minor', 'dorian', 'mixolydian', 'lydian',
    'phrygian', 'harmonic_minor',
  ];

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _randomize() async {
    setState(() => _isRandomizing = true);
    try {
      final rp = await _api.fetchRandomPrompt();
      if (!mounted) return;
      setState(() {
        _promptCtrl.text = rp.prompt;
        _style = _styles.contains(rp.style) ? rp.style : 'auto';
        _key = _keys.contains(rp.key) ? rp.key : 'auto';
        _mode = _modes.contains(rp.mode) ? rp.mode : 'auto';
        _tempo = rp.tempoBpm.toDouble().clamp(50, 180);
        _bars = rp.bars.toDouble().clamp(8, 32);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch random prompt. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isRandomizing = false);
    }
  }

  void _submit() {
    widget.onSubmit(
      prompt: _promptCtrl.text.trim(),
      style: _style == 'auto' ? null : _style,
      key: _key == 'auto' ? null : _key,
      mode: _mode == 'auto' ? null : _mode,
      tempoBpm: _tempo.round(),
      bars: _bars.round(),
      useLlm: _useLlm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.tan),
              const SizedBox(width: 8),
              Text(
                'AI Music Compositor',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe the music you want…',
              prefixIcon: const Icon(Icons.edit_note_rounded),
              suffixIcon: Tooltip(
                message: 'Fill with a random prompt and settings',
                child: IconButton(
                  onPressed: (_isRandomizing || widget.isLoading) ? null : _randomize,
                  icon: _isRandomizing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.casino_rounded),
                  color: AppTheme.tan,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _dropdown('Style', _styles, _style, (v) => setState(() => _style = v)),
              _dropdown('Key', _keys, _key, (v) => setState(() => _key = v)),
              _dropdown('Mode', _modes, _mode, (v) => setState(() => _mode = v)),
            ],
          ),
          const SizedBox(height: 14),
          _slider('Tempo', '${_tempo.round()} BPM', _tempo, 50, 180, (v) => setState(() => _tempo = v)),
          _slider('Length', '${_bars.round()} bars', _bars, 8, 32, (v) => setState(() => _bars = v)),
          Row(
            children: [
              Switch(value: _useLlm, onChanged: (v) => setState(() => _useLlm = v)),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Use LLM (LangGraph) when OPENAI_API_KEY is configured',
                   style: TextStyle(fontSize: 12, color: AppTheme.tan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.isLoading ? null : _submit,
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.graphic_eq_rounded, size: 18),
              label: Text(widget.isLoading ? 'Composing…' : 'Compose'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String value, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 160,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            isExpanded: true,
            items: items
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, String display, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
           width: 70,
           child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.paper)),
        ),
        Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
        SizedBox(width: 80, child: Text(display, style: const TextStyle(color: AppTheme.tan))),
      ],
    );
  }
}
