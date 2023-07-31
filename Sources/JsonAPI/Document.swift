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

public protocol IdentifierProtocol {
    var id: Identifier { get }
}

/// Document represent any resource containing information about any object
public struct Document<A: Decodable, R: Decodable>: IdentifierProtocol, Equatable {
    public static func == (lhs: Document<A, R>, rhs: Document<A, R>) -> Bool {
        lhs.id == rhs.id
    }

    // Unique Identifier Of any document
    public let id: Identifier

    // Attributes of any document
    public let attributes: A

    // Relationships of any document
    public let relationships: [String: [RelationshipObject]]

    public init(
        id: Identifier, attributes: A, relationships: [String: [RelationshipObject]]
    ) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    public func relationshipFor<T: Decodable>(key: String) throws -> [Relationship<T>] {
        if let objects = relationships[key]  {
            return objects.map {
                Relationship<T>.init(id: $0.id, attributes: $0.attributes as! T)
            }
        }
        throw DocumentError.emptyRelationship
    }
}

public struct Relationship<AttributesType: Decodable> {
    public let id: Identifier
    public let attributes: AttributesType
}

public struct RelationshipObject {
    public let id: Identifier
    public let attributes: Decodable
}
