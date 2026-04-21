import 'dart:convert';
import 'dart:isolate';

/// Top-level functions for Isolate.run — must be static/top-level.
/// These offload JSON parsing from the main thread.

/// Parse a raw JSON response body string into a Map.
Map<String, dynamic> _decodeJsonMap(String body) {
  return json.decode(body) as Map<String, dynamic>;
}

/// Parse a raw JSON response body string into a List.
List<dynamic> _decodeJsonList(String body) {
  return json.decode(body) as List<dynamic>;
}

/// Offload JSON map parsing to an Isolate.
Future<Map<String, dynamic>> parseJsonMap(String body) {
  return Isolate.run(() => _decodeJsonMap(body));
}

/// Offload JSON list parsing to an Isolate.
Future<List<dynamic>> parseJsonList(String body) {
  return Isolate.run(() => _decodeJsonList(body));
}

/// Parse Google Places autocomplete suggestions in an Isolate.
/// Returns a list of description strings.
Future<List<String>> parseAddressSuggestions(String body) {
  return Isolate.run(() {
    final data = json.decode(body) as Map<String, dynamic>;
    final predictions = data['predictions'] as List<dynamic>? ?? [];
    return predictions
        .map((p) => (p as Map<String, dynamic>)['description'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  });
}

/// Parse Places API v1 autocomplete response (used by the /autocomplete edge function).
/// New API shape: { suggestions: [{ placePrediction: { text: { text: "..." } } }] }
Future<List<String>> parsePlacesV1Suggestions(String body) {
  return Isolate.run(() {
    final data = json.decode(body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List<dynamic>? ?? [];
    return suggestions
        .map((s) {
          final pred = (s as Map<String, dynamic>)['placePrediction']
              as Map<String, dynamic>?;
          return (pred?['text'] as Map<String, dynamic>?)?['text'] as String? ??
              '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  });
}

/// Parse Google Directions route polyline + distance/duration in an Isolate.
/// Returns a map with 'points', 'distance_km', 'duration_min' keys.
Future<Map<String, dynamic>> parseRouteData(String body) {
  return Isolate.run(() {
    final data = json.decode(body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? [];
    if (routes.isEmpty) {
      return <String, dynamic>{
        'points': '',
        'distance_km': 0.0,
        'duration_min': 0.0,
      };
    }
    final route = routes[0] as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>? ?? [];
    if (legs.isEmpty) {
      return <String, dynamic>{
        'points': route['overview_polyline']?['points'] ?? '',
        'distance_km': 0.0,
        'duration_min': 0.0,
      };
    }
    final leg = legs[0] as Map<String, dynamic>;
    final distanceM = (leg['distance']?['value'] as num?)?.toDouble() ?? 0.0;
    final durationS = (leg['duration']?['value'] as num?)?.toDouble() ?? 0.0;
    return <String, dynamic>{
      'points': route['overview_polyline']?['points'] ?? '',
      'distance_km': distanceM / 1000.0,
      'duration_min': durationS / 60.0,
    };
  });
}

/// Parse Supabase fare response in an Isolate.
Future<List<Map<String, dynamic>>> parseFareResponse(String body) {
  return Isolate.run(() {
    final data = json.decode(body) as Map<String, dynamic>;
    final fares = data['fares'] as List<dynamic>? ?? [];
    return fares
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();
  });
}

/// Parse Routes API v2 response in an Isolate.
/// Returns 'encodedPolyline', 'distance_km', 'duration_min'.
Future<Map<String, dynamic>> parseRoutesV2Data(String body) {
  return Isolate.run(() {
    final data = json.decode(body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? [];
    if (routes.isEmpty) {
      return <String, dynamic>{
        'encodedPolyline': '',
        'distance_km': 0.0,
        'duration_min': 0.0,
      };
    }
    final route = routes[0] as Map<String, dynamic>;
    final distanceM = (route['distanceMeters'] as num?)?.toDouble() ?? 0.0;
    final durationStr = route['duration'] as String? ?? '0s';
    final durationS =
        double.tryParse(durationStr.replaceAll('s', '')) ?? 0.0;
    final encodedPolyline =
        (route['polyline'] as Map<String, dynamic>?)?['encodedPolyline']
            as String? ??
            '';
    return <String, dynamic>{
      'encodedPolyline': encodedPolyline,
      'distance_km': distanceM / 1000.0,
      'duration_min': durationS / 60.0,
    };
  });
}

/// Parse geocode result (lat/lng) in an Isolate.
Future<Map<String, double>?> parseGeocodeResult(String body) {
  return Isolate.run(() {
    final data = json.decode(body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) return null;
    final location =
        results[0]['geometry']?['location'] as Map<String, dynamic>?;
    if (location == null) return null;
    return {
      'lat': (location['lat'] as num).toDouble(),
      'lng': (location['lng'] as num).toDouble(),
    };
  });
}
