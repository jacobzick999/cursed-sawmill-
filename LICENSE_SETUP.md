# License-key service setup

This repository now includes a Cloudflare Worker + D1 starter service. It supports license-key-only validation, key creation, optional expiration, and revocation.

## Security model

- License keys are generated using the Worker's cryptographic random generator.
- The API stores only SHA-256 hashes of keys, not plaintext keys.
- A newly generated plaintext key is returned once. Save it securely for the customer.
- Admin endpoints require the `ADMIN_TOKEN` Worker secret.
- The Roblox client must never contain `ADMIN_TOKEN`.
- This is an access-control layer, not tamper-proof DRM. A client-side script can be modified or its check bypassed. Strong enforcement requires code running in a game/server you control.

## 1. Create the D1 database

Install Wrangler and log in to Cloudflare, then run:

```sh
cd license-server
npx wrangler d1 create cursed-sawmill-licenses
```

Copy the returned database ID into `wrangler.toml`, replacing `REPLACE_WITH_YOUR_D1_DATABASE_ID`.

Apply the schema:

```sh
npx wrangler d1 execute cursed-sawmill-licenses --remote --file=schema.sql
```

## 2. Set the administrator secret and deploy

Generate a long random secret locally. Do not commit it to GitHub.

```sh
npx wrangler secret put ADMIN_TOKEN
npx wrangler deploy
```

Save the deployed Worker URL. It will look like `https://cursed-sawmill-license.<your-subdomain>.workers.dev`.

## 3. Create a license

Send this request from a trusted admin computer or private admin tool. Do not put the admin token in Roblox code or a public webpage.

```sh
curl -X POST "https://YOUR-WORKER-URL/admin/licenses" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

The response contains the new key. Store it safely; the service cannot display it again because only its hash is stored.

To create a key with an expiry, send an ISO-8601 value:

```json
{"expiresAt":"2027-01-01T00:00:00Z"}
```

## 4. Validate a license

```sh
curl -X POST "https://YOUR-WORKER-URL/v1/validate" \
  -H "Content-Type: application/json" \
  -d '{"key":"CUSTOMER-LICENSE-KEY"}'
```

A valid response looks like:

```json
{"valid":true,"product":"cursed-sawmill","expiresAt":null}
```

## 5. Revoke a license

```sh
curl -X POST "https://YOUR-WORKER-URL/admin/revoke" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key":"CUSTOMER-LICENSE-KEY"}'
```

## API routes

| Method | Route | Purpose |
| --- | --- | --- |
| GET | `/health` | Health check |
| POST | `/v1/validate` | Public license validation |
| POST | `/admin/licenses` | Create a key (admin secret required) |
| POST | `/admin/revoke` | Revoke a key (admin secret required) |

## Roblox integration note

The existing README script is a client-side LocalScript. Do not insert the administrator secret into it. A client-side validation request can deter casual sharing but cannot prevent a determined user from bypassing the check. For a Roblox experience you own, put the license check in a server Script or server-side ModuleScript and keep any trusted credentials in server-only storage. The current client-only project cannot securely enforce licensing by itself.
