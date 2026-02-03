//
//  SupabaseConfig.swift
//  AI4Science
//
//  Supabase client initialization and configuration
//

import Foundation
import Supabase

/// Singleton managing Supabase client
/// Thread-safe via immutable client after initialization
final class SupabaseConfig {
    static let shared = SupabaseConfig()

    // Immutable after init - safe for concurrent access
    let client: SupabaseClient

    // MARK: - Initialization

    private init() {
        // Read configuration from Info.plist
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("Supabase configuration missing from Info.plist. Please add SUPABASE_URL and SUPABASE_ANON_KEY.")
        }

        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid SUPABASE_URL in Info.plist: \(supabaseURL)")
        }

        // Initialize Supabase client (immutable after this)
        // Note: Supabase SDK handles session persistence and auto-refresh by default
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )

        AppLogger.info("Supabase client initialized successfully")
    }
}
