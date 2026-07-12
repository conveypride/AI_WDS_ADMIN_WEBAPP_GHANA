import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/coastline_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

// ============================================================================
// ENHANCED FORECAST TABLE WITH INPUT GUIDANCE
// ============================================================================

/// Smart input cell with format hints, validation, and templates
class SmartForecastInputCell extends StatefulWidget {
  final String parameter;
  final String period;
  final String value;
  final CoastlineForecastController ctrl;
  final BuildContext context;
  final bool isDaily; 
  
  const SmartForecastInputCell({
    super.key,
    required this.parameter,
    required this.period,
    required this.value,
    required this.ctrl,
    required this.context,
    this.isDaily = false, 
  });

  @override
  State<SmartForecastInputCell> createState() => _SmartForecastInputCellState();
}

class _SmartForecastInputCellState extends State<SmartForecastInputCell> {
  final FocusNode _focusNode = FocusNode();
  bool _showHint = false;
  bool _hasError = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value);
    
    _focusNode.addListener(() {
      setState(() {
        _showHint = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Get format template based on parameter type
  Map<String, dynamic> _getInputGuide() {
    final guides = {
      // --- IBF TABLE PARAMETERS ---
      'SURFACE WIND': {
        'format': 'Direction Speed MAX Speed',
        'example': 'S/SW 05KT MAX 22KT',
        'hint': 'e.g., S/SW 05KT MAX 22KT',
        'validator': _validateWind,
        'suggestions': ['S/SW 05KT MAX 22KT', 'SSE 05KT MAX 20KT', 'N/NE 05KT MAX 15KT'],
      },
      'VISIBILITY': {
        'format': '(MIN - MAX) km',
        'example': '(4 - 10) km',
        'hint': 'Enter range: (4 - 10) km',
        'validator': _validateVisibility,
        'suggestions': ['(4 - 10) km', '(5 - 12) km', '(2 - 8) km'],
      },
      'SEA SURFACE TEMPERATURE': {
        'format': 'MIN - MAX °C',
        'example': '28 - 30',
        'hint': 'Enter range: 28 - 30',
        'validator': _validateTemperature,
        'suggestions': ['28 - 30', '27 - 29', '29 - 31'],
      },
      'SIG WAVE HEIGHT': {
        'format': '(MIN - MAX) m (MIN - MAX) ft',
        'example': '(1.0 - 1.7) m (3.3 - 5.6) ft',
        'hint': 'e.g., (1.0 - 1.7) m (3.3 - 5.6) ft',
        'validator': _validateWaveHeight,
        'suggestions': [
          '(1.0 - 1.7) m (3.3 - 5.6) ft',
          '(1.0 - 1.5) m (3.3 - 4.9) ft',
          '(0.5 - 1.2) m (1.6 - 3.9) ft'
        ],
      },
      'TIDAL WAVE': {
        'format': '(MIN - MAX) m (MIN - MAX) ft',
        'example': '(0.49 - 1.26) m (1.61 - 4.13) ft',
        'hint': 'e.g., (0.49 - 1.26) m (1.61 - 4.13) ft',
        'validator': _validateTide,
        'suggestions': [
          '(0.49 - 1.26) m (1.61 - 4.13) ft',
          '(0.83 - 1.31) m (2.72 - 4.30) ft'
        ],
      },
      'WAVE CURRENT': {
        'format': 'Direction Speed m/s',
        'example': 'E/NE 0.47 m/s',
        'hint': 'e.g., E/NE 0.47 m/s',
        'validator': _validateWaveCurrent,
        'suggestions': [
          'E/NE 0.47 m/s',
          'E/NE 0.37 m/s',
          'S/SW 0.50 m/s'
        ],
      },
    };
    
    return guides[widget.parameter] ?? {
      'format': 'Free text',
      'example': '-',
      'hint': 'Enter value',
      'validator': null,
      'suggestions': [],
    };
  }

  // --- STRICT REGEX VALIDATORS FOR IBF ---
  bool _validateWind(String value) {
    final pattern = RegExp(r'^[A-Z]{1,3}\/[A-Z]{1,3}\s+\d{2}KT\s+MAX\s+\d{2}KT$', caseSensitive: false);
    return pattern.hasMatch(value.trim()) || value.trim().toUpperCase() == 'CALM';
  }

  bool _validateVisibility(String value) {
    final pattern = RegExp(r'^\(\s*\d+\s*[--]\s*\d+\s*\)\s*km$', caseSensitive: false);
    return pattern.hasMatch(value.trim());
  }

  bool _validateTemperature(String value) {
    // Matches "(23 - 35)" without requiring "°C" at the end
    final pattern = RegExp(r'^\(\s*\d+\s*-\s*\d+\s*\)$', caseSensitive: false);
    return pattern.hasMatch(value.trim());
  }

  bool _validateWaveHeight(String value) {
    final pattern = RegExp(r'^\(\s*\d+\.?\d*\s*[--]\s*\d+\.?\d*\s*\)\s*m\s*\(\s*\d+\.?\d*\s*[--]\s*\d+\.?\d*\s*\)\s*ft$', caseSensitive: false);
    return pattern.hasMatch(value.trim());
  }

  bool _validateTide(String value) {
    final pattern = RegExp(r'^\(\s*\d+\.?\d*\s*[--]\s*\d+\.?\d*\s*\)\s*m\s*\(\s*\d+\.?\d*\s*[--]\s*\d+\.?\d*\s*\)\s*ft$', caseSensitive: false);
    return pattern.hasMatch(value.trim());
  }

  bool _validateWaveCurrent(String value) {
    final pattern = RegExp(r'^[A-Z]{1,3}\/[A-Z]{1,3}\s+\d+\.?\d*\s*m\/s$', caseSensitive: false);
    return pattern.hasMatch(value.trim());
  }

  void _validateInput(String value) {
    final guide = _getInputGuide();
    final validator = guide['validator'];
    
    if (widget.isDaily) {
      if (value.trim().isEmpty || value.trim() == '-') {
        setState(() => _hasError = true);
      } else {
        setState(() => _hasError = false);
      }
      return;
    }

    if (validator != null && value.isNotEmpty && value != '-') {
      setState(() => _hasError = !validator(value));
    } else {
      setState(() => _hasError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = widget.context.wColors;
    final guide = _getInputGuide();
    final suggestions = List<String>.from(guide['suggestions'] as List<dynamic>? ?? []);
    
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: (widget.isDaily && _hasError) ? Colors.red.withOpacity(0.05) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: ValueKey('${widget.ctrl.currentForecastId.value}_${widget.parameter}_${widget.period}'),
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hasError ? Colors.red.shade700 : wc.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: guide['example'],
                  hintStyle: TextStyle(color: wc.textMuted.withOpacity(0.5), fontSize: 11),
                  suffixIcon: _showHint
                      ? IconButton(
                          icon: Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill), size: 16, color: Colors.amber.shade600),
                          onPressed: () => _showTemplateDialog(suggestions),
                          tooltip: 'Quick templates',
                        )
                      : null,
                ),
                onChanged: (val) {
                  _validateInput(val);
                  // FIXED: The arguments are now correctly ordered for BOTH tables!
                  if (widget.isDaily) {
                     widget.ctrl.updateDailyTableData(widget.parameter, widget.period, val); 
                  } else {
                     widget.ctrl.updateTableData(widget.parameter, widget.period, val);
                  }
                },
              ),
              
              if (_showHint)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(guide['hint'], style: TextStyle(fontSize: 9, color: Colors.blue.shade800, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                ),
              
              if (_hasError && !widget.isDaily) 
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.warning(), size: 10, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Flexible(child: Text('Check format', style: TextStyle(fontSize: 9, color: Colors.red.shade700))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTemplateDialog(List<String> suggestions) {
    final wc = widget.context.wColors;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill), color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Quick Templates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tap to use a template:', style: TextStyle(fontSize: 12, color: wc.textMuted)),
              const SizedBox(height: 12),
              ...suggestions.map((template) => _buildTemplateOption(template)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(String template) {
    final wc = widget.context.wColors;
    
    return InkWell(
      onTap: () {
        setState(() {
          _textController.text = template;
          _validateInput(template);
        });
        // FIXED: The arguments are now correctly ordered for templates too!
        if (widget.isDaily) {
          widget.ctrl.updateDailyTableData(widget.parameter, widget.period, template); 
        } else {
          widget.ctrl.updateTableData(widget.parameter, widget.period, template);
        }
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: wc.elevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: wc.borderSoft)),
        child: Row(
          children: [
            Icon(PhosphorIcons.fileText(), size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(template, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: wc.textPrimary))),
            Icon(PhosphorIcons.caretRight(), size: 14, color: wc.textMuted),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ENHANCED TABLE WITH HELP INDICATORS (USED BY IBF)
// ============================================================================

Widget buildEnhancedForecastTable({
  required BuildContext context,
  required CoastlineForecastController ctrl,
}) {
  final wc = context.wColors;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Forecast Parameters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: wc.textPrimary)),
          OutlinedButton.icon(
            onPressed: () => _showFormatGuideDialog(context),
            icon: Icon(PhosphorIcons.info(), size: 16),
            label: const Text('Format Guide'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade700, side: BorderSide(color: Colors.blue.shade300), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
        child: Row(
          children: [
            Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill), color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Tip: Click any input field for format hints and quick templates. Hover over 💡 for instant templates.', style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
      const SizedBox(height: 16),
      
      Container(
        width: double.infinity,
        decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: wc.border)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Obx(() {
            return Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: wc.borderSoft, width: 1),
                verticalInside: BorderSide(color: wc.borderSoft, width: 1),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1)
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: wc.elevated),
                  children: [
                    _headerCell("PARAMETER", context),
                    _headerCell("12 HOURS", context),
                    _headerCell("24 HOURS", context)
                  ],
                ),
                ...ctrl.parameters.asMap().entries.map((entry) {
                  final index = entry.key;
                  final param = entry.value;
                  final data = ctrl.tableData[param]!;

                  return TableRow(
                    decoration: BoxDecoration(color: index.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3)),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: Text(param, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: wc.textPrimary))),
                            const SizedBox(width: 4),
                            _buildParameterHelpIcon(context, param),
                          ],
                        ),
                      ),
                      SmartForecastInputCell(parameter: param, period: '12h', value: data['12h']!, ctrl: ctrl, context: context, isDaily: false),
                      SmartForecastInputCell(parameter: param, period: '24h', value: data['24h']!, ctrl: ctrl, context: context, isDaily: false),
                    ],
                  );
                })
              ],
            );
          }),
        ),
      ),
    ],
  );
}

