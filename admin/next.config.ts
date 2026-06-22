import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Pin the file-tracing root to this app (not the repo root) so output tracing
  // works both locally (multiple lockfiles in the monorepo) and on Vercel —
  // a ".." root doubles the deploy path there (path0/path0 → ENOENT).
  outputFileTracingRoot: __dirname,
};

export default nextConfig;
