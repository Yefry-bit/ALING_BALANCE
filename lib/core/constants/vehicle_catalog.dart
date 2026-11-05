/// Marcas y modelos más comunes en el mercado colombiano.
///
/// Se usan para sugerir mientras se escribe y para corregir mayúsculas,
/// tildes y guiones al guardar ("chevrolet" → "Chevrolet", "cx5" → "CX-5"),
/// así los registros quedan escritos siempre igual. Se puede escribir una
/// marca o un modelo que no esté en la lista.
abstract final class VehicleCatalog {
  /// Marca → modelos más comunes. El orden de las marcas es aproximadamente
  /// el de su presencia en el parque automotor (las más comunes primero).
  static const Map<String, List<String>> models = {
    'Chevrolet': [
      'Spark', 'Spark GT', 'Spark Life', 'Sail', 'Onix', 'Joy', 'Beat', //
      'Aveo', 'Aveo Emotion', 'Aveo Family', 'Optra', 'Corsa', 'Cobalt',
      'Sonic', 'Cruze', 'Malibu', 'Camaro', 'Spin', 'Zafira', 'Orlando',
      'Tracker', 'Groove', 'Captiva', 'Equinox', 'Blazer', 'Trailblazer',
      'Traverse', 'Tahoe', 'Suburban', 'Vitara', 'Grand Vitara', 'Esteem',
      'Swift', 'Luv', 'Luv D-Max', 'D-Max', 'Colorado', 'Montana', 'S10',
      'Silverado', 'N300', 'N400', 'NHR', 'NKR', 'NPR', 'NQR', 'FRR', 'FVR',
      'Bolt', 'Chevytaxi',
    ],
    'Renault': [
      'Logan', 'Sandero', 'Sandero RS', 'Stepway', 'Kwid', 'Kardian', //
      'Duster', 'Duster Oroch', 'Oroch', 'Clio', 'Twingo', 'Symbol',
      'Captur', 'Koleos', 'Arkana', 'Megane', 'Fluence', 'Scenic', 'Laguna',
      'R4', 'R9', 'R12', 'R18', 'R19', 'Alaskan', 'Kangoo', 'Dokker',
      'Master', 'Trafic', 'Zoe',
    ],
    'Mazda': [
      'Mazda 2', 'Mazda 3', 'Mazda 5', 'Mazda 6', 'CX-3', 'CX-30', 'CX-5', //
      'CX-50', 'CX-60', 'CX-7', 'CX-70', 'CX-9', 'CX-90', 'MX-30', 'MX-5',
      'BT-50', 'B2200', 'B2600', 'Allegro', 'Demio', 'Protegé', 'Tribute',
      '323', '626',
    ],
    'Kia': [
      'Picanto', 'Rio', 'Soluto', 'Cerato', 'K3', 'K5', 'Optima', 'Soul', //
      'Stonic', 'Sonet', 'Seltos', 'Sportage', 'Sorento', 'Mohave', 'Niro',
      'Carens', 'Carnival', 'Sephia', 'Spectra', 'EV5', 'EV6', 'EV9',
      'K2500', 'K2700', 'Frontier', 'Pregio', 'Besta',
    ],
    'Toyota': [
      'Corolla', 'Corolla Cross', 'Yaris', 'Yaris Cross', 'Etios', 'Agya', //
      'Wigo', 'Avanza', 'Prius', 'Camry', 'Starlet', 'Tercel', 'Raize',
      'Rush', 'C-HR', 'RAV4', 'Fortuner', 'Hilux', 'Hilux SW4', '4Runner',
      'Prado', 'Land Cruiser', 'Land Cruiser 70', 'Land Cruiser Prado',
      'FJ Cruiser', 'Sequoia', 'Tacoma', 'Tundra', 'Sienna', 'Hiace',
      'Coaster', 'bZ4X',
    ],
    'Nissan': [
      'March', 'Versa', 'Almera', 'Sunny', 'Sentra', 'Tiida', 'Note', //
      'Livina', 'Primera', 'Altima', 'Kicks', 'Juke', 'Qashqai', 'X-Trail',
      'Murano', 'Pathfinder', 'Terrano', 'Patrol', 'Frontier', 'Navara',
      'NP300', 'D21', 'D22', 'Pick Up', 'Urvan', 'Leaf',
    ],
    'Hyundai': [
      'Atos', 'i10', 'Grand i10', 'i20', 'i25', 'i30', 'Getz', 'Accent', //
      'Verna', 'HB20', 'Elantra', 'Sonata', 'Ioniq', 'Ioniq 5', 'Venue',
      'Creta', 'Kona', 'ix35', 'Tucson', 'Santa Fe', 'Veracruz', 'Palisade',
      'Santa Cruz', 'Matrix', 'Galloper', 'H-1', 'Starex', 'Staria',
      'Porter', 'HD65', 'HD78',
    ],
    'Volkswagen': [
      'Gol', 'Voyage', 'Fox', 'CrossFox', 'Up', 'Polo', 'Virtus', 'Jetta', //
      'Bora', 'Vento', 'Golf', 'Passat', 'Beetle', 'Escarabajo', 'Nivus',
      'Tera', 'T-Cross', 'Taos', 'Tiguan', 'Teramont', 'Touareg', 'ID.4',
      'Amarok', 'Saveiro', 'Caddy', 'Transporter', 'Crafter',
    ],
    'Ford': [
      'Ka', 'Fiesta', 'Focus', 'Fusion', 'EcoSport', 'Escape', 'Edge', //
      'Territory', 'Explorer', 'Expedition', 'Everest', 'Bronco',
      'Bronco Sport', 'Ranger', 'Ranger Raptor', 'Maverick', 'F-150',
      'F-250', 'F-350', 'Mustang', 'Mustang Mach-E', 'Transit',
    ],
    'Suzuki': [
      'Alto', 'Celerio', 'S-Presso', 'Swift', 'Dzire', 'Baleno', 'Ignis', //
      'Ciaz', 'Forsa', 'Sprint', 'SX4', 'Fronx', 'Ertiga', 'XL7', 'Vitara',
      'Grand Vitara', 'S-Cross', 'Jimny', 'Samurai', 'APV', 'Carry',
      'Super Carry',
    ],
    'Mitsubishi': [
      'Mirage', 'Space Star', 'Attrage', 'Lancer', 'Galant', 'ASX', //
      'Eclipse Cross', 'Outlander', 'Outlander PHEV', 'Montero',
      'Montero Sport', 'Nativa', 'Pajero', 'Pajero Sport', 'L200',
      'Xpander', 'Canter',
    ],
    'Honda': [
      'Fit', 'City', 'Civic', 'Accord', 'Insight', 'Prelude', 'HR-V', //
      'WR-V', 'BR-V', 'ZR-V', 'CR-V', 'Pilot', 'Odyssey', 'Element',
    ],
    'BYD': [
      'Seagull', 'Dolphin', 'Dolphin Mini', 'Seal', 'Seal U', 'Sealion 7', //
      'Atto 3', 'Yuan Plus', 'Song Plus', 'Han', 'Tang', 'King', 'Shark',
      'T3', 'F0', 'F3', 'S6',
    ],
    'JAC': [
      'J2', 'J4', 'J7', 'S2', 'S3', 'S4', 'S7', 'JS2', 'JS3', 'JS4', //
      'JS6', 'T6', 'T8', 'T9', 'E10X', 'E-JS1', 'E-JS4', 'X200', 'Sunray',
    ],
    'Peugeot': [
      '206', '207', '208', '2008', '301', '307', '308', '3008', '406', //
      '408', '508', '5008', 'Partner', 'Rifter', 'Expert', 'Boxer',
      'Landtrek',
    ],
    'Citroën': [
      'C3', 'C3 Aircross', 'C3 Picasso', 'C4', 'C4 Cactus', 'C4 Picasso', //
      'C-Elysée', 'C5', 'C5 Aircross', 'Berlingo', 'Jumpy', 'Jumper',
    ],
    'Mercedes-Benz': [
      'Clase A', 'Clase B', 'Clase C', 'Clase E', 'Clase S', 'Clase G', //
      'Clase V', 'CLA', 'GLA', 'GLB', 'GLC', 'GLE', 'GLS', 'EQA', 'EQB',
      'Vito', 'Sprinter', 'Accelo', 'Atego', 'Actros',
    ],
    'BMW': [
      'Serie 1', 'Serie 2', 'Serie 3', 'Serie 4', 'Serie 5', 'Serie 7', //
      'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'Z4', 'i3', 'i4', 'iX',
    ],
    'Audi': [
      'A1', 'A3', 'A4', 'A5', 'A6', 'A8', 'Q2', 'Q3', 'Q5', 'Q7', 'Q8', //
      'TT', 'e-tron',
    ],
    'Jeep': [
      'Renegade', 'Compass', 'Commander', 'Cherokee', 'Grand Cherokee', //
      'Liberty', 'Patriot', 'Wrangler', 'Gladiator', 'Willys', 'CJ',
    ],
    'Dodge': [
      'Attitude', 'Neon', 'Caliber', 'Avenger', 'Journey', 'Durango', //
      'Nitro', 'Dakota', 'Charger', 'Challenger', 'Ram 700',
    ],
    'RAM': ['700', '1000', '1200', '1500', '2500', '3500', 'Rampage'],
    'Subaru': [
      'Impreza', 'XV', 'Crosstrek', 'Forester', 'Outback', 'Legacy', //
      'Evoltis', 'WRX', 'BRZ', 'Solterra',
    ],
    'Fiat': [
      'Mobi', 'Uno', 'Palio', 'Siena', 'Grand Siena', 'Punto', 'Argo', //
      'Cronos', 'Tipo', '500', 'Pulse', 'Fastback', 'Strada', 'Toro',
      'Fiorino', 'Ducato',
    ],
    'Chery': [
      'QQ', 'IQ', 'Arrizo 5', 'Tiggo 2', 'Tiggo 2 Pro', 'Tiggo 3', //
      'Tiggo 4', 'Tiggo 4 Pro', 'Tiggo 5', 'Tiggo 7', 'Tiggo 7 Pro',
      'Tiggo 8', 'Tiggo 8 Pro', 'Van',
    ],
    'Great Wall': [
      'Wingle', 'Wingle 5', 'Wingle 7', 'Poer', 'Voleex C30', 'Hover', //
      'Haval H2', 'Haval H6', 'Haval Jolion',
    ],
    'Haval': ['H2', 'H6', 'H9', 'Jolion', 'Dargo'],
    'Changan': [
      'Alsvin', 'Benni', 'CS15', 'CS35', 'CS35 Plus', 'CS55', 'CS75', //
      'Uni-T', 'Uni-K', 'Hunter', 'Star Truck', 'Deepal S07',
    ],
    'DFSK': [
      'Glory 500', 'Glory 560', 'Glory 580', 'Glory 600', 'Seres 3', //
      'E5', 'C31', 'C32', 'C35', 'C37', 'K01', 'K07',
    ],
    'Foton': [
      'Tunland', 'Gratour', 'Toano', 'Sauvana', 'Midi', 'View', 'Aumark', //
      'Auman', 'BJ40',
    ],
    'Volvo': [
      'S40', 'S60', 'S80', 'V40', 'XC40', 'XC60', 'XC90', 'C40', 'EX30', //
      'FH', 'FMX',
    ],
    'Land Rover': [
      'Defender', 'Discovery', 'Discovery Sport', 'Freelander', //
      'Range Rover', 'Range Rover Evoque', 'Range Rover Sport',
      'Range Rover Velar',
    ],
    'SsangYong': [
      'Tivoli', 'Korando', 'Actyon', 'Kyron', 'Torres', 'Rexton', 'Musso', //
      'Stavic',
    ],
    'Seat': ['Ibiza', 'León', 'Toledo', 'Córdoba', 'Altea', 'Arona', 'Ateca'],
    'Isuzu': [
      'D-Max', 'MU-X', 'Rodeo', 'Trooper', 'Amigo', 'NHR', 'NKR', 'NPR', //
      'NQR', 'FRR', 'FVR',
    ],
    'Hino': ['Dutro', '300', '500', 'FC', 'GD'],
    'Mini': ['Cooper', 'Cooper S', 'Clubman', 'Countryman', 'Paceman'],
    'Porsche': [
      'Cayenne',
      'Macan',
      'Panamera',
      'Taycan',
      'Boxster',
      'Cayman',
      '911',
    ],
    'Daihatsu': ['Terios', 'Charade', 'Sirion', 'Feroza', 'Delta'],
    'Lexus': ['UX', 'NX', 'RX', 'GX', 'LX', 'ES', 'IS'],
    'Geely': [
      'Coolray', 'Emgrand', 'Azkarra', 'Okavango', 'Geometry C', 'GX3', //
      'EX5',
    ],
    'MG': ['MG3', 'MG4', 'MG5', 'ZS', 'ZX', 'HS', 'RX5', 'One'],
    'GAC': ['GS3', 'GS4', 'GS8', 'GN6', 'Emkoo', 'Emzoom', 'Aion Y'],
    'Jetour': ['X70', 'X70 Plus', 'Dashing', 'T2'],
    'JMC': ['Vigus', 'Carrying', 'Grand Avenue', 'N800'],
    'Kaiyi': ['X3', 'X3 Pro', 'X7'],
    'Zotye': ['T600', 'Z100', 'Nomada'],
    'Lifan': ['320', '520', '620', 'X50', 'X60', 'Foison'],
    'Dongfeng': ['Rich', 'AX7', 'S30', 'Captain'],
    'BAIC': ['X25', 'X35', 'X55', 'BJ40', 'EU5'],
    'Tesla': ['Model 3', 'Model Y', 'Model S', 'Model X'],
    'Cupra': ['Formentor', 'Born', 'Ateca', 'León'],
    'Skoda': ['Fabia', 'Octavia', 'Superb', 'Kamiq', 'Karoq', 'Kodiaq'],
    'Mahindra': ['Scorpio', 'Pik Up', 'XUV500', 'XUV700', 'KUV100'],
    'Daewoo': [
      'Tico', 'Matiz', 'Lanos', 'Cielo', 'Racer', 'Espero', 'Nubira', //
      'Leganza',
    ],
    'Opel': ['Corsa', 'Astra', 'Vectra', 'Zafira', 'Mokka'],
    'Alfa Romeo': ['Giulietta', 'MiTo', 'Giulia', 'Stelvio', 'Tonale'],
    'Jaguar': ['XE', 'XF', 'E-Pace', 'F-Pace', 'I-Pace'],
    'Chrysler': ['300C', 'PT Cruiser', 'Pacifica', 'Grand Caravan'],
    'Cadillac': ['Escalade', 'XT4', 'XT5', 'Lyriq'],
    'GMC': ['Sierra', 'Yukon', 'Acadia', 'Terrain', 'Canyon'],
    'Infiniti': ['Q50', 'QX50', 'QX60', 'QX80'],
    'Acura': ['MDX', 'RDX', 'TLX'],
    'Smart': ['Fortwo', 'Forfour'],
    'Kenworth': ['T370', 'T800', 'T880'],
    'International': ['4300', '7400', 'HV', 'MV'],
    'Freightliner': ['M2', 'Cascadia', 'Columbia'],
  };