// Helper widgets
Widget _headerCell(String text, BuildContext context) {
  return Container(
    height: 55,
    padding: const EdgeInsets.all(4),
    alignment: Alignment.center,
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: context.wColors.textSecondary, letterSpacing: 0.5)),
  );
}

Widget _buildParameterHelpIcon(BuildContext context, String param) {
  return Tooltip(
    message: 'View format example',
    child: InkWell(
      onTap: () => _showParameterHelp(context, param),
      child: Icon(PhosphorIcons.question(), size: 14, color: Colors.blue.shade600),
    ),
  );
}

void _showParameterHelp(BuildContext context, String param) {
  final examples = {
    'SURFACE WIND': 'Direction Speed MAX Speed\nExample: S/SW 05KT MAX 22KT',
    'VISIBILITY': 'Range in km\nExample: (4 - 10) km',
    'SEA SURFACE TEMPERATURE': 'Range in Celsius\nExample: 28 - 30 °C',
    'SIG WAVE HEIGHT': 'Meters and Feet\nExample: (1.0 - 1.7) m (3.3 - 5.6) ft',
    'TIDAL WAVE': 'Meters and Feet\nExample: (0.49 - 1.26) m (1.61 - 4.13) ft',
    'WAVE CURRENT': 'Direction and Speed\nExample: E/NE 0.47 m/s',
  };

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(param, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      content: Text(examples[param] ?? 'No example available', style: const TextStyle(fontSize: 12)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
    ),
  );
}

void _showFormatGuideDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.book(), color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                const Text('Forecast Format Guide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGuideSection('Surface Wind', 'Direction Speed MAX Speed', 'S/SW 05KT MAX 22KT', ''),
                    const Divider(height: 24),
                    _buildGuideSection('Visibility', '(MIN - MAX) km', '(4 - 10) km', ''),
                    const Divider(height: 24),
                    _buildGuideSection('Sea Surface Temperature', 'MIN - MAX °C', '28 - 30 °C', ''),
                    const Divider(height: 24),
                    _buildGuideSection('Sig. Wave Height', '(MIN - MAX) m (MIN - MAX) ft', '(1.0 - 1.7) m (3.3 - 5.6) ft', ''),
                    const Divider(height: 24),
                    _buildGuideSection('Tide', '(MIN - MAX) m (MIN - MAX) ft', '(0.49 - 1.26) m (1.61 - 4.13) ft', ''),
                    const Divider(height: 24),
                    _buildGuideSection('Wave Current', 'Direction Speed m/s', 'E/NE 0.47 m/s', ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildGuideSection(String title, String format, String example, String note) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Format:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(format, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Text('Example:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(example, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    ],
  );
}
