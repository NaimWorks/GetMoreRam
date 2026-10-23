//
//  AuthenticationSettings.swift
//  GetMoreRam
//
//  Anisette server list and authentication headers (Client-Info / User-Agent),
//  all editable from Settings.
//

import Foundation
import SwiftUI

struct AnisetteServer: Codable, Hashable, Identifiable {
    var name: String
    var address: String
    /// true when the entry comes from the remote JSON list rather than being added by hand
    var isRemote: Bool = false

    var id: String { address }
}

struct HeaderPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let clientInfo: String
    let userAgent: String

    static let windowsITunes = HeaderPreset(
        id: "windows-itunes",
        name: "Windows / iTunes (SideStore fix)",
        clientInfo: "<PC> <Windows;6.2(0,0);9200> <com.apple.AuthKit/1 (com.apple.iTunes/12.12.4.1)>",
        userAgent: "akd/1.0 CFNetwork/808.1.4"
    )
    static let macAkd = HeaderPreset(
        id: "mac-akd",
        name: "macOS akd (previous GetMoreRam)",
        clientInfo: "<iMac18,3> <macOS;27.0;26A5378j> <com.apple.AuthKit/1 (com.apple.akd/1.0)>",
        userAgent: "AuthKit/1 (Macintosh; OS X 27.0) (com.apple.akd/1.0)"
    )
    static let macXcode = HeaderPreset(
        id: "mac-xcode",
        name: "macOS Xcode (StosSign default)",
        clientInfo: "<iMac18,3> <macOS;27.0;26A5378j> <com.apple.AuthKit/1 (com.apple.dt.Xcode/25183.54.10)>",
        userAgent: "AuthKit/1 (Macintosh; OS X 26.6) (com.apple.dt.Xcode/26.0)"
    )

    static let all: [HeaderPreset] = [.windowsITunes, .macAkd, .macXcode]
}

final class AuthenticationSettings: ObservableObject {
    static let shared = AuthenticationSettings()

    static let defaultServers: [AnisetteServer] = [
        AnisetteServer(name: "jkcoxson (mac)", address: "https://mac-ani.jkcoxson.com"),
        AnisetteServer(name: "jkcoxson", address: "https://ani.jkcoxson.com"),
        AnisetteServer(name: "StikStore", address: "https://ani2.stikstore.app"),
        AnisetteServer(name: "SideStore", address: "https://ani.sidestore.io"),
    ]
    static let defaultServerListURL = "https://servers.sidestore.io/servers.json"

    private let defaults = UserDefaults.standard

    @Published var servers: [AnisetteServer] { didSet { saveServers() } }
    /// Address of the server used for sign-in. Kept under the original "AnisetteServer" key.
    @Published var selectedServerAddress: String { didSet { defaults.set(selectedServerAddress, forKey: "AnisetteServer") } }
    @Published var serverListURL: String { didSet { defaults.set(serverListURL, forKey: "AnisetteServerListURL") } }
    /// When the selected server fails, try the other servers of the list in order.
    @Published var fallbackToOtherServers: Bool { didSet { defaults.set(fallbackToOtherServers, forKey: "AnisetteFallback") } }

    /// Ask the anisette server for its own client info (/v3/client_info) instead of the values below.
    @Published var useServerClientInfo: Bool { didSet { defaults.set(useServerClientInfo, forKey: "UseServerClientInfo") } }
    @Published var clientInfo: String { didSet { defaults.set(clientInfo, forKey: "AuthClientInfo") } }
    @Published var userAgent: String { didSet { defaults.set(userAgent, forKey: "AuthUserAgent") } }

    private init() {
        var servers = Self.defaultServers
        if let data = defaults.data(forKey: "AnisetteServers"),
           let saved = try? JSONDecoder().decode([AnisetteServer].self, from: data),
           !saved.isEmpty {
            servers = saved
        }

        let selected = defaults.string(forKey: "AnisetteServer") ?? Self.defaultServers[0].address
        if !servers.contains(where: { $0.address == selected }) {
            // Keep the URL typed in older versions of the app
            servers.insert(AnisetteServer(name: "Custom", address: selected), at: 0)
        }

        self.servers = servers
        self.selectedServerAddress = selected
        self.serverListURL = defaults.string(forKey: "AnisetteServerListURL") ?? Self.defaultServerListURL
        self.fallbackToOtherServers = defaults.object(forKey: "AnisetteFallback") as? Bool ?? true
        self.useServerClientInfo = defaults.bool(forKey: "UseServerClientInfo")
        self.clientInfo = defaults.string(forKey: "AuthClientInfo") ?? HeaderPreset.windowsITunes.clientInfo
        self.userAgent = defaults.string(forKey: "AuthUserAgent") ?? HeaderPreset.windowsITunes.userAgent
    }

