export function PageHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <h1 style={{ fontSize: 22, margin: 0, letterSpacing: '-0.3px' }}>{title}</h1>
      {subtitle && <div style={{ color: 'var(--ink2)', fontSize: 12.5, marginTop: 2 }}>{subtitle}</div>}
    </div>
  )
}
