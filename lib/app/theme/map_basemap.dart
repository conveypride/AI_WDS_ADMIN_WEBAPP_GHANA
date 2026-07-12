/// The basemap for the impact-based forecast maps.
///
/// One source of truth on purpose. The drawing maps used to render standard
/// OpenStreetMap tiles while the image generators exported onto CartoDB
/// Positron, so a forecaster drew on one map and published a different one.
///
/// Positron is a pale, low-saturation basemap: grey land, no landuse colour,
/// thin white roads. That matters because IBF polygons carry meaning in their
/// colour — GREEN / YELLOW / ORANGE / RED severity. On standard OSM the map's
/// own green landuse and coloured roads sit underneath those polygons and the
/// low-severity ones get lost; on Positron nothing on the basemap competes with
/// them.
///
/// A dark basemap was considered and rejected: the exported bulletin is light,
/// and yellow/orange glow against dark, so severity would read hotter while
/// drawing than it does in the published product.
class MapBasemap {
  const MapBasemap._();

  /// CartoDB Positron. `{s}` spreads tile requests across CARTO's hosts, which
  /// the interactive maps want; the image generators pin a single host instead.
  static const String urlTemplate =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  static const List<String> subdomains = ['a', 'b', 'c', 'd'];

  static const String userAgentPackageName = 'com.gmet.weather';

  /// CARTO's terms require attribution wherever these tiles are shown.
  static const String attribution = '© OpenStreetMap contributors © CARTO';
}
