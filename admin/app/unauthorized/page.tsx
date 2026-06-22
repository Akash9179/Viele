export default function Unauthorized() {
  return (
    <main style={{ minHeight: '100vh', display: 'grid', placeItems: 'center' }}>
      <p style={{ color: 'var(--ink2)' }}>You don't have admin access to this console.</p>
    </main>
  )
}
