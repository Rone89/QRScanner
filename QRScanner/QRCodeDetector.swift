import Foundation

enum QRCodeType {
    case alipay(url: String)
    case wechat
    case generic
}

struct QRCodeDetector {
    func detectQRCodeType(_ code: String) -> QRCodeType {
        let lowercased = code.lowercased()

        // Detect Alipay QR codes
        if lowercased.contains("alipay") ||
           lowercased.contains("alipays://") ||
           lowercased.hasPrefix("https://qr.alipay.com") ||
           lowercased.hasPrefix("https://ds.alipay.com") {
            return .alipay(url: code)
        }

        // Detect WeChat QR codes
        if lowercased.contains("weixin://") ||
           lowercased.contains("wxp://") ||
           lowercased.hasPrefix("https://wx.tenpay.com") ||
           lowercased.hasPrefix("https://payapp.weixin.qq.com") {
            return .wechat
        }

        // Generic QR code (could be aggregated payment code)
        return .generic
    }
}
