import { describe, it, expect } from 'vitest'
import { tokens } from './tokens'

describe('design tokens', () => {
  it('exposes the Viele-tinted palette verbatim', () => {
    expect(tokens.accent).toBe('#1F7D4A')
    expect(tokens.ink).toBe('#1E1A14')
    expect(tokens.danger).toBe('#C0392B')
    expect(tokens.canvas).toBe('#FAF8F4')
  })
})
