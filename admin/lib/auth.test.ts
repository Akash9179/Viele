import { describe, it, expect } from 'vitest'
import { isAdminClaim } from './auth'

describe('isAdminClaim', () => {
  it('true only when app_metadata.role === admin', () => {
    expect(isAdminClaim({ app_metadata: { role: 'admin' } })).toBe(true)
    expect(isAdminClaim({ app_metadata: { role: 'user' } })).toBe(false)
    expect(isAdminClaim({ app_metadata: {} })).toBe(false)
    expect(isAdminClaim(null)).toBe(false)
  })

  it('ignores user_metadata.role — only app_metadata grants admin', () => {
    const u = { user_metadata: { role: 'admin' }, app_metadata: {} }
    expect(isAdminClaim(u)).toBe(false)
  })
})
