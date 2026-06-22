import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { StatusPill } from './StatusPill'

describe('StatusPill', () => {
  it('renders the label', () => {
    render(<StatusPill kind="open" label="Open" />)
    expect(screen.getByText('Open')).toBeInTheDocument()
  })
})
