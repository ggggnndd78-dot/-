# Ghiyarak Phase 3.2.1 — TextPeak OTP Streams Fix

This build fixes the CommPeak/TextPeak integration for the actual stream type shown in the user's account:

- Stream name: SMS Stream - Transactional
- Stream type: SMS OTP
- Correct endpoint: `https://textpeak-streams.commpeak.com/otp/auth`
- Old endpoint removed from backend sending flow: `https://sendsms.commpeak.com/simple_send/`

## Required backend environment

```env
SMS_PROVIDER="COMMPEAK"
COMMPEAK_SMS_AUTH_URL="https://textpeak-streams.commpeak.com/otp/auth"
COMMPEAK_SMS_VERIFY_URL="https://textpeak-streams.commpeak.com/otp/verify"
COMMPEAK_SMS_TOKEN="PASTE_TRANSACTIONAL_STREAM_TOKEN_HERE"
COMMPEAK_SMS_SENDER="GLOBAL"
```

Use `GLOBAL` until the `GHIYARAK` sender ID is approved.

## Important

The OTP is generated and verified by Ghiyarak backend against the database table `iam_otp_requests`. TextPeak OTP Auth is used only for SMS delivery through the OTP stream template.
