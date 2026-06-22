# Viele Admin Console — Foundation + Moderation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `admin/` Next.js app with admin-gated auth, the Viele-tinted design shell, and a working **moderation review queue** (review reports → remove/dismiss/restore posts) deployed to Vercel — the TestFlight-unblocking slice.

**Architecture:** Next.js (App Router) + TypeScript at `admin/`, separate from the Flutter app. Auth via `@supabase/ssr` cookie sessions; authorization on `app_metadata.role === 'admin'` enforced by middleware **and** re-checked in every server action. The moderation queue reads the existing `moderation_queue()` RPC and writes via `moderate_post()` (both already live, `is_admin()`-gated) using the admin's JWT — no service role needed in this plan.

**Tech Stack:** Next.js 15 (App Router), TypeScript, `@supabase/ssr`, `@supabase/supabase-js`, Tailwind CSS v4, Vitest + @testing-library/react, Vercel.

## Global Constraints

- Next.js App Router + TypeScript only. Node ≥ 20.
- Pin every dependency to an exact version; commit `admin/package-lock.json`.
- `service_role`/secret keys **never** in the client bundle — not used at all in this plan (admin-as-user JWT only). Only `NEXT_PUBLIC_SUPABASE_URL` + `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` reach the browser.
- Authorization source of truth: `app_metadata.role === 'admin'` (never `user_metadata`). Re-verify admin server-side on every privileged action — never trust middleware alone.
- **Never** render `weight_kg` or any private field in any admin payload.
- Supabase project id: `mdgublyyxcgpwvnmnlxe`. Supabase URL `https://mdgublyyxcgpwvnmnlxe.supabase.co`, publishable key `sb_publishable_cK04mJ2VmBTal8fqsB-oug_uF7xckv9`.
- Design tokens (verbatim): canvas `#FAF8F4`, surface `#FFFFFF`, ink `#1E1A14`, ink-2 `#766C5C`, ink-3 `#A89C88`, hairline `#ECE4D6`, hairline-2 `#E2D8C6`, accent `#1F7D4A`, accent-soft `#E7F2EA`, danger `#C0392B`, danger-soft `#FBE9E7`, warning `#B9772A`, sand `#F3EEE4`. Radius 8–10px. Font: SF Pro / system. Tabular numerals where numbers matter.

---

### Task 1: Scaffold the `admin/` Next.js app + tooling

**Files:**
- Create: `admin/package.json`, `admin/tsconfig.json`, `admin/next.config.ts`, `admin/.gitignore`, `admin/.env.local.example`, `admin/app/globals.css`, `admin/app/layout.tsx`, `admin/app/page.tsx`, `admin/vitest.config.ts`, `admin/vitest.setup.ts`, `admin/lib/tokens.ts`
- Test: `admin/lib/tokens.test.ts`

**Interfaces:**
- Produces: `admin/lib/tokens.ts` exporting `const tokens` (the design tokens object) and a Tailwind theme; `globals.css` with CSS variables for every token in Global Constraints.

- [ ] **Step 1: Create the Next.js app non-interactively**

Run:
```bash
cd /Users/akashsuryavanshi/Projects/Viele
npx --yes create-next-app@latest admin --ts --app --tailwind --eslint --no-src-dir --import-alias "@/*" --use-npm --skip-install
```
Expected: `admin/` created with App Router + Tailwind + TS.

- [ ] **Step 2: Pin deps + add test tooling, then install**

Edit `admin/package.json` `dependencies`/`devDependencies` to exact versions (no `^`):
```json
{
  "dependencies": {
    "next": "15.5.4",
    "react": "19.1.0",
    "react-dom": "19.1.0",
    "@supabase/supabase-js": "2.45.4",
    "@supabase/ssr": "0.5.1"
  },
  "devDependencies": {
    "typescript": "5.6.3",
    "@types/node": "22.7.4",
    "@types/react": "19.1.0",
    "@types/react-dom": "19.1.0",
    "tailwindcss": "4.0.0",
    "@tailwindcss/postcss": "4.0.0",
    "vitest": "2.1.2",
    "@testing-library/react": "16.0.1",
    "@testing-library/jest-dom": "6.5.0",
    "jsdom": "25.0.1",
    "@vitejs/plugin-react": "4.3.2",
    "eslint": "9.12.0",
    "eslint-config-next": "15.5.4"
  }
}
```
Run: `cd admin && npm install`
Expected: `admin/package-lock.json` created, no errors. (If a pinned version is yanked, bump to the nearest published patch and note it.)

