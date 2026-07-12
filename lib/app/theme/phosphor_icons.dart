import 'package:flutter/material.dart';

/// Drop-in replacement for `package:phosphor_flutter`.
///
/// phosphor_flutter 2.1.0 (its final release, from 2023) declares
/// `class PhosphorIconData extends IconData`. Flutter 3.44 made `IconData` a
/// **final** class, so the package no longer compiles and the whole app fails
/// to build. It is unmaintained and there is no fixed version to upgrade to.
///
/// Rather than rewrite 875 call sites, this file reproduces the slice of the
/// phosphor API the app actually uses and backs it with Flutter's built-in
/// Material icons. Call sites stay exactly as they were —
/// `PhosphorIcons.caretDown()`, `PhosphorIcons.bell(PhosphorIconsStyle.fill)` —
/// only the import changes. Depending on nothing but Flutter itself, this
/// cannot rot the same way again.
///
/// Phosphor's `fill`/`duotone` styles map to Material's filled glyphs and every
/// other style to the outlined ones, which keeps the filled-when-active look
/// the navigation and status chips rely on.
enum PhosphorIconsStyle { thin, light, regular, bold, fill, duotone }

bool _filled(PhosphorIconsStyle? style) =>
    style == PhosphorIconsStyle.fill || style == PhosphorIconsStyle.duotone;

/// The Material equivalents of the phosphor icons used in this app.
///
/// Each accepts an optional style, mirroring phosphor's own signature, and
/// returns the filled or outlined Material glyph accordingly.
class PhosphorIcons {
  const PhosphorIcons._();

  static IconData _pick(
    PhosphorIconsStyle? style,
    IconData filled,
    IconData outlined,
  ) => _filled(style) ? filled : outlined;

  // ── Arrows, carets & navigation ───────────────────────────────────────────
  static IconData arrowUp([PhosphorIconsStyle? s]) => Icons.arrow_upward;
  static IconData arrowDown([PhosphorIconsStyle? s]) => Icons.arrow_downward;
  static IconData arrowLeft([PhosphorIconsStyle? s]) => Icons.arrow_back;
  static IconData arrowRight([PhosphorIconsStyle? s]) => Icons.arrow_forward;
  static IconData arrowBendDownRight([PhosphorIconsStyle? s]) =>
      Icons.subdirectory_arrow_right;
  static IconData arrowClockwise([PhosphorIconsStyle? s]) => Icons.refresh;
  static IconData arrowCounterClockwise([PhosphorIconsStyle? s]) =>
      Icons.rotate_left;
  static IconData arrowsClockwise([PhosphorIconsStyle? s]) => Icons.sync;
  static IconData caretDown([PhosphorIconsStyle? s]) =>
      Icons.keyboard_arrow_down;
  static IconData caretLeft([PhosphorIconsStyle? s]) =>
      Icons.keyboard_arrow_left;
  static IconData caretRight([PhosphorIconsStyle? s]) =>
      Icons.keyboard_arrow_right;
  static IconData skipBack([PhosphorIconsStyle? s]) => Icons.skip_previous;
  static IconData signOut([PhosphorIconsStyle? s]) => Icons.logout;

