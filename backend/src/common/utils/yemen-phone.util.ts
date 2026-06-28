export type YemenMobileCarrierCode = '70' | '71' | '73' | '77' | '78';

export type YemenMobileCarrier = {
  code: YemenMobileCarrierCode;
  key: string;
  nameAr: string;
  nameEn: string;
};

export const YEMEN_COUNTRY_CODE = '+967';

export const YEMEN_MOBILE_CARRIERS: Record<YemenMobileCarrierCode, YemenMobileCarrier> = {
  '70': { code: '70', key: 'Y_TELECOM', nameAr: 'واي', nameEn: 'Y Telecom' },
  '71': { code: '71', key: 'SABAFON', nameAr: 'سبأفون', nameEn: 'Sabafon' },
  '73': { code: '73', key: 'YOU', nameAr: 'يو', nameEn: 'YOU' },
  '77': { code: '77', key: 'YEMEN_MOBILE', nameAr: 'يمن موبايل', nameEn: 'Yemen Mobile' },
  '78': { code: '78', key: 'YEMEN_MOBILE', nameAr: 'يمن موبايل', nameEn: 'Yemen Mobile' },
};

export type NormalizedYemenPhone = {
  local: string;
  e164: string;
  carrierCode: YemenMobileCarrierCode;
  carrierKey: string;
  carrierNameAr: string;
  carrierNameEn: string;
};

function cleanPhoneInput(input: string): string {
  return String(input ?? '').trim().replace(/[\s\-().]/g, '');
}

export function normalizeYemeniMobile(input: string): NormalizedYemenPhone {
  const cleaned = cleanPhoneInput(input);
  let digits = cleaned.replace(/[^0-9+]/g, '');

  if (digits.startsWith('+967')) digits = digits.slice(4);
  else if (digits.startsWith('00967')) digits = digits.slice(5);
  else if (digits.startsWith('967')) digits = digits.slice(3);
  else if (digits.startsWith('0')) digits = digits.slice(1);

  if (!/^7\d{8}$/.test(digits)) {
    throw new Error('YEMEN_MOBILE_FORMAT_INVALID');
  }

  const carrierCode = digits.slice(0, 2) as YemenMobileCarrierCode;
  const carrier = YEMEN_MOBILE_CARRIERS[carrierCode];
  if (!carrier) {
    throw new Error('YEMEN_MOBILE_CARRIER_UNSUPPORTED');
  }

  return {
    local: digits,
    e164: `${YEMEN_COUNTRY_CODE}${digits}`,
    carrierCode,
    carrierKey: carrier.key,
    carrierNameAr: carrier.nameAr,
    carrierNameEn: carrier.nameEn,
  };
}

export function isValidYemeniMobile(input: string): boolean {
  try {
    normalizeYemeniMobile(input);
    return true;
  } catch {
    return false;
  }
}
