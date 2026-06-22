import { describe, it, expect } from 'vitest'
import { normalizeReasons } from './moderation'

describe('normalizeReasons', () => {
  it('handles a jsonb string array', () => {
    expect(normalizeReasons(['sexual', 'spam'])).toEqual(['sexual', 'spam'])
  })
  it('handles null / non-array', () => {
    expect(normalizeReasons(null)).toEqual([])
    expect(normalizeReasons('nope')).toEqual([])
  })
})
