import Foundation
import ReadiumShared
import ReadiumStreamer
import ReadiumNavigator

class BookOpener {
    static let shared = BookOpener()

    private let httpClient: DefaultHTTPClient
    private let assetRetriever: AssetRetriever
    private let publicationOpener: PublicationOpener

    private init() {
        httpClient = DefaultHTTPClient()
        assetRetriever = AssetRetriever(httpClient: httpClient)
        let parser = DefaultPublicationParser(
            httpClient: httpClient,
            assetRetriever: assetRetriever,
            pdfFactory: DefaultPDFDocumentFactory()
        )
        publicationOpener = PublicationOpener(parser: parser)
    }

    func open(url: URL) async throws -> Publication {
        let asset = try await assetRetriever.retrieve(url: FileURL(url: url)!).get()
        let publication = try await publicationOpener.open(asset: asset, allowUserInteraction: true).get()
        return publication
    }
}