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
