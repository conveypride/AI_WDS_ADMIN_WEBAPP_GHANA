import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/inland_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/inland/enhancedMapCard.dart';
 

// -------------------------------------------------------------
// THREE MAPS SECTION
// -------------------------------------------------------------
class ThreeMapsSection extends StatelessWidget {
  final InlandForecastController ctrl;
  final bool isDark;
  
  const ThreeMapsSection({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header Row with Toggle Button
          Row(
            children: [
              Icon(PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill), color: isDark ? Colors.blueAccent : const Color(0xFF0B4EA2)),
              const SizedBox(width: 12),
              Text('WEATHER MAPS BY PERIOD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              
              const Spacer(), // Pushes the toggle button to the far right
              
              // Layout Toggle Button listening to the controller
              Obx(() => Tooltip(
                message: ctrl.isVerticalMapLayout.value ? "Switch to Row Layout" : "Switch to Column Layout",
                child: IconButton(
                  icon: Icon(
                    ctrl.isVerticalMapLayout.value ? PhosphorIcons.columns() : PhosphorIcons.rows(),
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: ctrl.toggleMapLayout,
                ),
              )),
            ],
          ),
          const SizedBox(height: 20),
          
          // Map Rendering listening to layout state
          Obx(() {
            final periods = ctrl.getOrderedPeriods();
            final dates = ctrl.dynamicDates; 
            final isVertical = ctrl.isVerticalMapLayout.value;

            // We use a Flex widget because it can dynamically change direction
            // without destroying and remounting the FlutterMap widgets inside it!
            return Flex(
              direction: isVertical ? Axis.vertical : Axis.horizontal,
              children: List.generate(periods.length, (index) {
                
                return Flexible(
                  // When Horizontal, flex: 1 acts exactly like an 'Expanded' widget.
                  // When Vertical, flex: 0 prevents it from trying to expand infinitely.
                  flex: isVertical ? 0 : 1,
                  fit: isVertical ? FlexFit.loose : FlexFit.tight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isVertical ? 24.0 : 0.0,
                      left: isVertical ? 0.0 : 8.0,
                      right: isVertical ? 0.0 : 8.0,
                    ),
                    child: SizedBox(
                      height: isVertical ? 500 : null, // Fixed height only when vertical
                      width: double.infinity,
                      child: EnhancedMapCard(
                        key: ValueKey(periods[index]), // CRITICAL: This tells Flutter not to destroy the map!
                        ctrl: ctrl, 
                        period: periods[index],
                        dateLabel: dates[index],  
                        isDark: isDark
                      ),
                    ),
                  ),
                );
                
              }),
            );
          }),
        ],
      ),
    );
  }
} 
 

