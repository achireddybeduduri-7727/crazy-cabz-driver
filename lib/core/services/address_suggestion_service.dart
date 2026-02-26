import 'dart:async';
import 'package:geocoding/geocoding.dart';

/// Service for handling address suggestions and geocoding
class AddressSuggestionService {
  static final AddressSuggestionService _instance =
      AddressSuggestionService._internal();
  factory AddressSuggestionService() => _instance;
  AddressSuggestionService._internal();

  /// Get address suggestions based on user input
  Future<List<AddressSuggestion>> getAddressSuggestions(String query) async {
    if (query.length < 3) {
      return [];
    }

    List<AddressSuggestion> suggestions = [];

    try {
      // Method 1: Try direct geocoding
      suggestions.addAll(await _getGeocodingSuggestions(query));

      // Method 2: If no results, try expanded search
      if (suggestions.isEmpty) {
        suggestions.addAll(await _getExpandedSuggestions(query));
      }

      // Method 3: If still no results, provide contextual suggestions
      if (suggestions.isEmpty) {
        suggestions.addAll(await _getContextualSuggestions(query));
      }
    } catch (e) {
      print('Error getting address suggestions: $e');
      // Return basic suggestions as fallback
      return _getBasicSuggestions(query);
    }

    // Remove duplicates and limit results
    final uniqueSuggestions = _removeDuplicates(suggestions);
    return uniqueSuggestions.take(5).toList();
  }

