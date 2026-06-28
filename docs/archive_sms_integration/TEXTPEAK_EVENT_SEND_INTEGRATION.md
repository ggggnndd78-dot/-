# Ghiyarak Phase 4 Ready Patch — TextPeak event_send Integration

This package updates the backend SMS layer to use the verified CommPeak/TextPeak Streams API event_send flow.

## Verified production test

The successful manual test used:

- Endpoint: `https://textpeak-streams.commpeak.com/event_send/`
- Event key: `login_otp`
- Sender: `GLOBAL`
- Template variable: `{code}` inside the TextPeak event template
- Phone format: international digits without `+`

The API returned `status: true` and `message_uuid`.

## Important TextPeak stream settings

Stream name:

```text
Ghiyarak OTP Transactional
```

Event template:

```text
Event key: login_otp
Template content: {code} is your Ghiyarak verification code. Do not share this code with anyone.
```

Do not use `{{code}}`; TextPeak event_send formatting uses `{code}`.

## Backend environment

Use:

```env
SMS_PROVIDER="COMMPEAK_EVENT_SEND"
COMMPEAK_SMS_EVENT_SEND_URL="https://textpeak-streams.commpeak.com/event_send/"
COMMPEAK_SMS_STATUS_URL="https://textpeak-streams.commpeak.com/messages_status/"
COMMPEAK_SMS_TOKEN="PASTE_NEW_GHIYARAK_OTP_TRANSACTIONAL_STREAM_TOKEN_HERE"
COMMPEAK_SMS_EVENT_KEY="login_otp"
COMMPEAK_SMS_SENDER="GLOBAL"
COMMPEAK_SMS_PHONE_FORMAT="NO_PLUS"
```

## Files changed

- `backend/src/modules/communications/sms.service.ts`
  - Added `COMMPEAK_EVENT_SEND` provider.
  - Sends payload to `event_send/` with `event`, `recipients`, `sender`, and `template_variables.code`.
  - Keeps old OTP auth route as optional fallback provider `COMMPEAK_OTP_AUTH`.

- `backend/.env.example`
  - Updated to the working event_send variables.
  - Removed markdown-link style CORS values.

- `tools/test_commpeak_sms.ps1`
  - Updated to test the actual working event_send route.

- `tools/check_commpeak_message_status.ps1`
  - Added helper to check delivery status by message UUID.

## Notes

The Saudi test arrived, but the sender appeared as `talabat` because the provider route/sender binding is still controlled by CommPeak. This does not block backend integration. When CommPeak binds `GHIYARAK` correctly, change:

```env
COMMPEAK_SMS_SENDER="GHIYARAK"
```

For Yemen Mobile, the provider reported `delivered` even when the handset did not receive the SMS. This is a carrier/provider DLR route issue, not a backend-code issue.
