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