- [ ] **Step 3: Add Vitest config + setup**

Create `admin/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'node:path'

export default defineConfig({
  plugins: [react()],
  test: { environment: 'jsdom', globals: true, setupFiles: ['./vitest.setup.ts'] },
  resolve: { alias: { '@': path.resolve(__dirname, '.') } },
})
```
Create `admin/vitest.setup.ts`:
```ts
import '@testing-library/jest-dom/vitest'
```
Add to `admin/package.json` `scripts`: `"test": "vitest run"`, `"test:watch": "vitest"`.

- [ ] **Step 4: Write the failing test for tokens**

Create `admin/lib/tokens.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { tokens } from './tokens'

describe('design tokens', () => {
  it('exposes the Viele-tinted palette verbatim', () => {
    expect(tokens.accent).toBe('#1F7D4A')
    expect(tokens.ink).toBe('#1E1A14')
    expect(tokens.danger).toBe('#C0392B')
    expect(tokens.canvas).toBe('#FAF8F4')
  })
})
```

- [ ] **Step 5: Run test to verify it fails**

Run: `cd admin && npm test -- lib/tokens.test.ts`
Expected: FAIL — cannot find module `./tokens`.

- [ ] **Step 6: Implement tokens + globals.css**

Create `admin/lib/tokens.ts`:
```ts
export const tokens = {
  canvas: '#FAF8F4', surface: '#FFFFFF',
  ink: '#1E1A14', ink2: '#766C5C', ink3: '#A89C88',
  hairline: '#ECE4D6', hairline2: '#E2D8C6',
  accent: '#1F7D4A', accentSoft: '#E7F2EA',
  danger: '#C0392B', dangerSoft: '#FBE9E7',
  warning: '#B9772A', sand: '#F3EEE4',
} as const
export type Tokens = typeof tokens
```
Replace `admin/app/globals.css` with:
```css
@import "tailwindcss";

:root{
  --canvas:#FAF8F4; --surface:#FFFFFF; --ink:#1E1A14; --ink2:#766C5C; --ink3:#A89C88;
  --line:#ECE4D6; --line2:#E2D8C6; --accent:#1F7D4A; --accent-soft:#E7F2EA;
  --danger:#C0392B; --danger-soft:#FBE9E7; --warn:#B9772A; --sand:#F3EEE4;
}
html,body{background:var(--canvas);color:var(--ink);
  font-family:-apple-system,'SF Pro Text',system-ui,sans-serif;
  font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;}
*{box-sizing:border-box}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `cd admin && npm test -- lib/tokens.test.ts`
Expected: PASS.

- [ ] **Step 8: Verify build + commit**

Run: `cd admin && npm run build`
Expected: build succeeds.
```bash
cd /Users/akashsuryavanshi/Projects/Viele
git add admin/
git commit -m "feat(admin): scaffold Next.js app + design tokens + test tooling"
```

---

### Task 2: Supabase SSR clients + env

**Files:**
- Create: `admin/lib/supabase/client.ts`, `admin/lib/supabase/server.ts`, `admin/lib/supabase/config.ts`
- Modify: `admin/.env.local.example`
- Test: `admin/lib/supabase/config.test.ts`

**Interfaces:**
- Produces:
  - `createBrowserClient()` → Supabase client for client components.
  - `createServerClient()` → async Supabase client for server components / actions / route handlers (reads cookies via `next/headers`).
  - `config` → `{ url: string, publishableKey: string }` from env with fallbacks to the known values.

- [ ] **Step 1: Write the failing test**

Create `admin/lib/supabase/config.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { config } from './config'

