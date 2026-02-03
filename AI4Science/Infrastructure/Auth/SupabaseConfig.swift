import Foundation

/// Supabase project credentials. The anon key is intentionally public-facing;
/// Row-Level Security on the Supabase side enforces access control.
/// Replace placeholder values with real values from the Supabase dashboard.
nonisolated struct SupabaseConfig: Sendable {
    let projectURL: URL
    let anonKey: String

    static let current = SupabaseConfig(
        projectURL: URL(string: "https://project-id.supabase.co")!,
        anonKey: "anon-key"
    )
}
