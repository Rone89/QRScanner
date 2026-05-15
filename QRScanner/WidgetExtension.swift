import WidgetKit
import SwiftUI

struct QRScannerWidget: Widget {
    let kind: String = "QRScannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QRScannerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("快速扫码")
        .description("快速启动扫码功能")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct QRScannerWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView()
            case .systemMedium:
                MediumWidgetView()
            case .systemLarge:
                LargeWidgetView()
            case .accessoryCircular:
                CircularWidgetView()
            case .accessoryRectangular:
                RectangularWidgetView()
            case .accessoryInline:
                InlineWidgetView()
            case .systemExtraLarge:
                LargeWidgetView()
            @unknown default:
                SmallWidgetView()
            }
        }
    }
}

struct SmallWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(.ultraThinMaterial)

            VStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)

                Text("扫码")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .widgetURL(URL(string: "qrscanner://scan"))
    }
}

struct MediumWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(.ultraThinMaterial)

            HStack(spacing: 20) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("快速扫码")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text("轻触启动相机扫描二维码")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .widgetURL(URL(string: "qrscanner://scan"))
    }
}

struct LargeWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(.ultraThinMaterial)

            VStack(spacing: 24) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    Text("快速扫码")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("支持支付宝、微信及通用二维码")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 16) {
                    FeatureTag(icon: "dollarsign.circle.fill", text: "支付宝")
                    FeatureTag(icon: "message.fill", text: "微信")
                    FeatureTag(icon: "qrcode", text: "通用")
                }
            }
            .padding(32)
        }
        .widgetURL(URL(string: "qrscanner://scan"))
    }
}

struct FeatureTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.white.opacity(0.2))
        )
    }
}

struct CircularWidgetView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 24))
                .foregroundStyle(.white)
        }
        .widgetURL(URL(string: "qrscanner://scan"))
    }
}

struct RectangularWidgetView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 24))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("扫码")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("快速启动")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .widgetURL(URL(string: "qrscanner://scan"))
    }
}

struct InlineWidgetView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "qrcode.viewfinder")
            Text("扫码")
        }
        .widgetURL(URL(string: "qrscanner://scan"))
    }
}
