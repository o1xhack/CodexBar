import CodexBarCore
import SweetCookieKit
import Testing

struct BrowserCookieOrderStatusStringTests {
    #if os(macOS)
    @Test
    func `cursor no session includes browser login hint`() {
        let order = ProviderDefaults.metadata[.cursor]?.browserCookieOrder ?? Browser.defaultImportOrder
        let message = CursorStatusProbeError.noSessionCookie.errorDescription ?? ""
        #expect(message.contains(order.loginHint))
    }

    @Test
    func `factory no session includes browser login hint`() {
        let order = ProviderDefaults.metadata[.factory]?.browserCookieOrder ?? Browser.defaultImportOrder
        let message = FactoryStatusProbeError.noSessionCookie.errorDescription ?? ""
        #expect(message.contains(order.loginHint))
    }
    #endif
}
