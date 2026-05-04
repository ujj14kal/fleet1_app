/// Mirrors the web TRUCK_CATALOGUE exactly.
/// [img] paths match the PNG files copied from Fleet-1/trucks/.
const List<Map<String, dynamic>> kTruckCatalogue = [
  {'id':'tata_ace_7ft',    'name':'Tata Ace · 7ft',     'cap_kg':750,   'cat':'part_load', 'img':'assets/images/tata_ace.png'},
  {'id':'bolero_8ft',      'name':'Bolero · 8ft',        'cap_kg':1000,  'cat':'part_load', 'img':'assets/images/bolero.png'},
  {'id':'open_10ft',       'name':'Open · 10ft',         'cap_kg':2000,  'cat':'part_load', 'img':'assets/images/open_small.png'},
  {'id':'open_14ft',       'name':'Open · 14ft',         'cap_kg':4000,  'cat':'part_load', 'img':'assets/images/open_medium.png'},
  {'id':'container_10ft',  'name':'Container · 10ft',    'cap_kg':2000,  'cat':'part_load', 'img':'assets/images/container_small.png'},
  {'id':'open_17ft',       'name':'Open · 17ft',         'cap_kg':7000,  'cat':'full_load', 'img':'assets/images/open_large.png'},
  {'id':'open_20ft',       'name':'Open · 20ft',         'cap_kg':10000, 'cat':'full_load', 'img':'assets/images/open_large.png'},
  {'id':'open_22ft',       'name':'Open · 22ft',         'cap_kg':12000, 'cat':'full_load', 'img':'assets/images/open_large.png'},
  {'id':'half_daala_32ft', 'name':'Half Daala · 32ft',   'cap_kg':15000, 'cat':'full_load', 'img':'assets/images/daala.png'},
  {'id':'container_14ft',  'name':'Container · 14ft',    'cap_kg':5000,  'cat':'full_load', 'img':'assets/images/container_large.png'},
  {'id':'container_20ft',  'name':'Container · 20ft',    'cap_kg':10000, 'cat':'full_load', 'img':'assets/images/container_large.png'},
  {'id':'container_32ft',  'name':'Container · 32ft',    'cap_kg':20000, 'cat':'full_load', 'img':'assets/images/container_large.png'},
  {'id':'trailer_20ft',    'name':'Trailer · 20ft',      'cap_kg':15000, 'cat':'full_load', 'img':'assets/images/trailer.png'},
  {'id':'trailer_28ft',    'name':'Trailer · 28ft',      'cap_kg':25000, 'cat':'full_load', 'img':'assets/images/trailer.png'},
  {'id':'trailer_32ft',    'name':'Trailer · 32ft',      'cap_kg':30000, 'cat':'full_load', 'img':'assets/images/trailer.png'},
];

/// Returns the image asset path for any truck_type string from Supabase.
String truckImage(String? truckType) {
  if (truckType == null) return 'assets/images/open_large.png';
  final match = kTruckCatalogue.firstWhere(
    (t) => t['id'] == truckType,
    orElse: () => <String, dynamic>{},
  );
  return (match['img'] as String?) ?? 'assets/images/open_large.png';
}
