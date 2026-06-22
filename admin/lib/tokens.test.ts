import { describe, it, expect } from 'vitest'
import { tokens } from './tokens'

describe('design tokens', () => {
  it('exposes the Viele-tinted palette verbatim', () => {
    expect(tokens.accent).toBe('#1F7D4A')
    expect(tokens.ink).toBe('#1E1A14')
    expect(tokens.danger).toBe('#C0392B')
    expect(tokens.canvas).toBe('#FAF8F4')
  })

  it('has all 13 tokens with the exact palette', () => {
    expect(tokens).toEqual({
      canvas: '#FAF8F4', surface: '#FFFFFF',
      ink: '#1E1A14', ink2: '#766C5C', ink3: '#A89C88',
      hairline: '#ECE4D6', hairline2: '#E2D8C6',
      accent: '#1F7D4A', accentSoft: '#E7F2EA',
      danger: '#C0392B', dangerSoft: '#FBE9E7',
      warning: '#B9772A', sand: '#F3EEE4',
    })
  })
})
