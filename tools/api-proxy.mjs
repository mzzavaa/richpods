#!/usr/bin/env node
// Local CORS proxy for the public RichPods API.
//
// Why: api.richpods.org allowlists request Origins (CORS_ALLOWED_ORIGINS) and
// answers any other origin with 403 {"error":"Origin not allowed"}. A browser
// always sends Origin, so a local dev build cannot call it directly.
//
// This proxy forwards requests WITHOUT the browser's Origin header (which is
// what upstream rejects) and returns permissive CORS headers to the browser.
//
// Read-only against production data. Point the player at it with:
//   VITE_GRAPHQL_ENDPOINT=http://localhost:4000/graphql
//
// Usage: node richpods-tools/api-proxy.mjs [port]

import { createServer } from "node:http";

const PORT = Number(process.argv[2] ?? 4000);
const UPSTREAM = "https://api.richpods.org/graphql";

const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers": "content-type, authorization",
    "Access-Control-Max-Age": "600",
};

createServer(async (req, res) => {
    if (req.method === "OPTIONS") {
        res.writeHead(204, cors);
        return res.end();
    }

    const chunks = [];
    for await (const c of req) chunks.push(c);
    const body = Buffer.concat(chunks);

    try {
        const upstream = await fetch(UPSTREAM, {
            method: req.method,
            // Deliberately omit Origin and Referer: upstream 403s on unknown origins.
            headers: {
                "content-type": req.headers["content-type"] ?? "application/json",
                accept: req.headers.accept ?? "*/*",
                ...(req.headers.authorization ? { authorization: req.headers.authorization } : {}),
            },
            body: req.method === "GET" || req.method === "HEAD" ? undefined : body,
        });

        const text = await upstream.text();
        const op = tryOperationName(body);
        console.log(`${req.method} ${req.url} -> ${upstream.status}${op ? ` (${op})` : ""}`);

        res.writeHead(upstream.status, {
            ...cors,
            "content-type": upstream.headers.get("content-type") ?? "application/json",
        });
        res.end(text);
    } catch (err) {
        console.error("proxy error:", err.message);
        res.writeHead(502, { ...cors, "content-type": "application/json" });
        res.end(JSON.stringify({ errors: [{ message: `proxy: ${err.message}` }] }));
    }
// Bind loopback only. This proxy deliberately defeats an upstream CORS policy,
// so it must never be reachable from the network. Dev use only, never deploy it.
}).listen(PORT, "127.0.0.1", () => {
    console.log(`RichPods API proxy: http://127.0.0.1:${PORT}/graphql -> ${UPSTREAM}`);
    console.log("bound to loopback only — dev use only, do not deploy");
});

function tryOperationName(body) {
    try {
        const q = JSON.parse(body.toString("utf8"));
        return q.operationName || (q.query || "").trim().split(/[\s({]/).slice(0, 2).join(" ");
    } catch {
        return null;
    }
}
