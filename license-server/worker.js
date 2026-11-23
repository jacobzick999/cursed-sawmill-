const PRODUCT = "cursed-sawmill";

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store"
    }
  });
}

function toBase64Url(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function hashKey(key) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(key));
  return [...new Uint8Array(digest)].map(x => x.toString(16).padStart(2, "0")).join("");
}

function isAdmin(request, env) {
  const supplied = request.headers.get("authorization") || "";
  return Boolean(env.ADMIN_TOKEN) && supplied === `Bearer ${env.ADMIN_TOKEN}`;
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ ok: true, service: "license-api" });
    }

    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    if (url.pathname === "/v1/validate") {
      const body = await readJson(request);
      if (!body || typeof body.key !== "string" || body.key.length < 20 || body.key.length > 160) {
        return json({ valid: false, error: "invalid_request" }, 400);
      }

      const keyHash = await hashKey(body.key.trim());
      const license = await env.DB.prepare(
        "SELECT product, expires_at, revoked_at FROM licenses WHERE key_hash = ?"
      ).bind(keyHash).first();

      if (!license || license.product !== PRODUCT || license.revoked_at) {
        return json({ valid: false, error: "invalid_or_revoked" }, 200);
      }

      if (license.expires_at && Date.parse(license.expires_at) <= Date.now()) {
        return json({ valid: false, error: "expired" }, 200);
      }

      return json({ valid: true, product: license.product, expiresAt: license.expires_at });
    }

    if (url.pathname === "/admin/licenses") {
      if (!isAdmin(request, env)) return json({ error: "unauthorized" }, 401);

      const body = await readJson(request);
      if (!body || (body.expiresAt != null &&
          (typeof body.expiresAt !== "string" || !Number.isFinite(Date.parse(body.expiresAt))))) {
        return json({ error: "invalid_request" }, 400);
      }

      const raw = new Uint8Array(24);
      crypto.getRandomValues(raw);
      const key = "CSM-" + toBase64Url(raw);
      const keyHash = await hashKey(key);
      const expiresAt = body.expiresAt || null;

      await env.DB.prepare(
        "INSERT INTO licenses (key_hash, product, expires_at) VALUES (?, ?, ?)"
      ).bind(keyHash, PRODUCT, expiresAt).run();

      // The plaintext key is returned only once; only its SHA-256 hash is stored.
      return json({ created: true, key, product: PRODUCT, expiresAt }, 201);
    }

    if (url.pathname === "/admin/revoke") {
      if (!isAdmin(request, env)) return json({ error: "unauthorized" }, 401);
      const body = await readJson(request);
      if (!body || typeof body.key !== "string") return json({ error: "invalid_request" }, 400);

      const keyHash = await hashKey(body.key.trim());
      const result = await env.DB.prepare(
        "UPDATE licenses SET revoked_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now') WHERE key_hash = ? AND revoked_at IS NULL"
      ).bind(keyHash).run();

      return json({ revoked: result.meta.changes > 0 });
    }

    return json({ error: "not_found" }, 404);
  }
};
