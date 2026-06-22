import { createServerClient as create } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { config } from './config'

export async function createServerClient() {
  const cookieStore = await cookies()
  return create(config.url, config.publishableKey, {
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll: (toSet) => {
        try {
          toSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options))
        } catch { /* called from a Server Component — safe to ignore */ }
      },
    },
  })
}
