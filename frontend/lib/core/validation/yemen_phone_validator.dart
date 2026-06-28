class YemenPhoneInfo {
  final String local;
  final String e164;
  final String carrierCode;
  final String carrierKey;
  final String carrierNameAr;
  final String carrierNameEn;

  const YemenPhoneInfo({
    required this.local,
    required this.e164,
    required this.carrierCode,
    required this.carrierKey,
    required this.carrierNameAr,
    required this.carrierNameEn,
  });
}

class YemenPhoneValidator {
  static const countryCode = '+967';

  static const Map<String, YemenPhoneInfo> _carriers = {
    '70': YemenPhoneInfo(
        local: '',
        e164: '',
        carrierCode: '70',
        carrierKey: 'Y_TELECOM',
        carrierNameAr: 'واي',
        carrierNameEn: 'Y Telecom'),
    '71': YemenPhoneInfo(
        local: '',
        e164: '',
        carrierCode: '71',
        carrierKey: 'SABAFON',
        carrierNameAr: 'سبأفون',
        carrierNameEn: 'Sabafon'),
    '73': YemenPhoneInfo(
        local: '',
        e164: '',
        carrierCode: '73',
        carrierKey: 'YOU',
        carrierNameAr: 'يو',
        carrierNameEn: 'YOU'),
    '77': YemenPhoneInfo(
        local: '',
        e164: '',
        carrierCode: '77',
        carrierKey: 'YEMEN_MOBILE',
        carrierNameAr: 'يمن موبايل',
        carrierNameEn: 'Yemen Mobile'),
    '78': YemenPhoneInfo(
        local: '',
        e164: '',
        carrierCode: '78',
        carrierKey: 'YEMEN_MOBILE',
        carrierNameAr: 'يمن موبايل',
        carrierNameEn: 'Yemen Mobile'),
  };

  static YemenPhoneInfo? tryParse(String input) {
    var value = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    value = value.replaceAll(RegExp(r'[^0-9+]'), '');

    if (value.startsWith('+967')) {
      value = value.substring(4);
    } else if (value.startsWith('00967')) {
      value = value.substring(5);
    } else if (value.startsWith('967')) {
      value = value.substring(3);
    } else if (value.startsWith('0')) {
      value = value.substring(1);
    }

    if (!RegExp(r'^7\d{8}$').hasMatch(value)) return null;
    final carrierCode = value.substring(0, 2);
    final carrier = _carriers[carrierCode];
    if (carrier == null) return null;

    return YemenPhoneInfo(
      local: value,
      e164: '$countryCode$value',
      carrierCode: carrier.carrierCode,
      carrierKey: carrier.carrierKey,
      carrierNameAr: carrier.carrierNameAr,
      carrierNameEn: carrier.carrierNameEn,
    );
  }

  static bool isValid(String input) => tryParse(input) != null;

  static String toE164(String input) {
    final parsed = tryParse(input);
    if (parsed == null) throw FormatException('Invalid Yemeni mobile number');
    return parsed.e164;
  }
}