  /// Get suggestions using direct geocoding
  Future<List<AddressSuggestion>> _getGeocodingSuggestions(String query) async {
    List<AddressSuggestion> suggestions = [];

    try {
      // Timeout after 5 seconds to prevent hanging
      List<Location> locations = await locationFromAddress(
        query,
      ).timeout(const Duration(seconds: 5));

      for (Location location in locations.take(3)) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          ).timeout(const Duration(seconds: 3));

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final suggestion = _createSuggestionFromPlacemark(
              placemark,
              location,
            );
            if (suggestion != null) {
              suggestions.add(suggestion);
            }
          }
        } catch (e) {
          // Continue with next location if one fails
          continue;
        }
      }
    } catch (e) {
      print('Geocoding timeout or error: $e');
    }

    return suggestions;
  }

  /// Get expanded suggestions by trying different query variations
  Future<List<AddressSuggestion>> _getExpandedSuggestions(String query) async {
    List<AddressSuggestion> suggestions = [];

    // Try common variations of the query
    List<String> queryVariations = _generateQueryVariations(query);

    for (String variation in queryVariations) {
      try {
        List<Location> locations = await locationFromAddress(
          variation,
        ).timeout(const Duration(seconds: 3));

        if (locations.isNotEmpty) {
          Location location = locations.first;
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          ).timeout(const Duration(seconds: 2));

          if (placemarks.isNotEmpty) {
            final suggestion = _createSuggestionFromPlacemark(
              placemarks.first,
              location,
            );
            if (suggestion != null) {
              suggestions.add(suggestion);
            }
          }
        }
      } catch (e) {
        // Continue with next variation
        continue;
      }
    }

    return suggestions;
  }

  /// Get contextual suggestions based on common locations
  Future<List<AddressSuggestion>> _getContextualSuggestions(
    String query,
  ) async {
    List<AddressSuggestion> suggestions = [];

    // Define common location patterns
    List<String> contextualQueries = [
      '$query, New York, NY',
      '$query, Los Angeles, CA',
      '$query, Chicago, IL',
      '$query, Houston, TX',
      '$query, Phoenix, AZ',
      '$query Street',
      '$query Avenue',
      '$query Boulevard',
    ];

    for (String contextQuery in contextualQueries.take(3)) {
      try {
        List<Location> locations = await locationFromAddress(
          contextQuery,
        ).timeout(const Duration(seconds: 2));

        if (locations.isNotEmpty) {
          suggestions.add(
            AddressSuggestion(
              displayText: contextQuery,
              fullAddress: contextQuery,
              street: _extractStreet(contextQuery),
              city: _extractCity(contextQuery),
              state: _extractState(contextQuery),
              zipCode: _extractZipCode(contextQuery),
              latitude: locations.first.latitude,
              longitude: locations.first.longitude,
            ),
          );
        }
      } catch (e) {
        // Continue with next contextual query
        continue;
      }
    }

    return suggestions;
  }

  /// Generate query variations to improve search results
  List<String> _generateQueryVariations(String query) {
    List<String> variations = [];

    // Add common street suffixes if not present
    if (!query.toLowerCase().contains('st') &&
        !query.toLowerCase().contains('ave') &&
        !query.toLowerCase().contains('blvd') &&
        !query.toLowerCase().contains('rd') &&
        !query.toLowerCase().contains('dr')) {
      variations.add('$query St');
      variations.add('$query Ave');
      variations.add('$query Blvd');
    }

    // Add common city suffixes for partial matches
    if (query.length > 4 && !query.contains(',')) {
      variations.add('$query, USA');
    }

    return variations;
  }

  /// Create suggestion from placemark data
  AddressSuggestion? _createSuggestionFromPlacemark(
    Placemark placemark,
    Location location,
  ) {
    List<String> addressParts = [];

    String? street = placemark.street;
    String? city = placemark.locality;
    String? state = placemark.administrativeArea;
    String? zipCode = placemark.postalCode;

    if (street != null && street.isNotEmpty) {
      addressParts.add(street);
    }

    if (city != null && city.isNotEmpty) {
      addressParts.add(city);
    }

    if (state != null && state.isNotEmpty) {
      addressParts.add(state);
    }

    if (zipCode != null && zipCode.isNotEmpty) {
      addressParts.add(zipCode);
    }

    if (addressParts.isEmpty) {
      return null;
    }

    String fullAddress = addressParts.join(', ');

    return AddressSuggestion(
      displayText: fullAddress,
      fullAddress: fullAddress,
      street: street ?? '',
      city: city ?? '',
      state: state ?? '',
      zipCode: zipCode ?? '',
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  /// Get basic fallback suggestions
  List<AddressSuggestion> _getBasicSuggestions(String query) {
    if (query.length < 3) return [];

    return [
      AddressSuggestion(
        displayText: '$query (Type to search)',
        fullAddress: query,
        street: query,
        city: '',
        state: '',
        zipCode: '',
        latitude: 0.0,
        longitude: 0.0,
      ),
    ];
  }

  /// Remove duplicate suggestions
  List<AddressSuggestion> _removeDuplicates(
    List<AddressSuggestion> suggestions,
  ) {
    final seen = <String>{};
    return suggestions.where((suggestion) {
      return seen.add(suggestion.fullAddress.toLowerCase());
    }).toList();
  }

  /// Extract street from address string
  String _extractStreet(String address) {
    List<String> parts = address.split(', ');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Extract city from address string
  String _extractCity(String address) {
    List<String> parts = address.split(', ');
    return parts.length >= 2 ? parts[1] : '';
  }

  /// Extract state from address string
  String _extractState(String address) {
    List<String> parts = address.split(', ');
    if (parts.length >= 3) {
      // Handle "City, State Zip" format
      String stateZip = parts[2];
      List<String> stateZipParts = stateZip.split(' ');
      return stateZipParts.isNotEmpty ? stateZipParts[0] : '';
    }
    return '';
  }

  /// Extract zip code from address string
  String _extractZipCode(String address) {
    List<String> parts = address.split(', ');
    if (parts.length >= 3) {
      // Handle "City, State Zip" format
      String stateZip = parts[2];
      List<String> stateZipParts = stateZip.split(' ');
      return stateZipParts.length >= 2 ? stateZipParts[1] : '';
    }
    return '';
  }
}

/// Model for address suggestions
class AddressSuggestion {
  final String displayText;
  final String fullAddress;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;

  AddressSuggestion({
    required this.displayText,
    required this.fullAddress,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressSuggestion &&
        other.fullAddress.toLowerCase() == fullAddress.toLowerCase();
  }

  @override
  int get hashCode => fullAddress.toLowerCase().hashCode;

  @override
  String toString() => displayText;
}
