class PlanetModel {
  const PlanetModel({
    required this.name,
    required this.longitude,
    required this.sign,
    required this.degree,
    required this.retrograde,
  });

  final String name;
  final double longitude;
  final String sign;
  final double degree;
  final bool retrograde;

  factory PlanetModel.fromJson(Map<String, dynamic> j) => PlanetModel(
        name: j['name'] as String,
        longitude: (j['longitude'] as num).toDouble(),
        sign: j['sign'] as String,
        degree: (j['degree'] as num).toDouble(),
        retrograde: j['retrograde'] as bool,
      );
}

class HouseModel {
  const HouseModel({required this.house, required this.sign});
  final int house;
  final String sign;

  factory HouseModel.fromJson(Map<String, dynamic> j) => HouseModel(
        house: j['house'] as int,
        sign: j['sign'] as String,
      );
}

class DashaModel {
  const DashaModel({
    required this.mahadasha,
    required this.mahadashaRemainingYears,
    required this.antardasha,
    required this.antardashaRemainingYears,
  });

  final String mahadasha;
  final double mahadashaRemainingYears;
  final String antardasha;
  final double antardashaRemainingYears;

  factory DashaModel.fromJson(Map<String, dynamic> j) => DashaModel(
        mahadasha: j['mahadasha'] as String,
        mahadashaRemainingYears:
            (j['mahadasha_remaining_years'] as num).toDouble(),
        antardasha: j['antardasha'] as String,
        antardashaRemainingYears:
            (j['antardasha_remaining_years'] as num).toDouble(),
      );
}

class BirthChartModel {
  const BirthChartModel({
    required this.ayanamsa,
    required this.ascendant,
    required this.ascendantDegree,
    required this.sunSign,
    required this.moonSign,
    required this.planets,
    required this.houses,
    required this.dasha,
  });

  final double ayanamsa;
  final String ascendant;
  final double ascendantDegree;
  final String sunSign;
  final String moonSign;
  final List<PlanetModel> planets;
  final List<HouseModel> houses;
  final DashaModel dasha;

  factory BirthChartModel.fromJson(Map<String, dynamic> j) => BirthChartModel(
        ayanamsa: (j['ayanamsa'] as num).toDouble(),
        ascendant: j['ascendant'] as String,
        ascendantDegree: (j['ascendant_degree'] as num).toDouble(),
        sunSign: j['sun_sign'] as String,
        moonSign: j['moon_sign'] as String,
        planets: (j['planets'] as List<dynamic>)
            .map((p) => PlanetModel.fromJson(p as Map<String, dynamic>))
            .toList(),
        houses: (j['houses'] as List<dynamic>)
            .map((h) => HouseModel.fromJson(h as Map<String, dynamic>))
            .toList(),
        dasha: DashaModel.fromJson(j['dasha'] as Map<String, dynamic>),
      );
}
