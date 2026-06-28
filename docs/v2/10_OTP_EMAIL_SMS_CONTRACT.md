# OTP Email/SMS Contract

## Request OTP

`POST /api/v1/auth/request-otp`

### Phone OTP
```json
{
  "phone": "770000000",
  "channel": "SMS",
  "purpose": "LOGIN"
}
```

### Email OTP
```json
{
  "email": "user@example.com",
  "channel": "EMAIL",
  "purpose": "LOGIN"
}
```

## Verify OTP

`POST /api/v1/auth/verify-otp`

### Phone
```json
{
  "phone": "770000000",
  "otpCode": "123456",
  "purpose": "LOGIN",
  "displayName": "أحمد محمد"
}
```

### Email
```json
{
  "email": "user@example.com",
  "otpCode": "123456",
  "purpose": "LOGIN",
  "displayName": "أحمد محمد"
}
```

## Security rules

- OTP is stored as a hash, not plaintext.
- OTP expires after 5 minutes.
- OTP has max attempts.
- Consumed OTP cannot be reused.
- Request rate is limited by target within 10 minutes.
