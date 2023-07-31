import XCTest
@testable import JsonAPI

final class JsonDecodingTests: XCTestCase {

    func testResourceWithRelations() throws {

        guard let jsonData = jsonData else { return }
        let decoder = DocumentDecoder<Article>(
            ["people": Person.self, "comments": Comment.self, "articles": Article.self]
        )

        let documents: [Document<Article, ArticleRelation>] = try decoder.decodeArray(jsonData)
        XCTAssertEqual(documents.count, 1)

        let comments: [Relationship<Comment>] = try documents[0].relationshipFor(key: "comments")
        XCTAssertEqual(comments.count, 2)
    }

    func testJsonWithError() throws {
        guard let jsonData = errorJsonData else { return }
        let decoder = DocumentDecoder<Article>(
            ["articles": Article.self]
        )
        do {
            let _: [Document<Article, ArticleRelation>] = try decoder.decodeArray(jsonData)
        } catch {
            XCTAssert(error is DocumentError)
        }
    }
}