  static final List<String> brands = List.unmodifiable(models.keys);

  /// Clave para comparar sin importar mayúsculas, tildes, espacios ni
  /// guiones: "Mercedes Benz" y "mercedes-benz" dan lo mismo.
  static String key(String value) {
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', //
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u', 'ë': 'e',
    };
    final buffer = StringBuffer();
    for (final char in value.toLowerCase().split('')) {
      final plain = accents[char] ?? char;
      if (RegExp(r'[a-z0-9]').hasMatch(plain)) buffer.write(plain);
    }
    return buffer.toString();
  }

  /// Marca escrita como en el catálogo; si no está, cada palabra con
  /// mayúscula inicial ("great wall" → "Great Wall").
  static String canonicalBrand(String value) {
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return text;

    final wanted = key(text);
    for (final brand in models.keys) {
      if (key(brand) == wanted) return brand;
    }
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Modelo escrito como en el catálogo de esa marca; si no está, se deja
  /// como se escribió (sin espacios de más).
  static String canonicalModel(String brand, String value) {
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final list = models[canonicalBrand(brand)];
    if (text.isEmpty || list == null) return text;

    final wanted = key(text);
    for (final model in list) {
      if (key(model) == wanted) return model;
    }
    return text;
  }

  /// Sugerencias para lo que se lleva escrito: primero las que empiezan
  /// igual, luego las que lo contienen. Sin texto, las primeras de la lista.
  static List<String> suggest(
    List<String> options,
    String query, {
    int limit = 12,
  }) {
    final wanted = key(query);
    if (wanted.isEmpty) return options.take(limit).toList();

    final starts = <String>[];
    final contains = <String>[];
    for (final option in options) {
      final k = key(option);
      if (k == wanted) continue; // ya está escrito completo
      if (k.startsWith(wanted)) {
        starts.add(option);
      } else if (k.contains(wanted)) {
        contains.add(option);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  /// Modelos de la marca (vacío si la marca no está en el catálogo).
  static List<String> modelsFor(String brand) =>
      models[canonicalBrand(brand)] ?? const [];

  static List<String> brandSuggestions(String query) => suggest(brands, query);

  static List<String> modelSuggestions(String brand, String query) =>
      suggest(models[canonicalBrand(brand)] ?? const [], query);
}
