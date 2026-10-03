# Afoosha Odaa - Backend API

Node.js + Express + TypeScript, with Supabase used purely as PostgreSQL.
Custom auth: phone number + 4-digit PIN (like Telebirr).

## 1. Setup

1. Create a Supabase project.
2. In **SQL Editor**, run in order:
   - `db/migrations/001_odaa_schema.sql`
   - `db/migrations/002_auth_functions.sql`
3. Copy `.env.example` to `.env` and fill it in (Supabase URL + **service-role** key, and two secrets).
   Generate secrets with:
   `node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"`
4. Install and create the first committee accounts:
   ```
   npm install
   cp scripts/committee.example.json scripts/committee.json   # edit names + phones
   npm run seed:committee                                     # prints temporary PINs once
   npm run dev
   ```
   Check: `GET http://localhost:4000/health`

If `bcrypt` fails to install on your machine, replace it with `bcryptjs`
(same API): change the import in `src/utils/pin.ts`.

## 1b. SMS with Afro Message

1. Get your **API token**, **Identifier ID** and an approved **Sender name** from the Afro Message dashboard.
2. In `.env` set:
   ```
   SMS_PROVIDER=afromessage
   AFROMESSAGE_TOKEN=...
   AFROMESSAGE_IDENTIFIER_ID=...
   AFROMESSAGE_SENDER_NAME=...
   ```
3. Test it: `npm run test:sms -- 09XXXXXXXX`

With `SMS_PROVIDER=console` (the default) messages are only printed in the terminal.
A failed SMS never blocks registering a member or resetting a PIN: the PIN is still
shown to the secretary, and the failure is logged.

## 2. API (base path `/api/v1`)

Success: `{ "data": ... }` - Error: `{ "error": { "code", "message", "details?" } }`

### Auth
| Method | Path | Who | Purpose |
|---|---|---|---|
| POST | `/auth/login` | public | phone + pin + deviceId -> tokens |
| POST | `/auth/refresh` | public | rotate refresh token |
| POST | `/auth/logout` | public | revoke session (refreshToken in body) |
| POST | `/auth/change-pin` | logged in (also with temp PIN) | currentPin + newPin |
| GET | `/auth/me` | logged in | own profile |
| GET | `/auth/devices` | logged in | own devices |
| DELETE | `/auth/devices/:id` | logged in | revoke own device |

### Members
| Method | Path | Who |
|---|---|---|
| GET | `/members?page&limit&q&status&role` | committee |
| POST | `/members` | secretary |
| GET | `/members/:id` | committee |
| PATCH | `/members/:id` | secretary, chairperson |
| PATCH | `/members/:id/status` | secretary, chairperson |
| POST | `/members/:id/reset-pin` | secretary (members only), chairperson |
| POST | `/members/:id/unlock` | secretary, chairperson |
| PATCH | `/members/:id/role` | chairperson |

Login body:
```json
{ "phone": "0911223344", "pin": "4821", "deviceId": "uuid-from-the-app",
  "deviceName": "Samsung A14", "platform": "android", "fcmToken": "..." }
```

## 3. Login flow for the mobile app

1. Login -> if `mustChangePin` is true, show the change-PIN screen. Until the PIN is changed,
   every other endpoint returns `403 PIN_CHANGE_REQUIRED`.
2. Send `Authorization: Bearer <accessToken>`. Access tokens last 15 minutes.
3. On `401 TOKEN_EXPIRED`, call `/auth/refresh` and store the NEW refresh token.
   **Run only one refresh at a time** (use a lock in the Dio interceptor). Presenting an
   already-used refresh token is treated as theft and revokes the whole session.
4. Store tokens and `deviceId` in `flutter_secure_storage`.

## 4. Security rules implemented

- PINs: HMAC(pepper) + bcrypt (cost 12). Weak PINs rejected (repeats, sequences, years, common).
- Lockout: 5 wrong PINs -> 15 min; locked again within 24h -> 30 min. Enforced atomically in SQL.
- Rate limits on login: 20/15 min per IP and 10/15 min per phone (in memory; use Redis if you run several instances).
- Same error for unknown phone and wrong PIN; timing equalized.
- Device binding: first device auto-trusted; later new devices are allowed but audited (SMS OTP planned for Phase 2).
- Refresh tokens: hashed, rotated on every use, reuse detection.
- Every request re-checks member status and device in the database, so suspension and revocation are immediate.
- Only the chairperson can reset, unlock, suspend or edit committee accounts (a secretary cannot take over a committee account). The chairperson's own PIN is reset with `npm run reset-pin -- <phone>`.
- Audit log for registration, PIN reset/change, unlock, role/status changes, lockouts, committee logins.

## 5. Notes

- Temporary PINs are returned to the secretary once and also sent by SMS (Afro Message, see 1b).
- Message texts in `src/i18n/messages.ts` should be reviewed by a native Afaan Oromoo speaker.
- Supabase has no multi-statement transactions through the JS client; operations are ordered so a
  partial failure never leaves a member with a working but unrecorded session.
