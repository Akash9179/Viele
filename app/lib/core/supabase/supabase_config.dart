/// Supabase connection config for the **viele** project (ref
/// `mdgublyyxcgpwvnmnlxe`) — the dedicated, isolated project. NEVER point this
/// at any other project.
///
/// These are CLIENT keys and are safe to ship in the app bundle: the URL and
/// the **publishable** key carry no privileges beyond what RLS allows. Secret /
/// service_role keys must NEVER appear here — they live server-side only (Edge
/// Functions). See CLAUDE.md key-hygiene rules.
abstract final class SupabaseConfig {
  static const url = 'https://mdgublyyxcgpwvnmnlxe.supabase.co';
  static const publishableKey = 'sb_publishable_cK04mJ2VmBTal8fqsB-oug_uF7xckv9';
}
