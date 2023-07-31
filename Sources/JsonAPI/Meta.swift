//
//  Meta.swift
//  
//
//  Created by ramesh on 29/07/23.
//

import Foundation

public struct Meta: Decodable, Equatable {

    // MARK: Interface

    public subscript(_ key: String) -> Any? {
        storage[key]?.unwrappedValue
    }

    public var isEmpty: Bool {
        storage.isEmpty
    }

    public init(_ dictionary: [String: Codable]) throws {
        storage = dictionary.mapValues { AnyCodable($0) }
    }

    private let storage: [String: AnyCodable]

    public static func == (lhs: Meta, rhs: Meta) -> Bool {
        lhs.storage == rhs.storage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = try container.decode([String: AnyCodable].self)
    }

    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// This structure knows how to decode and compare a number of different types.
    public struct AnyCodable: Codable, Equatable {
        /// The value wrapped by this instance. If value is an array or dictionary, the values should also be wrapped in `AnyDecodable`
        private let value: Any

        /// This returns the underlying value with all  `AnyDecodable` wrappers stripped away.
        /// It takes `value` and strips away any nested `AnyDecodable` wrappers.
        var unwrappedValue: Any {
            switch value {
            case let array as [AnyCodable]: return array.map { $0.unwrappedValue }
            case let dict as [String: AnyCodable]: return dict.mapValues { $0.unwrappedValue }
            default: return value
            }
        }

        init(_ value: Any) {
            // If value contains nested arrays or dictionaries, make sure the value types are always `AnyDecodable`
            func wrapIfNecessary(_ value: Any) -> AnyCodable {
                if let value = value as? AnyCodable {
                    return value
                } else {
                    return AnyCodable(value)
                }
            }

            if let array = value as? [Any] {
                self.value = array.map(wrapIfNecessary)
            } else if let dictionary = value as? [String: Any] {
                self.value = dictionary.mapValues(wrapIfNecessary)
            } else {
                self.value = value
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if container.decodeNil() {
                self.init(())
            } else if let bool = try? container.decode(Bool.self) {
                self.init(bool)
            } else if let int = try? container.decode(Int.self) {
                self.init(int)
            } else if let uint = try? container.decode(UInt.self) {
                self.init(uint)
            } else if let double = try? container.decode(Double.self) {
                self.init(double)
            } else if let string = try? container.decode(String.self) {
                self.init(string)
            } else if let array = try? container.decode([AnyCodable].self) {
                self.init(array)
            } else if let dictionary = try? container.decode([String: AnyCodable].self) {
                self.init(dictionary)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription:
                        "AnyDecodable value cannot be decoded. You may need to add a switch statement case in \(#file)"
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            if value is NSNull {
                try container.encodeNil()
            } else if let v = value as? Bool {
                try container.encode(v)
            } else if let v = value as? Int {
                try container.encode(v)
            } else if let v = value as? UInt {
                try container.encode(v)
            } else if let v = value as? Double {
                try container.encode(v)
            } else if let v = value as? String {
                try container.encode(v)
            } else if let v = value as? [AnyCodable] {
                try container.encode(v)
            } else if let v = value as? [String: AnyCodable] {
                try container.encode(v)
            } else {
                throw EncodingError.invalidValue(
                    value,
                    .init(
                        codingPath: [],
                        debugDescription: "Anycodable value cannot be encoded. You may need to add a switch statement case in \(#file)"
                    )
                )
            }
        }

        public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
            switch (lhs.value, rhs.value) {
            case let (l as NSNull, r as NSNull): return l == r
            case let (l as Bool, r as Bool): return l == r
            case let (l as Int, r as Int): return l == r
            case let (l as UInt, r as UInt): return l == r
            case let (l as Double, r as Double): return l == r
            case let (l as String, r as String): return l == r
            case let (l as [AnyCodable], r as [AnyCodable]): return l == r
            case let (l as [String: AnyCodable], r as [String: AnyCodable]): return l == r
            default: return false
            }
        }
    }
}

public enum Link: Decodable, Equatable {
    case string(String?)
    case object(href: String, meta: [String: Any])
    var url: URL? {
        switch self {
        case let .string(path): return path.flatMap { URL(string: $0) }
        case .object(href: let path, meta: _): return URL(string: path)
        }
    }
    public init(from decoder: Decoder) throws {
        enum ObjectCodingKeys: CodingKey {
            case href, meta
        }
        // Try parsing as a string first
        if let linkString = try? decoder.singleValueContainer().decode(String?.self) {
            self = .string(linkString)
        } else if (try? decoder.singleValueContainer().decodeNil()) == true {
            self = .string(nil)
        } else if let container = try? decoder.container(keyedBy: ObjectCodingKeys.self) {
            let href = try container.decode(String.self, forKey: .href)
            // TODO: Decode meta
            self = .object(href: href, meta: [:])
        } else {
            // From spec: A link MUST be represented as either a string or object.
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "A link MUST be represented as either a string or object.")
            )
        }
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url
    }
}
