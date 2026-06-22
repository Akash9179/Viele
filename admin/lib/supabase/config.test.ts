import { describe, it, expect } from 'vitest'
import { config } from './config'

describe('supabase config', () => {
  it('resolves url + publishable key', () => {
    expect(config.url).toContain('mdgublyyxcgpwvnmnlxe.supabase.co')
    expect(config.publishableKey.startsWith('sb_publishable_')).toBe(true)
  })
})
