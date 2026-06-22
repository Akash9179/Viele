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
