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
