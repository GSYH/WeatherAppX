import Foundation

public struct FileCache {
  private let directory: URL

  public init(folderName: String = "WeatherCache") {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    directory = base.appendingPathComponent(folderName, isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  public func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
    let url = directory.appendingPathComponent(key)
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
  }

  public func save<T: Encodable>(_ value: T, key: String) {
    let url = directory.appendingPathComponent(key)
    guard let data = try? JSONEncoder().encode(value) else { return }
    try? data.write(to: url, options: [.atomic])
  }
}
