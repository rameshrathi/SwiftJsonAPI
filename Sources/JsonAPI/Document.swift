//
//  AttributesType.swift
//  
//
//  Created by ramesh on 27/07/23.
//

import Foundation

public protocol IdentifierProtocol {
    var id: Identifier { get }
}

/// Representing any resource in document with type and Id
public struct Identifier: Codable, Hashable, CustomStringConvertible {

    public let id: String

    public let type: String

    public var description: String {
        "\(type)_\(id)"
    }
}

/// Document object mapped with attributes type
public struct DocumentObject<AttributesType: Decodable>: IdentifierProtocol {
    public let id: Identifier
    public let attributes: AttributesType
    public let relationships: [String: [Identifier]]

    public func relationship(for key: String) -> [Identifier] {
        relationships[key] ?? []
    }
}

/// Document represent any resource containing information about any object
public struct Document<AttributesType: Decodable> {

    public let primary: [DocumentObject<AttributesType>]
    private let included: [Identifier: DocumentDecoder<AttributesType>.DecodedObject]

    public init(decodedObjects: [DocumentObject<AttributesType>], includedObjects: [Identifier: DocumentDecoder<AttributesType>.DecodedObject]) {
        self.primary = decodedObjects
        self.included = includedObjects
    }

    public func relationships<T: Decodable>(for id: Identifier) throws -> DocumentObject<T> {
        guard let object = included[id] else {
            throw DocumentError.emptyRelationship
        }
        guard let attributes = object.attributes as? T else {
            throw DocumentError.typeNotMached
        }
        return DocumentObject<T>(id: object.id, attributes: attributes, relationships: object.relationships.mapValues { $0.data })
    }
}
