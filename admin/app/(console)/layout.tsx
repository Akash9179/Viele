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
