import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/services/cafo_pdf_import_service.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

/// Shown before a parsed bulletin is written into the daily forecast table.
///
/// The CSV import overwrites silently; a PDF is machine-read rather than
/// authored against a template, so the forecaster gets to see exactly what will
/// land in the table — and what will not — before anything is overwritten.
class PdfImportPreviewDialog extends StatelessWidget {
  const PdfImportPreviewDialog({
    super.key,
    required this.bulletin,
    required this.rows,
    required this.onApply,
  });

  final ParsedBulletin bulletin;
  final List<PdfImportRow> rows;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;

    final matched = rows.where((r) => r.isMatched).toList();
    final unmatched = rows.where((r) => !r.isMatched).toList();
    final unmappedConditions = <String>{
      for (final row in rows) ...row.unmappedConditions,
    };

    return Dialog(
      backgroundColor: wc.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detected(context, matched.length),
                    if (bulletin.warnings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (final warning in bulletin.warnings)
                        _notice(
                          context,
                          warning,
                          AppTheme.warningAmber,
                          PhosphorIcons.warning(),
                        ),
                    ],
                    if (unmatched.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _notice(
                        context,
                        "${unmatched.length} city(ies) in the PDF are not "
                        "configured for this department and will be skipped: "
                        "${unmatched.map((r) => r.pdfCityName).join(', ')}.",
                        AppTheme.warningAmber,
                        PhosphorIcons.warning(),
                      ),
                    ],
                    if (unmappedConditions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _notice(
                        context,
                        "These conditions are not in this department's weather "
                        "list and will be entered as free text: "
                        "${unmappedConditions.join(', ')}.",
                        AppTheme.infoCyan,
                        PhosphorIcons.info(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _notice(
                      context,
                      "The bulletin only prints a probability for rain and "
                      "storms. Conditions without one are set to 0%.",
                      AppTheme.infoCyan,
                      PhosphorIcons.info(),
                    ),
                    if (bulletin.summary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        "SUMMARY (will replace the current text)",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: wc.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: wc.elevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: wc.border),
                        ),
                        child: Text(
                          bulletin.summary,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: wc.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _table(context),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _actions(context, matched.length),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final wc = context.wColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Icon(PhosphorIcons.filePdf(), size: 22, color: AppTheme.accentBlue),
          const SizedBox(width: 10),
          Text(
            "PDF IMPORT PREVIEW",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 0.5,
              color: wc.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// What the parser understood about the bulletin as a whole.
  Widget _detected(BuildContext context, int matchedCount) {
    final issueTime = bulletin.issueTime;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(
          context,
          "ISSUED AT",
          issueTime == null ? "UNKNOWN" : "$issueTime UTC",
          issueTime == null ? AppTheme.warningAmber : AppTheme.accentBlue,
        ),
        _chip(
          context,
          "COLUMNS",
          bulletin.periodHeaders.join(" / "),
          AppTheme.accentBlue,
        ),
        _chip(
          context,
          "CITIES MATCHED",
          "$matchedCount of ${rows.length}",
          matchedCount == rows.length
              ? AppTheme.successGreen
              : AppTheme.warningAmber,
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.wColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: context.wColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Every parsed row, so nothing lands in the table unseen.
  Widget _table(BuildContext context) {
    final wc = context.wColors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: wc.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              color: wc.elevated,
              child: Row(
                children: [
                  _cell("CITY", flex: 16, bold: true, context: context),
                  for (final header in bulletin.periodHeaders)
                    _cell(header, flex: 28, bold: true, context: context),
                ],
              ),
            ),
            for (var i = 0; i < rows.length; i++)
              Container(
                decoration: BoxDecoration(
                  color: rows[i].isMatched
                      ? (i.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3))
                      : AppTheme.warningAmber.withOpacity(0.08),
                  border: Border(top: BorderSide(color: wc.borderSoft)),
                ),
                child: Row(
                  children: [
                    _cell(
                      rows[i].isMatched
                          ? rows[i].pdfCityName
                          : "${rows[i].pdfCityName}  (skipped)",
                      flex: 16,
                      bold: true,
                      muted: !rows[i].isMatched,
                      context: context,
                    ),
                    for (final slot in rows[i].slots)
                      _cell(
                        _describe(slot),
                        flex: 28,
                        muted: !rows[i].isMatched,
                        context: context,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "SL’T RAIN · 30% · 26°" — the three values that will fill the row's cells.
  String _describe(ParsedSlot slot) {
    if (slot.isEmpty) return "—";
    final parts = <String>[
      if (slot.weather.isNotEmpty) slot.weather,
      if (slot.prob.isNotEmpty) "${slot.prob}%",
      if (slot.temp.isNotEmpty) "${slot.temp}°",
    ];
    return parts.join("  ·  ");
  }

  Widget _cell(
    String text, {
    required int flex,
    required BuildContext context,
    bool bold = false,
    bool muted = false,
  }) {
    final wc = context.wColors;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: muted ? wc.textMuted : wc.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, int matchedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "CANCEL",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: context.wColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            // Nothing to write if not one city lined up with this department.
            onPressed: matchedCount == 0 ? null : onApply,
            icon: Icon(PhosphorIcons.checkCircle(), size: 18),
            label: Text(
              matchedCount == 0
                  ? "NOTHING TO IMPORT"
                  : "APPLY TO TABLE ($matchedCount)",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
