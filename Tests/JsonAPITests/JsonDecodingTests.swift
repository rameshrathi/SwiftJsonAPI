import XCTest
@testable import JsonAPI

final class JsonDecodingTests: XCTestCase {

    func testResourceWithRelations() throws {

        guard let jsonData = jsonData else { return }
        let decoder = DocumentDecoder<Article>(
            ["people": Person.self, "comments": Comment.self, "articles": Article.self]
        )

        let documents: Document<Article> = try decoder.decodeArray(jsonData)
        XCTAssertEqual(documents.primary.count, 1)

        let comments = documents.primary[0].relationship(for: "comments")
        XCTAssertEqual(comments.count, 2)

        let comment: DocumentObject<Comment> = try documents.relationships(for: comments[0])
        XCTAssertEqual(comment.attributes.body, "First!")
    }

    func testJsonWithError() throws {
        guard let jsonData = errorJsonData else { return }
        let decoder = DocumentDecoder<Article>(
            ["articles": Article.self]
        )
        do {
            let _: Document<Article> = try decoder.decodeArray(jsonData)
        } catch {
            XCTAssert(error is DocumentError)
        }
    }
}
