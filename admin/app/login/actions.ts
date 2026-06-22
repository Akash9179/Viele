'use server'
import { redirect } from 'next/navigation'
import { createServerClient } from '@/lib/supabase/server'
import { isAdminClaim } from '@/lib/auth'

export async function signIn(_prev: string | null, formData: FormData) {
  const email = String(formData.get('email') ?? '')
  const password = String(formData.get('password') ?? '')
  const supabase = await createServerClient()
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) return 'Wrong email or password.'
  if (!isAdminClaim(data.user)) {
    await supabase.auth.signOut()
    return 'This account is not an admin.'
  }
  redirect('/moderation')
}
