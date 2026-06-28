# Ghiyarak Demo Accounts and Yemen Phone Rules

## Yemen Mobile Number Policy

The platform accepts Yemeni mobile numbers only.

Allowed formats:

- `7XXXXXXXX`
- `07XXXXXXXX`
- `9677XXXXXXXX`
- `009677XXXXXXXX`
- `+9677XXXXXXXX`

Allowed Yemeni mobile prefixes:

| Prefix | Operator |
|---|---|
| 70 | Y / واي |
| 71 | Sabafon / سبأفون |
| 73 | YOU / يو |
| 77 | Yemen Mobile / يمن موبايل |
| 78 | Yemen Mobile / يمن موبايل |

Any other prefix is rejected in both Flutter and backend.

## Seeded Demo Accounts

After running:

```powershell
cd backend
npx prisma migrate reset --force
npx prisma generate
npm run prisma:seed
npm run start:dev
```

Use these phone numbers from the login screen. The app does not ask for role selection. The system detects the role after phone verification.

| Role | Phone | Operator |
|---|---:|---|
| Super Admin | 781699203 | Y |
| Operations Admin | 700000002 | Y |
| Finance Manager | 700000003 | Y |
| Support Agent | 700000004 | Y |
| Customer | 710000001 | Sabafon |
| Merchant Owner | 711111111 | Sabafon |
| Merchant Employee | 711111112 | Sabafon |
| Workshop Owner | 733333333 | YOU |
| Workshop Employee | 733333334 | YOU |
| Warehouse Owner | 770000001 | Yemen Mobile |
| Warehouse Employee | 770000002 | Yemen Mobile |
| Driver | 780000001 | Yemen Mobile |

## Local OTP Testing

For local testing, keep:

```env
SMS_PROVIDER="CONSOLE"
```

The OTP appears in the backend terminal and is also returned in development response as `if_dev_mode_otp`.

For real SMS, switch to:

```env
SMS_PROVIDER="COMMPEAK_EVENT_SEND"
COMMPEAK_SMS_TOKEN="YOUR_REAL_TOKEN"
```
