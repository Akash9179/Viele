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
