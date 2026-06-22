'use server'
import { revalidatePath } from 'next/cache'
import { createServerClient } from '@/lib/supabase/server'
import { requireAdmin } from '@/lib/auth'

async function moderate(postId: string, action: 'remove' | 'dismiss' | 'restore') {
  await requireAdmin()
  const supabase = await createServerClient()
  const { error } = await supabase.rpc('moderate_post', { p_post_id: postId, p_action: action })
  if (error) throw new Error(error.message)
  revalidatePath('/moderation')
}

export const removePost = (postId: string) => moderate(postId, 'remove')
export const dismissPost = (postId: string) => moderate(postId, 'dismiss')
export const restorePost = (postId: string) => moderate(postId, 'restore')
