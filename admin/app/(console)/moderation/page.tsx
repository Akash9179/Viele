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
