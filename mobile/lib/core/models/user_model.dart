class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    required this.language,
    required this.hasBirthChart,
    this.dob,
    this.tob,
    this.birthPlace,
    this.birthLat,
    this.birthLng,
    required this.whatsappEnabled,
    this.whatsappDeliveryTime,
    required this.subscriptionStatus,
    this.trialEndsAt,
    this.subscriptionEndsAt,
    required this.createdAt,
  });

  final String id;
  final String phone;
  final String? name;
  final String language;
  final bool hasBirthChart;
  final String? dob;
  final String? tob;
  final String? birthPlace;
  final double? birthLat;
  final double? birthLng;
  final bool whatsappEnabled;
  final String? whatsappDeliveryTime;
  final String subscriptionStatus;
  final String? trialEndsAt;
  final String? subscriptionEndsAt;
  final String createdAt;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        phone: j['phone'] as String,
        name: j['name'] as String?,
        language: (j['language'] as String?) ?? 'en',
        hasBirthChart: (j['has_birth_chart'] as bool?) ?? false,
        dob: j['dob'] as String?,
        tob: j['tob'] as String?,
        birthPlace: j['birth_place'] as String?,
        birthLat: (j['birth_lat'] as num?)?.toDouble(),
        birthLng: (j['birth_lng'] as num?)?.toDouble(),
        whatsappEnabled: (j['whatsapp_enabled'] as bool?) ?? false,
        whatsappDeliveryTime: j['whatsapp_delivery_time'] as String?,
        subscriptionStatus: (j['subscription_status'] as String?) ?? 'trial',
        trialEndsAt: j['trial_ends_at'] as String?,
        subscriptionEndsAt: j['subscription_ends_at'] as String?,
        createdAt: (j['created_at'] as String?) ?? '',
      );

  UserModel copyWith({
    String? name,
    String? language,
    bool? hasBirthChart,
    bool? whatsappEnabled,
    String? whatsappDeliveryTime,
    String? subscriptionStatus,
  }) =>
      UserModel(
        id: id,
        phone: phone,
        name: name ?? this.name,
        language: language ?? this.language,
        hasBirthChart: hasBirthChart ?? this.hasBirthChart,
        dob: dob,
        tob: tob,
        birthPlace: birthPlace,
        birthLat: birthLat,
        birthLng: birthLng,
        whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
        whatsappDeliveryTime: whatsappDeliveryTime ?? this.whatsappDeliveryTime,
        subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
        trialEndsAt: trialEndsAt,
        subscriptionEndsAt: subscriptionEndsAt,
        createdAt: createdAt,
      );

  bool get isActive => subscriptionStatus == 'active';
  bool get isTrial => subscriptionStatus == 'trial';
  String get displayName => name ?? phone;
}
