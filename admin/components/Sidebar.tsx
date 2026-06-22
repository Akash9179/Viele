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
