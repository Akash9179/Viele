import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { ReasonChip } from './ReasonChip'

describe('ReasonChip', () => {
  it('marks severe reasons as danger', () => {
    const { container } = render(<ReasonChip reason="sexual" />)
    expect(screen.getByText('sexual')).toBeInTheDocument()
    expect(container.firstChild).toHaveAttribute('data-severe', 'true')
  })
  it('marks other reasons as mild', () => {
    const { container } = render(<ReasonChip reason="other" />)
    expect(container.firstChild).toHaveAttribute('data-severe', 'false')
  })
})
