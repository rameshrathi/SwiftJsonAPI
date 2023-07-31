//
//  AttributesType.swift
//  
//
//  Created by ramesh on 27/07/23.
//

import Foundation

public struct Identifier: Codable, Hashable, CustomStringConvertible {

    public let id: String

    public let type: String

    public var description: String {
        "\(type)_\(id)"
    }
}

public protocol DocumentProtocol {
    var id: Identifier { get }
}

/// Document represent any resource containing information about any object
public struct Document<A: Decodable, R: Decodable>: DocumentProtocol {

    // Unique Identifier Of any document
    public let id: Identifier

    // Attributes of any document
    public let attributes: A

    // Relationships of any document
    public let relationships: [String: [Decodable]]

    public init(
        id: Identifier, attributes: A, relationships: [String: [Decodable]]
    ) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    public func relationshipFor<T>(key: String) throws -> T {
        if let items = relationships[key] as? T {
            return items
        }
        throw DocumentError.emptyRelationship
    }
}

public struct Relationships<RelationshipsType> {

    private var _container: [String: Decodable]

    public init(_container: [String : Decodable]) {
        self._container = _container
    }
}
