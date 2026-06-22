import { createServerClient } from './supabase/server'

export type QueueRow = {
  target_type: 'post' | 'user'
  target_id: string
  display: string
  post_status: string | null
  reasons: string[]
  reporters: number
  last_report: string
}

export function normalizeReasons(raw: unknown): string[] {
  return Array.isArray(raw) ? raw.filter((r): r is string => typeof r === 'string') : []
}

export async function fetchQueue(): Promise<QueueRow[]> {
  const supabase = await createServerClient()
  const { data, error } = await supabase.rpc('moderation_queue')
  if (error) throw new Error(error.message)
  return (data ?? []).map((r: Record<string, unknown>) => ({
    target_type: r.target_type as 'post' | 'user',
    target_id: r.target_id as string,
    display: (r.display as string) ?? '',
    post_status: (r.post_status as string | null) ?? null,
    reasons: normalizeReasons(r.reasons),
    reporters: Number(r.reporters ?? 0),
    last_report: (r.last_report as string) ?? '',
  }))
}
