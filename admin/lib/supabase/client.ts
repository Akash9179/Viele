'use client'
import { createBrowserClient as create } from '@supabase/ssr'
import { config } from './config'

export function createBrowserClient() {
  return create(config.url, config.publishableKey)
}
