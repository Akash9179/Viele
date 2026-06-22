import { NextResponse, type NextRequest } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import { config as sb } from './lib/supabase/config'
import { isAdminClaim } from './lib/auth'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createServerClient(sb.url, sb.publishableKey, {
    cookies: {
      getAll: () => req.cookies.getAll(),
      setAll: (toSet) =>
        toSet.forEach(({ name, value, options }) => res.cookies.set(name, value, options)),
    },
  })
  const { data: { user } } = await supabase.auth.getUser()
  const path = req.nextUrl.pathname
  const isPublic = path.startsWith('/login') || path.startsWith('/unauthorized')
  if (!isPublic && !isAdminClaim(user)) {
    return NextResponse.redirect(new URL(user ? '/unauthorized' : '/login', req.url))
  }
  return res
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