// -------------------------------------------------------------
// FORECAST DETAILS CARD
// -------------------------------------------------------------
class ForecastDetailsCard extends StatelessWidget {
  final InlandForecastController ctrl;
  final bool isDark;
  const ForecastDetailsCard({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = ctrl.currentForecast.value;
      if (f == null) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('METADATA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (ctx, constraints) {
                return Flex(
                  direction: constraints.maxWidth < 600 ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _InputField(label: 'Date', value: f.date, onChanged: ctrl.updateDate, isDark: isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _InputField(label: 'Time Issued', value: f.timeIssued, onChanged: ctrl.updateTimeIssued, isDark: isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _InputField(label: 'Warning Type', value: f.warningType, onChanged: ctrl.updateWarningType, isDark: isDark)),
                    const SizedBox(width: 16),
                    // NEW DROPDOWN SELECTOR HERE
                    Expanded(
                      child: _DropdownField(
                        label: 'Sea State', 
                        value: f.seastate, // Make sure you have 'condition' in your forecast model
                        items: const ["CALM(1)", "ROUGH(2)", "DANGEROUS(3)"],
                        onChanged: (val) {
                          if (val != null) {
                            ctrl.updateSeastate(val); // Make sure this method exists in InlandForecastController
                          }
                        },
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

class _InputField extends StatelessWidget {
  final String label, value;
  final Function(String) onChanged;
  final bool isDark;
  const _InputField({required this.label, required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
          decoration: InputDecoration(
            isDense: true, filled: true, fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// WEATHER SUMMARY CARD
// -------------------------------------------------------------
class WeatherSummaryCard extends StatelessWidget {
  final InlandForecastController ctrl;
  final bool isDark;
  const WeatherSummaryCard({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = ctrl.currentForecast.value;
      if (f == null) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FORECAST SUMMARY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: f.weatherSummary, maxLines: 4, onChanged: ctrl.updateSummary,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(filled: true, fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade900.withOpacity(0.2) : const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.amber.shade800 : const Color(0xFFFDD835)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CAUTION / NB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.orangeAccent : Colors.orange.shade900)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: f.caution, maxLines: 2, onChanged: ctrl.updateCaution,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}



// NEW DROPDOWN WIDGET
class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isDark;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Ensures the passed value actually exists in the items list to prevent assertion errors
    final safeValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: safeValue,
          dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
          iconEnabledColor: isDark ? Colors.white70 : Colors.black54,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
          decoration: InputDecoration(
            isDense: true, 
            filled: true, 
            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TEMPERATURE CARD
// -------------------------------------------------------------


class TemperatureCard extends StatelessWidget {
  final InlandForecastController ctrl;
  final bool isDark;
  
  const TemperatureCard({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Exact colors mapped from your attached image
    final Color headerBg = const Color(0xFFFFC000); // Yellow
    final Color cellBg = const Color(0xFFFFF2CC);   // Cream
    final Color borderColor = Colors.black;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('GENERAL FORECAST CONDITIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const Spacer(),
              Tooltip(
                message: "Format: \nWind: S/SE 05\\nMax 20 kt\nVis: (3 - 10) km\nTemp: (23 - 35) °C",
                child: Icon(PhosphorIcons.info(), size: 18, color: Colors.blue),
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              border: TableBorder.all(color: borderColor, width: 1.5),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                // ── HEADER ROW ──
                TableRow(
                  decoration: BoxDecoration(color: headerBg),
                  children: [
                    _headerCell("Time"),
                    _headerCell("Surface Wind"),
                    _headerCell("Visibility"),
                    _headerCell("Temperature"),
                  ],
                ),
                // ── 12 HOURS ROW ──
                TableRow(
                  decoration: BoxDecoration(color: cellBg),
                  children: [
                    _headerCell("12 hours", bg: headerBg),
                    _buildSmartCell(period: '12h', param: 'SURFACE WIND'),
                    _buildSmartCell(period: '12h', param: 'VISIBILITY'),
                    _buildSmartCell(period: '12h', param: 'TEMPERATURE'),
                  ],
                ),
                // ── 24 HOURS ROW ──
                TableRow(
                  decoration: BoxDecoration(color: cellBg),
                  children: [
                    _headerCell("24 hours", bg: headerBg),
                    _buildSmartCell(period: '24h', param: 'SURFACE WIND'),
                    _buildSmartCell(period: '24h', param: 'VISIBILITY'),
                    _buildSmartCell(period: '24h', param: 'TEMPERATURE'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {Color? bg}) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
      ),
    );
  }

  Widget _buildSmartCell({required String period, required String param}) {
    return InlandSmartInputCell(
      parameter: param,
      period: period,
      ctrl: ctrl,
    );
  }
}

// ============================================================================
// INLAND SMART INPUT CELL (With built-in Validation logic)
// ============================================================================
class InlandSmartInputCell extends StatefulWidget {
  final String parameter;
  final String period;
  final InlandForecastController ctrl;

  const InlandSmartInputCell({
    super.key,
    required this.parameter,
    required this.period,
    required this.ctrl,
  });

  @override
  State<InlandSmartInputCell> createState() => _InlandSmartInputCellState();
}

class _InlandSmartInputCellState extends State<InlandSmartInputCell> {
  final FocusNode _focusNode = FocusNode();
  bool _showHint = false;
  bool _hasError = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // Initialize with current value from controller (if any)
    String initialValue = widget.ctrl.generalConditions[widget.parameter]?[widget.period] ?? '';
    _textController = TextEditingController(text: initialValue);
    
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

  Map<String, dynamic> _getInputGuide() {
    final guides = {
      'SURFACE WIND': {
        'example': 'S/SE 05\nMax 20 kt',
        'hint': 'e.g., S/SE 05\nMax 20 kt',
        'validator': (String value) {
          // Allows standard format with space or newline before "Max"
          final pattern = RegExp(r'^[A-Z]{1,3}\/[A-Z]{1,3}\s+\d{2}[\s\n]+Max\s+\d{2}\s*kt$', caseSensitive: false);
          return pattern.hasMatch(value.trim()) || value.trim().toUpperCase() == 'CALM';
        },
      },
      'VISIBILITY': {
        'example': '(3 - 10) km',
        'hint': 'e.g., (3 - 10) km',
        'validator': (String value) {
          final pattern = RegExp(r'^\(\s*\d+\s*-\s*\d+\s*\)\s*km$', caseSensitive: false);
          return pattern.hasMatch(value.trim());
        },
      },
      'TEMPERATURE': {
        'example': '(23 - 35) °C',
        'hint': 'e.g., (23 - 35)',
        'validator': (String value) {
          final pattern = RegExp(r'^\(\s*\d+\s*-\s*\d+\s*\)$', caseSensitive: false);
          return pattern.hasMatch(value.trim());
        },
      },
    };
    
    return guides[widget.parameter]!;
  }

  void _validateInput(String value) {
    final guide = _getInputGuide();
    final Function(String) validator = guide['validator'];
    
    if (value.isNotEmpty) {
      setState(() => _hasError = !validator(value));
    } else {
      setState(() => _hasError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = _getInputGuide();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: null,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _hasError ? Colors.red.shade700 : Colors.black87,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: guide['example'],
              hintStyle: TextStyle(color: Colors.black38, fontSize: 11),
            ),
            onChanged: (val) {
              _validateInput(val);
              widget.ctrl.updateGeneralCondition(widget.parameter, widget.period, val);
            },
          ),
          
          if (_showHint)
            Text(
              guide['hint'], 
              style: TextStyle(fontSize: 9, color: Colors.blue.shade800, fontWeight: FontWeight.w600), 
              textAlign: TextAlign.center
            ),
          
          if (_hasError) 
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
              child: Text('Invalid format', style: TextStyle(fontSize: 9, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
 
 // -------------------------------------------------------------
// SUBMIT BUTTON (Split Button with Dropdown)
// -------------------------------------------------------------
class PublishForecastButton extends StatelessWidget {
  final InlandForecastController ctrl;
  final bool isDark;
  const PublishForecastButton({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        final isLoading = ctrl.isSubmitting.value;
        final action = ctrl.submitAction.value;
        final buttonColor = isDark ? Colors.blue.shade600 : const Color(0xFF0B4EA2);

        // --- LOADING STATE ---
        if (isLoading) {
          return ElevatedButton.icon(
            onPressed: null, // Disables button while loading
            icon: const SizedBox(
              width: 20, height: 20, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            ),
            label: Text(
              action == 'draft' ? "SAVING DRAFT..." : "SENDING FOR APPROVAL...", 
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              disabledBackgroundColor: Colors.grey.shade500,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          );
        }

        // --- NORMAL SPLIT BUTTON STATE ---
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.4), 
                blurRadius: 8, 
                offset: const Offset(0, 4)
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. MAIN ACTION BUTTON (Send for Approval)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  onTap: ctrl.sendForApproval,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            "SEND FOR APPROVAL", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // 2. VERTICAL DIVIDER LINE
              Container(
                width: 1, 
                color: Colors.white.withOpacity(0.3), 
                margin: const EdgeInsets.symmetric(vertical: 10)
              ),
              
              // 3. DROPDOWN MENU BUTTON
              Material(
                color: Colors.transparent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.white24,
                    highlightColor: Colors.white10,
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: "More Submit Options",
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                    offset: const Offset(0, 50),
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (value) {
                      if (value == 'draft') ctrl.saveAsDraft();
                      if (value == 'approval') ctrl.sendForApproval();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'approval',
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.paperPlaneTilt(), size: 18, color: isDark ? Colors.white : Colors.black87),
                            const SizedBox(width: 10),
                            Text("Send for Approval", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'draft',
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.floppyDisk(), size: 18, color: isDark ? Colors.white : Colors.black87),
                            const SizedBox(width: 10),
                            Text("Save as Draft", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}