describe('supabase config', () => {
  it('resolves url + publishable key', () => {
    expect(config.url).toContain('mdgublyyxcgpwvnmnlxe.supabase.co')
    expect(config.publishableKey.startsWith('sb_publishable_')).toBe(true)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin && npm test -- lib/supabase/config.test.ts`
Expected: FAIL — cannot find `./config`.

- [ ] **Step 3: Implement config + clients**

Create `admin/lib/supabase/config.ts`:
```ts
export const config = {
  url: process.env.NEXT_PUBLIC_SUPABASE_URL ?? 'https://mdgublyyxcgpwvnmnlxe.supabase.co',
  publishableKey:
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
    'sb_publishable_cK04mJ2VmBTal8fqsB-oug_uF7xckv9',
}
```
Create `admin/lib/supabase/client.ts`:
```ts
'use client'
import { createBrowserClient as create } from '@supabase/ssr'
import { config } from './config'

export function createBrowserClient() {
  return create(config.url, config.publishableKey)
}
```
Create `admin/lib/supabase/server.ts`:
```ts
import { createServerClient as create } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { config } from './config'

export async function createServerClient() {
  const cookieStore = await cookies()
  return create(config.url, config.publishableKey, {
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll: (toSet) => {
        try {
          toSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options))
        } catch { /* called from a Server Component — safe to ignore */ }
      },
    },
  })
}
```
Append to `admin/.env.local.example`:
```
NEXT_PUBLIC_SUPABASE_URL=https://mdgublyyxcgpwvnmnlxe.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_cK04mJ2VmBTal8fqsB-oug_uF7xckv9
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin && npm test -- lib/supabase/config.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add admin/lib/supabase admin/.env.local.example
git commit -m "feat(admin): supabase ssr browser + server clients"
```

---

### Task 3: Admin authorization util + middleware gate + login

**Files:**
- Create: `admin/lib/auth.ts`, `admin/middleware.ts`, `admin/app/login/page.tsx`, `admin/app/login/actions.ts`, `admin/app/unauthorized/page.tsx`
- Test: `admin/lib/auth.test.ts`

**Interfaces:**
- Consumes: `createServerClient` (Task 2).
- Produces:
  - `isAdminClaim(user: { app_metadata?: { role?: string } } | null): boolean` — pure predicate.
  - `requireAdmin(): Promise<User>` — server util; throws `redirect('/login')` if no session, `redirect('/unauthorized')` if not admin. Used at the top of every protected page/action.

- [ ] **Step 1: Write the failing test for the claim predicate**

Create `admin/lib/auth.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { isAdminClaim } from './auth'

describe('isAdminClaim', () => {
  it('true only when app_metadata.role === admin', () => {
    expect(isAdminClaim({ app_metadata: { role: 'admin' } })).toBe(true)
    expect(isAdminClaim({ app_metadata: { role: 'user' } })).toBe(false)
    expect(isAdminClaim({ app_metadata: {} })).toBe(false)
    expect(isAdminClaim(null)).toBe(false)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin && npm test -- lib/auth.test.ts`
Expected: FAIL — `isAdminClaim` not exported.

- [ ] **Step 3: Implement auth util**

Create `admin/lib/auth.ts`:
```ts
import { redirect } from 'next/navigation'
import { createServerClient } from './supabase/server'

export function isAdminClaim(
  user: { app_metadata?: { role?: string } } | null,
): boolean {
  return user?.app_metadata?.role === 'admin'
}

export async function requireAdmin() {
  const supabase = await createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')
  if (!isAdminClaim(user)) redirect('/unauthorized')
  return user
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin && npm test -- lib/auth.test.ts`
Expected: PASS.

- [ ] **Step 5: Add the middleware gate**

Create `admin/middleware.ts`:
```ts
import { NextResponse, type NextRequest } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import { config as sb } from './lib/supabase/config'
import { isAdminClaim } from './lib/auth'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createServerClient(sb.url, sb.publishableKey, {
    cookies: {
      getAll: () => req.cookies.getAll(),
      setAll: (toSet) =>
        toSet.forEach(({ name, value, options }) => res.cookies.set(name, value, options)),
    },
  })
  const { data: { user } } = await supabase.auth.getUser()
  const path = req.nextUrl.pathname
  const isPublic = path.startsWith('/login') || path.startsWith('/unauthorized')
  if (!isPublic && !isAdminClaim(user)) {
    return NextResponse.redirect(new URL(user ? '/unauthorized' : '/login', req.url))
  }
  return res
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

- [ ] **Step 6: Add login page + server action + unauthorized page**

Create `admin/app/login/actions.ts`:
```ts
'use server'
import { redirect } from 'next/navigation'
import { createServerClient } from '@/lib/supabase/server'
import { isAdminClaim } from '@/lib/auth'

export async function signIn(_prev: string | null, formData: FormData) {
  const email = String(formData.get('email') ?? '')
  const password = String(formData.get('password') ?? '')
  const supabase = await createServerClient()
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) return 'Wrong email or password.'
  if (!isAdminClaim(data.user)) {
    await supabase.auth.signOut()
    return 'This account is not an admin.'
  }
  redirect('/moderation')
}
```
Create `admin/app/login/page.tsx`:
```tsx
'use client'
import { useActionState } from 'react'
import { signIn } from './actions'

export default function LoginPage() {
  const [error, action, pending] = useActionState(signIn, null)
  return (
    <main style={{ minHeight: '100vh', display: 'grid', placeItems: 'center' }}>
      <form action={action} style={{ width: 320, display: 'grid', gap: 12 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700 }}>Viele Admin</h1>
        <input name="email" type="email" placeholder="Email" required
          style={{ padding: 10, border: '1px solid var(--line2)', borderRadius: 9 }} />
        <input name="password" type="password" placeholder="Password" required
          style={{ padding: 10, border: '1px solid var(--line2)', borderRadius: 9 }} />
        <button disabled={pending}
          style={{ padding: 10, background: 'var(--ink)', color: '#F6F1E8', borderRadius: 9, fontWeight: 700 }}>
          {pending ? 'Signing in…' : 'Sign in'}
        </button>
        {error && <p style={{ color: 'var(--danger)', fontSize: 13 }}>{error}</p>}
      </form>
    </main>
  )
}
```
Create `admin/app/unauthorized/page.tsx`:
```tsx
export default function Unauthorized() {
  return (
    <main style={{ minHeight: '100vh', display: 'grid', placeItems: 'center' }}>
      <p style={{ color: 'var(--ink2)' }}>You don’t have admin access to this console.</p>
    </main>
  )
}
```

- [ ] **Step 7: Verify build + commit**

Run: `cd admin && npm run build`
Expected: build succeeds (routes compile).
```bash
git add admin/lib/auth.ts admin/lib/auth.test.ts admin/middleware.ts admin/app/login admin/app/unauthorized
git commit -m "feat(admin): admin auth gate (middleware + requireAdmin) + login"
```

---

### Task 4: App shell (sidebar + layout) + core UI components

**Files:**
- Create: `admin/components/Sidebar.tsx`, `admin/components/PageHeader.tsx`, `admin/components/ui/StatusPill.tsx`, `admin/components/ui/ReasonChip.tsx`, `admin/components/ui/ActionButton.tsx`, `admin/app/(console)/layout.tsx`
- Test: `admin/components/ui/StatusPill.test.tsx`, `admin/components/ui/ReasonChip.test.tsx`

**Interfaces:**
- Consumes: `requireAdmin` (Task 3).
- Produces:
  - `<Sidebar active="moderation" />` — nav (Overview, Moderation, Users, Posts, Content & seed, Audit) with the active item highlighted in accent.
  - `<PageHeader title subtitle />`.
  - `<StatusPill kind="open"|"auto"|"active" label />`.
  - `<ReasonChip reason: string />` — red for severe (`sexual|violence|illegal|harassment`), sand for mild.
  - `<ActionButton variant="default"|"danger"|"ghost" onClick>` (client component).
  - `(console)/layout.tsx` — calls `requireAdmin()`, renders Sidebar + content grid.

- [ ] **Step 1: Write failing tests for StatusPill + ReasonChip**

Create `admin/components/ui/StatusPill.test.tsx`:
```tsx
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { StatusPill } from './StatusPill'

describe('StatusPill', () => {
  it('renders the label', () => {
    render(<StatusPill kind="open" label="Open" />)
    expect(screen.getByText('Open')).toBeInTheDocument()
  })
})
```
Create `admin/components/ui/ReasonChip.test.tsx`:
```tsx
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { ReasonChip } from './ReasonChip'

describe('ReasonChip', () => {
  it('marks severe reasons as danger', () => {
    const { container } = render(<ReasonChip reason="sexual" />)
    expect(screen.getByText('sexual')).toBeInTheDocument()
    expect(container.firstChild).toHaveAttribute('data-severe', 'true')
  })
  it('marks other reasons as mild', () => {
    const { container } = render(<ReasonChip reason="other" />)
    expect(container.firstChild).toHaveAttribute('data-severe', 'false')
  })
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd admin && npm test -- components/ui`
Expected: FAIL — components not found.

- [ ] **Step 3: Implement the UI components**

Create `admin/components/ui/StatusPill.tsx`:
```tsx
const COLORS = {
  open: { fg: 'var(--warn)', dot: 'var(--warn)' },
  auto: { fg: 'var(--danger)', dot: 'var(--danger)' },
  active: { fg: 'var(--accent)', dot: 'var(--accent)' },
} as const

export function StatusPill({ kind, label }: { kind: keyof typeof COLORS; label: string }) {
  const c = COLORS[kind]
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontWeight: 700, fontSize: 12.5, color: c.fg }}>
      <span style={{ width: 7, height: 7, borderRadius: '50%', background: c.dot }} />
      {label}
    </span>
  )
}
```
Create `admin/components/ui/ReasonChip.tsx`:
```tsx
const SEVERE = new Set(['sexual', 'violence', 'illegal', 'harassment'])
export function ReasonChip({ reason }: { reason: string }) {
  const severe = SEVERE.has(reason)
  return (
    <span data-severe={severe} style={{
      fontSize: 11, fontWeight: 650, padding: '2px 8px', borderRadius: 20,
      background: severe ? 'var(--danger-soft)' : 'var(--sand)',
      color: severe ? 'var(--danger)' : 'var(--ink2)',
    }}>{reason}</span>
  )
}
```
Create `admin/components/ui/ActionButton.tsx`:
```tsx
'use client'
const V = {
  default: { bg: 'var(--surface)', fg: 'var(--ink)', bd: 'var(--line2)' },
  danger: { bg: 'var(--danger)', fg: '#fff', bd: 'var(--danger)' },
  ghost: { bg: 'transparent', fg: 'var(--ink2)', bd: 'var(--line2)' },
} as const
export function ActionButton(
  { variant = 'default', children, onClick, disabled }:
  { variant?: keyof typeof V; children: React.ReactNode; onClick?: () => void; disabled?: boolean },
) {
  const c = V[variant]
  return (
    <button onClick={onClick} disabled={disabled} style={{
      fontSize: 12, fontWeight: 700, padding: '6px 12px', borderRadius: 8,
      border: `1px solid ${c.bd}`, background: c.bg, color: c.fg,
      cursor: disabled ? 'default' : 'pointer', opacity: disabled ? 0.6 : 1,
    }}>{children}</button>
  )
}
```
Create `admin/components/Sidebar.tsx`:
```tsx
import Link from 'next/link'

const ITEMS = [
  { href: '/overview', label: 'Overview' },
  { href: '/moderation', label: 'Moderation' },
  { href: '/users', label: 'Users' },
  { href: '/posts', label: 'Posts' },
  { href: '/content', label: 'Content & seed' },
  { href: '/audit', label: 'Audit log' },
]

export function Sidebar({ active }: { active: string }) {
  return (
    <aside style={{ background: 'var(--surface)', borderRight: '1px solid var(--line)', padding: '18px 14px' }}>
      <div style={{ display: 'flex', gap: 9, alignItems: 'center', padding: '6px 8px 16px' }}>
        <span style={{ width: 26, height: 26, borderRadius: 8, background: 'var(--ink)', color: '#F6F1E8', display: 'grid', placeItems: 'center', fontWeight: 800 }}>V</span>
        <b style={{ fontSize: 16 }}>Viele Admin</b>
      </div>
      <nav style={{ display: 'grid', gap: 4 }}>
        {ITEMS.map((i) => {
          const on = i.href === `/${active}`
          return (
            <Link key={i.href} href={i.href} style={{
              padding: '8px 9px', borderRadius: 8, textDecoration: 'none', fontWeight: on ? 700 : 550,
              background: on ? 'var(--accent-soft)' : 'transparent',
              color: on ? 'var(--accent)' : 'var(--ink2)',
            }}>{i.label}</Link>
          )
        })}
      </nav>
    </aside>
  )
}
```
Create `admin/components/PageHeader.tsx`:
```tsx
export function PageHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <h1 style={{ fontSize: 22, margin: 0, letterSpacing: '-0.3px' }}>{title}</h1>
      {subtitle && <div style={{ color: 'var(--ink2)', fontSize: 12.5, marginTop: 2 }}>{subtitle}</div>}
    </div>
  )
}
```
Create `admin/app/(console)/layout.tsx`:
```tsx
import { requireAdmin } from '@/lib/auth'
import { Sidebar } from '@/components/Sidebar'

export default async function ConsoleLayout({ children }: { children: React.ReactNode }) {
  await requireAdmin()
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '224px 1fr', minHeight: '100vh' }}>
      {/* Sidebar active state is set per-page via the URL; default highlight handled client-side later. */}
      <Sidebar active="moderation" />
      <main style={{ padding: '22px 28px 40px', overflow: 'auto' }}>{children}</main>
    </div>
  )
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd admin && npm test -- components/ui`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add admin/components admin/app/\(console\)
git commit -m "feat(admin): app shell (sidebar, header) + core UI components"
```

---

### Task 5: Moderation data layer (RPC wrappers + actions)

**Files:**
- Create: `admin/lib/moderation.ts`, `admin/app/(console)/moderation/actions.ts`
- Test: `admin/lib/moderation.test.ts`

**Interfaces:**
- Consumes: `createServerClient` (Task 2), `requireAdmin` (Task 3).
- Produces:
  - Type `QueueRow = { target_type: 'post'|'user'; target_id: string; display: string; post_status: string|null; reasons: string[]; reporters: number; last_report: string }`.
  - `fetchQueue(): Promise<QueueRow[]>` — server fn calling `moderation_queue()` RPC, mapping `reasons` jsonb → `string[]`.
  - `normalizeReasons(raw: unknown): string[]` — pure helper (jsonb array or null → string[]).
  - Server actions `removePost(postId)`, `dismissPost(postId)`, `restorePost(postId)` — each `requireAdmin()` then `rpc('moderate_post', { p_post_id, p_action })` and `revalidatePath('/moderation')`.

- [ ] **Step 1: Write the failing test for normalizeReasons**

Create `admin/lib/moderation.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { normalizeReasons } from './moderation'

describe('normalizeReasons', () => {
  it('handles a jsonb string array', () => {
    expect(normalizeReasons(['sexual', 'spam'])).toEqual(['sexual', 'spam'])
  })
  it('handles null / non-array', () => {
    expect(normalizeReasons(null)).toEqual([])
    expect(normalizeReasons('nope')).toEqual([])
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin && npm test -- lib/moderation.test.ts`
Expected: FAIL — `normalizeReasons` not exported.

- [ ] **Step 3: Implement the data layer + actions**

Create `admin/lib/moderation.ts`:
```ts
import { createServerClient } from './supabase/server'

export type QueueRow = {
  target_type: 'post' | 'user'
  target_id: string
  display: string
  post_status: string | null
  reasons: string[]
  reporters: number
  last_report: string
}

export function normalizeReasons(raw: unknown): string[] {
  return Array.isArray(raw) ? raw.filter((r): r is string => typeof r === 'string') : []
}

export async function fetchQueue(): Promise<QueueRow[]> {
  const supabase = await createServerClient()
  const { data, error } = await supabase.rpc('moderation_queue')
  if (error) throw new Error(error.message)
  return (data ?? []).map((r: Record<string, unknown>) => ({
    target_type: r.target_type as 'post' | 'user',
    target_id: r.target_id as string,
    display: (r.display as string) ?? '',
    post_status: (r.post_status as string | null) ?? null,
    reasons: normalizeReasons(r.reasons),
    reporters: Number(r.reporters ?? 0),
    last_report: (r.last_report as string) ?? '',
  }))
}
```
Create `admin/app/(console)/moderation/actions.ts`:
```ts
'use server'
import { revalidatePath } from 'next/cache'
import { createServerClient } from '@/lib/supabase/server'
import { requireAdmin } from '@/lib/auth'

async function moderate(postId: string, action: 'remove' | 'dismiss' | 'restore') {
  await requireAdmin()
  const supabase = await createServerClient()
  const { error } = await supabase.rpc('moderate_post', { p_post_id: postId, p_action: action })
  if (error) throw new Error(error.message)
  revalidatePath('/moderation')
}

export const removePost = (postId: string) => moderate(postId, 'remove')
export const dismissPost = (postId: string) => moderate(postId, 'dismiss')
export const restorePost = (postId: string) => moderate(postId, 'restore')
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin && npm test -- lib/moderation.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add admin/lib/moderation.ts admin/lib/moderation.test.ts "admin/app/(console)/moderation/actions.ts"
git commit -m "feat(admin): moderation data layer (queue fetch + moderate actions)"
```

---

### Task 6: Moderation queue screen

**Files:**
- Create: `admin/app/(console)/moderation/page.tsx`, `admin/app/(console)/moderation/QueueTable.tsx`
- Test: `admin/app/(console)/moderation/QueueTable.test.tsx`

**Interfaces:**
- Consumes: `fetchQueue`, `QueueRow` (Task 5); `removePost`/`dismissPost`/`restorePost` (Task 5); `StatusPill`, `ReasonChip`, `ActionButton`, `PageHeader` (Task 4).
- Produces: server `page.tsx` (calls `fetchQueue`) + client `QueueTable` (renders rows, wires actions with optimistic pending state).

- [ ] **Step 1: Write the failing test for QueueTable rendering**

Create `admin/app/(console)/moderation/QueueTable.test.tsx`:
```tsx
import { render, screen } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { QueueTable } from './QueueTable'
import type { QueueRow } from '@/lib/moderation'

const rows: QueueRow[] = [
  { target_type: 'post', target_id: 'p1', display: 'Cream knit', post_status: 'removed',
    reasons: ['sexual'], reporters: 3, last_report: '2026-06-21T00:00:00Z' },
  { target_type: 'user', target_id: 'u1', display: 'Jules', post_status: null,
    reasons: ['spam'], reporters: 2, last_report: '2026-06-21T00:00:00Z' },
]

describe('QueueTable', () => {
  it('renders a row per report and an empty state', () => {
    const actions = { removePost: vi.fn(), dismissPost: vi.fn(), restorePost: vi.fn() }
    render(<QueueTable rows={rows} actions={actions} />)
    expect(screen.getByText('Cream knit')).toBeInTheDocument()
    expect(screen.getByText('Jules')).toBeInTheDocument()
    expect(screen.getByText('sexual')).toBeInTheDocument()
  })
  it('shows empty state with no rows', () => {
    const actions = { removePost: vi.fn(), dismissPost: vi.fn(), restorePost: vi.fn() }
    render(<QueueTable rows={[]} actions={actions} />)
    expect(screen.getByText(/no open reports/i)).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin && npm test -- "app/(console)/moderation/QueueTable.test.tsx"`
Expected: FAIL — `QueueTable` not found.

- [ ] **Step 3: Implement QueueTable (client)**

Create `admin/app/(console)/moderation/QueueTable.tsx`:
```tsx
'use client'
import { useTransition } from 'react'
import type { QueueRow } from '@/lib/moderation'
import { StatusPill } from '@/components/ui/StatusPill'
import { ReasonChip } from '@/components/ui/ReasonChip'
import { ActionButton } from '@/components/ui/ActionButton'

type Actions = {
  removePost: (id: string) => Promise<void>
  dismissPost: (id: string) => Promise<void>
  restorePost: (id: string) => Promise<void>
}

export function QueueTable({ rows, actions }: { rows: QueueRow[]; actions: Actions }) {
  const [pending, start] = useTransition()
  if (rows.length === 0) {
    return <p style={{ color: 'var(--ink3)', padding: 40, textAlign: 'center' }}>No open reports 🎉</p>
  }
  return (
    <div style={{ background: 'var(--surface)', border: '1px solid var(--line)', borderRadius: 10, overflow: 'hidden' }}>
      {rows.map((r) => {
        const removed = r.post_status === 'removed'
        return (
          <div key={`${r.target_type}:${r.target_id}`} style={{
            display: 'grid', gridTemplateColumns: '1.7fr 1.5fr .7fr .9fr auto', gap: 14,
            alignItems: 'center', padding: '13px 16px', borderBottom: '1px solid var(--line)',
          }}>
            <div>
              <span style={{ fontWeight: 650 }}>{r.display}</span>
              <span style={{ fontSize: 10, fontWeight: 800, textTransform: 'uppercase',
                marginLeft: 6, padding: '1px 6px', borderRadius: 5, background: 'var(--sand)', color: 'var(--ink2)' }}>
                {r.target_type}
              </span>
            </div>
            <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
              {r.reasons.map((x) => <ReasonChip key={x} reason={x} />)}
            </div>
            <div style={{ fontWeight: 700 }}>{r.reporters}</div>
            <div>
              <StatusPill kind={removed ? 'auto' : 'open'} label={removed ? 'Removed' : 'Open'} />
            </div>
            <div style={{ display: 'flex', gap: 7 }}>
              {r.target_type === 'post' && !removed && (
                <ActionButton variant="danger" disabled={pending}
                  onClick={() => start(() => { void actions.removePost(r.target_id) })}>Remove</ActionButton>
              )}
              {r.target_type === 'post' && removed && (
                <ActionButton disabled={pending}
                  onClick={() => start(() => { void actions.restorePost(r.target_id) })}>Restore</ActionButton>
              )}
              {r.target_type === 'post' && (
                <ActionButton variant="ghost" disabled={pending}
                  onClick={() => start(() => { void actions.dismissPost(r.target_id) })}>Dismiss</ActionButton>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin && npm test -- "app/(console)/moderation/QueueTable.test.tsx"`
Expected: PASS.

- [ ] **Step 5: Implement the server page**

Create `admin/app/(console)/moderation/page.tsx`:
```tsx
import { fetchQueue } from '@/lib/moderation'
import { PageHeader } from '@/components/PageHeader'
import { QueueTable } from './QueueTable'
import { removePost, dismissPost, restorePost } from './actions'

export const dynamic = 'force-dynamic'

export default async function ModerationPage() {
  const rows = await fetchQueue()
  return (
    <>
      <PageHeader title="Moderation" subtitle="Open reports across posts and users · auto-takedown active" />
      <QueueTable rows={rows} actions={{ removePost, dismissPost, restorePost }} />
    </>
  )
}
```

- [ ] **Step 6: Full test + build + commit**

Run: `cd admin && npm test && npm run build`
Expected: all tests PASS, build succeeds.
```bash
git add "admin/app/(console)/moderation"
git commit -m "feat(admin): moderation queue screen wired to moderate_post"
```

---

### Task 7: Deploy to Vercel + live smoke test

**Files:**
- Create: `admin/README.md` (run + deploy notes)

**Interfaces:**
- Consumes: the whole app.

- [ ] **Step 1: Local run against live Supabase**

Run: `cd admin && cp .env.local.example .env.local && npm run dev`
Open `http://localhost:3000` → redirected to `/login`.

- [ ] **Step 2: Create a throwaway admin to verify the gate**

Create a test user (REST signup) and flag admin via SQL (Supabase MCP `execute_sql` on `mdgublyyxcgpwvnmnlxe`):
```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
where email = '<throwaway-admin-email>';
```
Sign in at `/login`. Expected: redirected to `/moderation`, queue renders (empty or with seeded reports). Sign in with a NON-admin → `/unauthorized`. Delete the throwaway after via the `delete-account` flow / SQL.

- [ ] **Step 3: Write README**

Create `admin/README.md` with: prerequisites (Node ≥20), `npm install`, `.env.local` keys, `npm run dev`, `npm test`, `npm run build`, and "deploy: import `admin/` as a Vercel project, set `NEXT_PUBLIC_SUPABASE_URL` + `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` env vars."

- [ ] **Step 4: Deploy to Vercel**

Run (from `admin/`): `npx --yes vercel@latest --prod` (or import via the Vercel dashboard). Set the two `NEXT_PUBLIC_*` env vars in the Vercel project. Confirm the deployed URL gates non-admins and serves the moderation queue for an admin.

- [ ] **Step 5: Commit**

```bash
git add admin/README.md
git commit -m "docs(admin): run + deploy notes; foundation+moderation slice complete"
```

---

## Follow-on plans (separate cycles, after this lands)

1. **Users + suspension** — suspension migration (`suspended_at`/`banned_at` + RLS predicate extensions to `profiles_select`/`posts_select`/`feed()`/`recommend_people()`) + `admin-suspend-user` edge function; Users browser + suspend/ban actions.
2. **Posts browser** — list/filter all posts, force remove/restore, jump to author.
3. **Analytics + Overview** — `admin_overview()` + `admin_timeseries()` RPCs; KPI cards + trend charts.
4. **Content & seed + Audit log** — seed teardown (typed confirm) + `admin_actions` read.

## Self-review notes

- **Spec coverage:** This plan covers spec §3 (architecture), §4 (auth), §5 screen #1 (login) + #3 (moderation), §7 (design tokens/components), §8 (security), §9 build steps 1–2 + deploy. Screens #2 (overview), #4 (users), #5 (posts), #6 (content/seed), #7 (audit) and §6 backend additions are explicitly deferred to the four follow-on plans above — each its own shippable cycle.
- **Type consistency:** `QueueRow`, `normalizeReasons`, `fetchQueue`, `isAdminClaim`, `requireAdmin`, action names (`removePost`/`dismissPost`/`restorePost`) are defined once and reused with identical signatures across Tasks 5–6.
- **No placeholders:** every code step contains real code; the only `<...>` tokens are the throwaway-admin email in Task 7 (operator-supplied) and the Vercel env values (from Global Constraints).