    private func saveServers() {
        if let data = try? JSONEncoder().encode(servers) {
            defaults.set(data, forKey: "AnisetteServers")
        }
    }

    var selectedServer: AnisetteServer? {
        servers.first { $0.address == selectedServerAddress }
    }

    /// Selected server first, then (if fallback is enabled) every other server.
    var serversToTry: [AnisetteServer] {
        let selected = selectedServer.map { [$0] } ?? []
        guard fallbackToOtherServers else { return selected }
        return selected + servers.filter { $0.address != selectedServerAddress }
    }

    var currentPresetID: String? {
        HeaderPreset.all.first { $0.clientInfo == clientInfo && $0.userAgent == userAgent }?.id
    }

    func apply(_ preset: HeaderPreset) {
        clientInfo = preset.clientInfo
        userAgent = preset.userAgent
    }

    // MARK: - Editing the list

    static func normalizedAddress(_ raw: String) -> String? {
        var address = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return nil }
        if !address.contains("://") {
            address = "https://" + address
        }
        while address.hasSuffix("/") {
            address.removeLast()
        }
        guard let url = URL(string: address), url.host != nil,
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return address
    }

    @discardableResult
    func addServer(name: String, address rawAddress: String) throws -> AnisetteServer {
        guard let address = Self.normalizedAddress(rawAddress) else {
            throw "Invalid server URL: \(rawAddress)"
        }
        if let existing = servers.first(where: { $0.address == address }) {
            return existing
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let server = AnisetteServer(name: trimmedName.isEmpty ? (URL(string: address)?.host ?? address) : trimmedName,
                                    address: address)
        servers.append(server)
        return server
    }

    func removeServers(at offsets: IndexSet) {
        servers.remove(atOffsets: offsets)
        if !servers.contains(where: { $0.address == selectedServerAddress }), let first = servers.first {
            selectedServerAddress = first.address
        }
    }

    func moveServers(from source: IndexSet, to destination: Int) {
        servers.move(fromOffsets: source, toOffset: destination)
    }

    func resetServers() {
        servers = Self.defaultServers
        selectedServerAddress = Self.defaultServers[0].address
    }

    // MARK: - Remote list

    /// Downloads a JSON list of servers and merges it into the local list.
    /// Accepted formats:
    ///   { "servers": [ { "name": "...", "address": "https://..." } ] }   (SideStore format)
    ///   [ { "name": "...", "address" | "url": "https://..." } ]
    ///   [ "https://...", ... ]
    /// Returns the number of servers that were added.
    @MainActor
    func fetchRemoteServers() async throws -> Int {
        guard let url = URL(string: serverListURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw "Invalid list URL"
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw "The server list returned HTTP \(http.statusCode)"
        }

        let remote = try Self.parseServerList(data)
        guard !remote.isEmpty else { throw "The list doesn't contain any server" }

        var added = 0
        for entry in remote {
            guard let address = Self.normalizedAddress(entry.address) else { continue }
            if let index = servers.firstIndex(where: { $0.address == address }) {
                if servers[index].isRemote { servers[index].name = entry.name }
            } else {
                servers.append(AnisetteServer(name: entry.name, address: address, isRemote: true))
                added += 1
            }
        }
        return added
    }

    static func parseServerList(_ data: Data) throws -> [AnisetteServer] {
        let json = try JSONSerialization.jsonObject(with: data)
        let items: [Any]
        if let dict = json as? [String: Any] {
            guard let list = dict["servers"] as? [Any] else { throw "JSON has no \"servers\" array" }
            items = list
        } else if let list = json as? [Any] {
            items = list
        } else {
            throw "Unsupported JSON format"
        }

        return items.compactMap { item in
            if let address = item as? String {
                return AnisetteServer(name: URL(string: address)?.host ?? address, address: address, isRemote: true)
            }
            guard let dict = item as? [String: Any],
                  let address = (dict["address"] ?? dict["url"]) as? String else { return nil }
            let name = dict["name"] as? String ?? URL(string: address)?.host ?? address
            return AnisetteServer(name: name, address: address, isRemote: true)
        }
    }
}
