import { redirect } from 'next/navigation'
import { createServerClient } from './supabase/server'

export function isAdminClaim(
  user: { app_metadata?: Record<string, unknown> } | null,
): boolean {
  return user?.app_metadata?.['role'] === 'admin'
}

export async function requireAdmin() {
  const supabase = await createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')
  if (!isAdminClaim(user)) redirect('/unauthorized')
  return user
}