  // ── Notifications ─────────────────────────────────────────────────────────
  static IconData bell([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.notifications, Icons.notifications_outlined);
  static IconData bellRinging([PhosphorIconsStyle? s]) => _pick(
    s,
    Icons.notifications_active,
    Icons.notifications_active_outlined,
  );
  static IconData bellZ([PhosphorIconsStyle? s]) => _pick(
    s,
    Icons.notifications_paused,
    Icons.notifications_paused_outlined,
  );
  static IconData broadcast([PhosphorIconsStyle? s]) => Icons.cell_tower;
  static IconData vibrate([PhosphorIconsStyle? s]) => Icons.vibration;

  // ── Weather ───────────────────────────────────────────────────────────────
  static IconData cloud([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.cloud, Icons.cloud_outlined);
  static IconData cloudArrowUp([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.cloud_upload, Icons.cloud_upload_outlined);
  static IconData cloudFog([PhosphorIconsStyle? s]) => Icons.foggy;
  static IconData cloudLightning([PhosphorIconsStyle? s]) => Icons.thunderstorm;
  static IconData cloudRain([PhosphorIconsStyle? s]) => Icons.water_drop;
  static IconData cloudSlash([PhosphorIconsStyle? s]) => Icons.cloud_off;
  static IconData cloudSnow([PhosphorIconsStyle? s]) => Icons.ac_unit;
  static IconData cloudSun([PhosphorIconsStyle? s]) => Icons.wb_cloudy;
  static IconData sun([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.wb_sunny, Icons.wb_sunny_outlined);
  static IconData sunDim([PhosphorIconsStyle? s]) => Icons.brightness_low;
  static IconData sunHorizon([PhosphorIconsStyle? s]) => Icons.wb_twilight;
  static IconData moon([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.dark_mode, Icons.dark_mode_outlined);
  static IconData moonStars([PhosphorIconsStyle? s]) => Icons.nights_stay;
  static IconData drop([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.water_drop, Icons.water_drop_outlined);
  static IconData dropSlash([PhosphorIconsStyle? s]) => Icons.invert_colors_off;
  static IconData wind([PhosphorIconsStyle? s]) => Icons.air;
  static IconData waves([PhosphorIconsStyle? s]) => Icons.waves;
  static IconData tornado([PhosphorIconsStyle? s]) => Icons.tornado;
  static IconData thermometer([PhosphorIconsStyle? s]) => Icons.thermostat;
  static IconData thermometerHot([PhosphorIconsStyle? s]) => Icons.whatshot;
  static IconData fire([PhosphorIconsStyle? s]) =>
      Icons.local_fire_department;

  // ── Time ──────────────────────────────────────────────────────────────────
  static IconData clock([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.access_time_filled, Icons.access_time);
  static IconData clockClockwise([PhosphorIconsStyle? s]) => Icons.update;
  static IconData clockCounterClockwise([PhosphorIconsStyle? s]) =>
      Icons.history;
  static IconData hourglass([PhosphorIconsStyle? s]) => Icons.hourglass_empty;
  static IconData calendar([PhosphorIconsStyle? s]) => Icons.calendar_today;
  static IconData calendarBlank([PhosphorIconsStyle? s]) =>
      Icons.calendar_month;
  static IconData calendarCheck([PhosphorIconsStyle? s]) =>
      Icons.event_available;
  static IconData calendarDot([PhosphorIconsStyle? s]) => Icons.event;
  static IconData calendarPlus([PhosphorIconsStyle? s]) => Icons.event_note;

  // ── Files & data ──────────────────────────────────────────────────────────
  static IconData file([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.insert_drive_file, Icons.insert_drive_file_outlined);
  static IconData files([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.file_copy, Icons.file_copy_outlined);
  static IconData fileText([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.description, Icons.description_outlined);
  static IconData fileCsv([PhosphorIconsStyle? s]) => Icons.table_view;
  static IconData fileXls([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.table_chart, Icons.table_chart_outlined);
  static IconData filePdf([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.picture_as_pdf, Icons.picture_as_pdf_outlined);
  static IconData folderOpen([PhosphorIconsStyle? s]) => Icons.folder_open;
  static IconData folders([PhosphorIconsStyle? s]) => Icons.folder_copy;
  static IconData archive([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.archive, Icons.archive_outlined);
  static IconData floppyDisk([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.save, Icons.save_outlined);
  static IconData database([PhosphorIconsStyle? s]) => Icons.storage;
  static IconData downloadSimple([PhosphorIconsStyle? s]) => Icons.download;
  static IconData paperclip([PhosphorIconsStyle? s]) => Icons.attach_file;
  static IconData clipboardText([PhosphorIconsStyle? s]) => Icons.assignment;
  static IconData notepad([PhosphorIconsStyle? s]) => Icons.event_note;
  static IconData book([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.book, Icons.book_outlined);
  static IconData image([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.image, Icons.image_outlined);
  static IconData imageBroken([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.broken_image, Icons.broken_image_outlined);
  static IconData trash([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.delete, Icons.delete_outline);

  // ── Charts & layout ───────────────────────────────────────────────────────
  static IconData chartBar([PhosphorIconsStyle? s]) => Icons.bar_chart;
  static IconData chartLine([PhosphorIconsStyle? s]) => Icons.show_chart;
  static IconData chartLineUp([PhosphorIconsStyle? s]) => Icons.trending_up;
  static IconData trendUp([PhosphorIconsStyle? s]) => Icons.trending_up;
  static IconData trendDown([PhosphorIconsStyle? s]) => Icons.trending_down;
  static IconData gauge([PhosphorIconsStyle? s]) => Icons.speed;
  static IconData table([PhosphorIconsStyle? s]) => Icons.table_chart;
  static IconData columns([PhosphorIconsStyle? s]) => Icons.view_column;
  static IconData rows([PhosphorIconsStyle? s]) => Icons.table_rows;
  static IconData list([PhosphorIconsStyle? s]) => Icons.list;
  static IconData dotsNine([PhosphorIconsStyle? s]) => Icons.apps;
  static IconData dotsThreeVertical([PhosphorIconsStyle? s]) => Icons.more_vert;
  static IconData sliders([PhosphorIconsStyle? s]) => Icons.tune;
  static IconData waveform([PhosphorIconsStyle? s]) => Icons.graphic_eq;

  // ── Mail ──────────────────────────────────────────────────────────────────
  static IconData envelope([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.mail, Icons.mail_outline);
  static IconData envelopeOpen([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.drafts, Icons.drafts_outlined);
  static IconData envelopeSimple([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.email, Icons.email_outlined);
  static IconData chatCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.chat_bubble, Icons.chat_bubble_outline);
  static IconData paperPlaneRight([PhosphorIconsStyle? s]) => Icons.send;
  static IconData paperPlaneTilt([PhosphorIconsStyle? s]) => Icons.send;

  // ── People ────────────────────────────────────────────────────────────────
  static IconData user([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.person, Icons.person_outline);
  static IconData userCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.account_circle, Icons.account_circle_outlined);
  static IconData userGear([PhosphorIconsStyle? s]) => Icons.manage_accounts;
  static IconData userPlus([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.person_add, Icons.person_add_outlined);
  static IconData userMinus([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.person_remove, Icons.person_remove_outlined);
  static IconData users([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.people, Icons.people_outline);
  static IconData usersThree([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.groups, Icons.groups_outlined);

  // ── Status & feedback ─────────────────────────────────────────────────────
  static IconData check([PhosphorIconsStyle? s]) => Icons.check;
  static IconData checks([PhosphorIconsStyle? s]) => Icons.done_all;
  static IconData checkCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.check_circle, Icons.check_circle_outline);
  static IconData x([PhosphorIconsStyle? s]) => Icons.close;
  static IconData xCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.cancel, Icons.cancel_outlined);
  static IconData warning([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.warning, Icons.warning_amber);
  static IconData warningCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.error, Icons.error_outline);
  static IconData warningOctagon([PhosphorIconsStyle? s]) => Icons.dangerous;
  static IconData info([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.info, Icons.info_outline);
  static IconData question([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.help, Icons.help_outline);
  static IconData shieldCheck([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.verified_user, Icons.verified_user_outlined);
  static IconData shieldWarning([PhosphorIconsStyle? s]) => Icons.gpp_maybe;
  static IconData spinner([PhosphorIconsStyle? s]) => Icons.autorenew;
  static IconData circle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.circle, Icons.circle_outlined);

  // ── Media controls ────────────────────────────────────────────────────────
  static IconData play([PhosphorIconsStyle? s]) => Icons.play_arrow;
  static IconData playCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.play_circle, Icons.play_circle_outline);
  static IconData pause([PhosphorIconsStyle? s]) => Icons.pause;
  static IconData pauseCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.pause_circle, Icons.pause_circle_outline);
  static IconData stop([PhosphorIconsStyle? s]) => Icons.stop;
  static IconData stopCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.stop_circle, Icons.stop_circle_outlined);
  static IconData microphone([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.mic, Icons.mic_none);
  static IconData speakerHigh([PhosphorIconsStyle? s]) => Icons.volume_up;

  // ── Actions & misc ────────────────────────────────────────────────────────
  static IconData plus([PhosphorIconsStyle? s]) => Icons.add;
  static IconData plusCircle([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.add_circle, Icons.add_circle_outline);
  static IconData minus([PhosphorIconsStyle? s]) => Icons.remove;
  static IconData pencilSimple([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.edit, Icons.edit_outlined);
  static IconData magnifyingGlass([PhosphorIconsStyle? s]) => Icons.search;
  static IconData eye([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.visibility, Icons.visibility_outlined);
  static IconData gear([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.settings, Icons.settings_outlined);
  static IconData gearSix([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.settings, Icons.settings_outlined);
  static IconData house([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.home, Icons.home_outlined);
  static IconData buildings([PhosphorIconsStyle? s]) => Icons.apartment;
  static IconData mapPin([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.place, Icons.place_outlined);
  static IconData mapTrifold([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.map, Icons.map_outlined);
  static IconData target([PhosphorIconsStyle? s]) => Icons.my_location;
  static IconData anchor([PhosphorIconsStyle? s]) => Icons.anchor;
  static IconData key([PhosphorIconsStyle? s]) => Icons.key;
  static IconData lockKey([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.lock, Icons.lock_outline);
  static IconData lightbulb([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.lightbulb, Icons.lightbulb_outline);
  static IconData tag([PhosphorIconsStyle? s]) =>
      _pick(s, Icons.label, Icons.label_outline);
}
