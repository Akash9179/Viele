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
