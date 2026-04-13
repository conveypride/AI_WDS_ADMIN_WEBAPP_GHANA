import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InfoSidePanel extends StatelessWidget {
  final ctrl;
  final bool isDark;
  
  const InfoSidePanel({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : const Color(0xFF0B4EA2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.info(PhosphorIconsStyle.regular), color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('FORECAST DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final f = ctrl.currentForecast.value;
              
              if (f == null){
                return _buildRiskMatrixOnly(isDark);
              } else {
                // --- SAFE DATA EXTRACTION ---
                // Safely handles both Maps (Firestore) and Objects (Models)
                String dateStr = "N/A";
                String timeIssuedStr = "N/A";
                String validFromStr = "N/A";

                if (f is Map) {
                  // It's a Map from Firestore
                  if (f['issueDate'] != null) {
                    try {
                      DateTime dt = DateTime.parse(f['issueDate'].toString());
                      dateStr = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
                    } catch (_) {
                      dateStr = f['issueDate'].toString().split('T')[0];
                    }
                  }
                  timeIssuedStr = f['issueTime']?.toString() ?? 'N/A';
                  validFromStr = f['validTime']?.toString() ?? 'N/A';
                } else {
                  // Fallback for older Model objects
                  try { dateStr = f.date?.toString() ?? 'N/A'; } catch (_) {}
                  try { timeIssuedStr = f.timeIssued?.toString() ?? 'N/A'; } catch (_) {}
                  try { validFromStr = f.validFrom?.toString() ?? 'N/A'; } catch (_) {}
                }

                return Column(
                  children: [
                    _DetailRow(label: 'Date', value: dateStr, isDark: isDark),
                    _DetailRow(label: 'Time Issued', value: timeIssuedStr, isDark: isDark),
                    _DetailRow(label: 'Valid From', value: validFromStr, isDark: isDark),
                    const Divider(height: 30),
                    
                    _buildRiskMatrixOnly(isDark),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  // Extracted Matrix builder to keep the code DRY
  Widget _buildRiskMatrixOnly(bool isDark) {
    return Column(
      children: [ 
        Text("Weather Forecast Risk Matrix", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 12),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Y-Axis Label
            RotatedBox(
              quarterTurns: 3,
              child: Text("Likelihood", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.purple.shade200 : Colors.purple)),
            ),
            const SizedBox(width: 8),
            // The Grid
            Expanded(
              child: Column(
                children: [
                  Table(
                    border: TableBorder.all(color: isDark ? Colors.grey.shade600 : Colors.black, width: 1.5),
                    columnWidths: const {
                      0: FlexColumnWidth(1.2), // Label column
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      // High Row
                      TableRow(children: [
                        _RowHeaderCell("High (> 60%)", isDark),
                        _MatrixCell("G", Colors.yellowAccent.shade100),
                        _MatrixCell("H", Colors.orange),
                        _MatrixCell("I", Colors.red),
                      ]),
                      // Medium Row
                      TableRow(children: [
                        _RowHeaderCell("Medium (40% - 60%)", isDark),
                        _MatrixCell("D", Colors.green.shade400),
                        _MatrixCell("E", Colors.yellowAccent.shade100),
                        _MatrixCell("F", Colors.orange),
                      ]),
                      // Low Row
                      TableRow(children: [
                        _RowHeaderCell("Low (< 40%)", isDark),
                        _MatrixCell("A", Colors.green.shade400),
                        _MatrixCell("B", Colors.green.shade400),
                        _MatrixCell("C", Colors.yellowAccent.shade100),
                      ]),
                      // Bottom X-Axis labels mapped inside the table for alignment
                      TableRow(
                        decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
                        children: [
                          const SizedBox(), // Empty corner
                          _BottomHeaderCell("Low", isDark),
                          _BottomHeaderCell("Medium", isDark),
                          _BottomHeaderCell("High", isDark),
                        ]
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Impact", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.purple.shade200 : Colors.purple)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Sub-widgets for the Risk Matrix Table
Widget _RowHeaderCell(String text, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    alignment: Alignment.center,
    color: isDark ? Colors.grey.shade800 : Colors.white,
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
  );
}

Widget _BottomHeaderCell(String text, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    alignment: Alignment.center,
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
  );
}

Widget _MatrixCell(String letter, Color bgColor) {
  return Container(
    height: 40,
    alignment: Alignment.center,
    color: bgColor,
    // Note: Text is forced black inside matrix colored cells for readability
    child: Text(letter, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
  );
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _DetailRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}