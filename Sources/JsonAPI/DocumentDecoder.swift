//
//  JsonParser.swift
//  
//
//  Created by ramesh on 27/07/23.
//

import Foundation

public enum DocumentError: Error {
    public struct ErrorContent: Decodable {
        let status: String
        let title: String
        let detail: String?
    }
    public struct ErrorBox: Decodable {
        public let errors: [ErrorContent]
    }
    case emptyData
    case emptyDocument
    case errorData(ErrorBox)
    case incompleteTypesMapping
    case emptyRelationship
    case typeNotMached
}

/// Document Decoder for decoding any JsonAPI reponse format 2.1
public struct DocumentDecoder<AttributesType: Decodable> {

    struct DecodingState {
        var undecodedObjects: [Identifier: UndecodedObject] = [:]
        var decodedObjects: [Identifier: DecodedObject] = [:]
    }

    let typesMapping: [String: Decodable.Type]

    public init(_ typesMapping: [String: Decodable.Type]) {
        self.typesMapping = typesMapping
    }

    struct TopLevelBox: Decodable {
        let data: [UndecodedObject]
        let included: [UndecodedObject]?
    }

    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// Convert un-decoded objects to decoded objects
    private func decodeUndecodedObjects(_ state: inout DecodingState) throws {
        // Processing undecoded objects
        try state.undecodedObjects.forEach { id, object in
            guard let decodingType = typesMapping[id.type] else {
                assertionFailure("Must have a type mapping for: \(id.type)")
                return
            }
            let container = try object.attributesDecoder.singleValueContainer()
            let attributes = try container.decode(decodingType)

            let relationshipsContainer = try object.relationshipsDecoder.singleValueContainer()
            let isNullRelatonship = relationshipsContainer.decodeNil()

            state.undecodedObjects.removeValue(forKey: id)
            state.decodedObjects[id] = DecodedObject(
                id: id, attributes: attributes,
                relationships: isNullRelatonship ? [:] : (try relationshipsContainer.decode([String: RelationshipsMapping].self))
            )
        }
    }

    public func decodeArray(_ data: Data) throws -> Document<AttributesType> {

        // Check if any error is received
        if let errors = try? jsonDecoder.decode(DocumentError.ErrorBox.self, from: data) {
            throw DocumentError.errorData(errors)
        }

        let box = try jsonDecoder.decode(TopLevelBox.self, from: data)

        // Box.Data should not be empty
        if box.data.isEmpty {
            throw DocumentError.emptyDocument
        }

        var state = DecodingState()
        for item in box.data {
            state.undecodedObjects[item.id] = item
        }
        for item in box.included ?? [] {
            state.undecodedObjects[item.id] = item
        }

        // Decode undecoded objects to array of `DecodedObject`
        try decodeUndecodedObjects(&state)
        // `state.undecodedObjects` must be empty otherwise some docoding must has been interrupted
        // We can continue processing rest of the items
        assert(state.undecodedObjects.isEmpty)

        var decodedObjects: [DocumentObject<AttributesType>] = []

        for identifier in box.data.map({ $0.id }) {
            guard let object = state.decodedObjects[identifier] else {
                assertionFailure("Must have object for ID: \(identifier)")
                continue
            }

            // Relationship
            let relationshipsMap = object.relationships.mapValues { $0.data }
            decodedObjects.append(
                .init(id: object.id, attributes: object.attributes as! AttributesType, relationships: relationshipsMap)
            )
        }

        // Success parsing
        return Document<AttributesType>(
            decodedObjects: decodedObjects,
            includedObjects: state.decodedObjects.mapValues {
                .init(id: $0.id, attributes: $0.attributes, relationships: $0.relationships)
            }
        )
    }
}

extension DocumentDecoder {
    struct UndecodedObject: Decodable {

        let id: Identifier

        let attributesDecoder: Decoder
        let relationshipsDecoder: Decoder

        enum CodingKeys: CodingKey {
            case id
            case type
            case meta
            case links
            case attributes
            case relationships
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let id = try container.decode(String.self, forKey: .id)
            let type = try container.decode(String.self, forKey: .type)
            self.id = Identifier(id: id, type: type)

            self.attributesDecoder = try container.superDecoder(forKey: .attributes)
            self.relationshipsDecoder = try container.superDecoder(forKey: .relationships)
        }
    }

    public struct RelationshipsMapping: Decodable {

        public let data: [Identifier]

        public enum CodingKeys: CodingKey {
            case data
        }

        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            if let links = try? container.decode([Identifier].self, forKey: CodingKeys.data) {
                data = links
            }
            else {
                let link  = try container.decode(Identifier.self, forKey: CodingKeys.data)
                data = [link]
            }
        }
    }

    public struct DecodedObject {
        public let id: Identifier
        public let attributes: Decodable
        public let relationships: [String: RelationshipsMapping]
    }
}
