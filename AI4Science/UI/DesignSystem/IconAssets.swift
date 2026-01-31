import SwiftUI

/// SF Symbols and custom icon definitions for the AI4Science app
public struct IconAssets {
    // MARK: - Navigation Icons
    public static let home = Image(systemName: "house.fill")
    public static let homeOutline = Image(systemName: "house")
    public static let projects = Image(systemName: "folder.fill")
    public static let projectsOutline = Image(systemName: "folder")
    public static let capture = Image(systemName: "camera.fill")
    public static let captureOutline = Image(systemName: "camera")
    public static let analysis = Image(systemName: "chart.bar.fill")
    public static let analysisOutline = Image(systemName: "chart.bar")
    public static let settings = Image(systemName: "gear")
    public static let settingsFill = Image(systemName: "gear.circle.fill")

    // MARK: - Action Icons
    public static let add = Image(systemName: "plus")
    public static let addCircle = Image(systemName: "plus.circle.fill")
    public static let edit = Image(systemName: "pencil")
    public static let delete = Image(systemName: "trash")
    public static let share = Image(systemName: "square.and.arrow.up")
    public static let copy = Image(systemName: "doc.on.doc")
    public static let export = Image(systemName: "arrow.up.doc")
    public static let import_icon = Image(systemName: "arrow.down.doc")
    public static let download = Image(systemName: "arrow.down.circle")
    public static let upload = Image(systemName: "arrow.up.circle")
    public static let save = Image(systemName: "checkmark.circle")
    public static let cancel = Image(systemName: "xmark.circle")
    public static let close = Image(systemName: "xmark")
    public static let back = Image(systemName: "chevron.left")
    public static let forward = Image(systemName: "chevron.right")
    public static let refresh = Image(systemName: "arrow.clockwise")
    public static let search = Image(systemName: "magnifyingglass")
    public static let clear = Image(systemName: "xmark.circle.fill")

    // MARK: - Status Icons
    public static let success = Image(systemName: "checkmark.circle.fill")
    public static let error = Image(systemName: "xmark.circle.fill")
    public static let warning = Image(systemName: "exclamationmark.circle.fill")
    public static let info = Image(systemName: "info.circle.fill")
    public static let loading = Image(systemName: "hourglass")
    public static let pending = Image(systemName: "clock.fill")

    // MARK: - Media Icons
    public static let image = Image(systemName: "photo.fill")
    public static let imageOutline = Image(systemName: "photo")
    public static let camera = Image(systemName: "camera.fill")
    public static let cameraOutline = Image(systemName: "camera")
    public static let video = Image(systemName: "video.fill")
    public static let videoOutline = Image(systemName: "video")
    public static let play = Image(systemName: "play.fill")
    public static let pause = Image(systemName: "pause.fill")
    public static let stop = Image(systemName: "stop.fill")
    public static let zoomIn = Image(systemName: "plus.magnifyingglass")
    public static let zoomOut = Image(systemName: "minus.magnifyingglass")
    public static let crop = Image(systemName: "crop")
    public static let rotate = Image(systemName: "rotate.right")

    // MARK: - Analysis Icons
    public static let chart = Image(systemName: "chart.bar.fill")
    public static let chartLine = Image(systemName: "chart.line.uptrend.xyaxis")
    public static let pie = Image(systemName: "chart.pie.fill")
    public static let graph = Image(systemName: "graph")
    public static let timeline = Image(systemName: "timeline.selection")
    public static let compare = Image(systemName: "arrow.left.arrow.right")
    public static let filter = Image(systemName: "slider.horizontal.3")
    public static let sort = Image(systemName: "arrow.up.arrow.down")

    // MARK: - Annotation Icons
    public static let pen = Image(systemName: "pencil.tip")
    public static let paintbrush = Image(systemName: "paintbrush.fill")
    public static let highlighter = Image(systemName: "marker")
    public static let eraser = Image(systemName: "eraser.fill")
    public static let box = Image(systemName: "rectangle.dashed")
    public static let circle = Image(systemName: "circle.dashed")
    public static let polygon = Image(systemName: "triangle.fill")
    public static let freehand = Image(systemName: "scribble.variable")

    // MARK: - Science Icons
    public static let microscope = Image(systemName: "testtube.2")
    public static let flask = Image(systemName: "flask.fill")
    public static let atom = Image(systemName: "atom")
    public static let settings_science = Image(systemName: "gearshape.2.fill")
    public static let brain = Image(systemName: "brain.head.profile")
    public static let sparkles = Image(systemName: "sparkles")

    // MARK: - Organization Icons
    public static let folder = Image(systemName: "folder.fill")
    public static let folderOutline = Image(systemName: "folder")
    public static let tag = Image(systemName: "tag.fill")
    public static let tagOutline = Image(systemName: "tag")
    public static let star = Image(systemName: "star.fill")
    public static let starOutline = Image(systemName: "star")
    public static let heart = Image(systemName: "heart.fill")
    public static let heartOutline = Image(systemName: "heart")

    // MARK: - Account Icons
    public static let user = Image(systemName: "person.fill")
    public static let userOutline = Image(systemName: "person")
    public static let users = Image(systemName: "person.2.fill")
    public static let usersOutline = Image(systemName: "person.2")
    public static let logout = Image(systemName: "power")
    public static let login = Image(systemName: "person.badge.key.fill")

    // MARK: - System Icons
    public static let bell = Image(systemName: "bell.fill")
    public static let bellOutline = Image(systemName: "bell")
    public static let mail = Image(systemName: "envelope.fill")
    public static let mailOutline = Image(systemName: "envelope")
    public static let phone = Image(systemName: "phone.fill")
    public static let link = Image(systemName: "link")
    public static let wifi = Image(systemName: "wifi")
    public static let battery = Image(systemName: "battery.100")
    public static let checkmark = Image(systemName: "checkmark")
    public static let menu = Image(systemName: "line.3.horizontal")
    public static let lock = Image(systemName: "lock.fill")
    public static let lockOutline = Image(systemName: "lock")
    public static let clock = Image(systemName: "clock.fill")
    public static let clockOutline = Image(systemName: "clock")

    // MARK: - File/Document Icons
    public static let document = Image(systemName: "doc.fill")
    public static let documentOutline = Image(systemName: "doc")
    public static let pdf = Image(systemName: "doc.pdf.fill")
    public static let zip = Image(systemName: "doc.zipper")
    public static let spreadsheet = Image(systemName: "tablecells.fill")

    // MARK: - Custom Icon Sizes
    public enum IconSize {
        case small
        case medium
        case large
        case xLarge
        case custom(CGFloat)

        public var value: CGFloat {
            switch self {
            case .small: return Spacing.iconSmall
            case .medium: return Spacing.iconMedium
            case .large: return Spacing.iconLarge
            case .xLarge: return Spacing.iconXLarge
            case .custom(let size): return size
            }
        }
    }

    public enum IconWeight {
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy

        public var fontWeight: Font.Weight {
            switch self {
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            }
        }
    }
}

// MARK: - Icon Modifiers
extension Image {
    /// Apply size to the icon
    public func iconSize(_ size: IconAssets.IconSize) -> some View {
        self
            .font(.system(size: size.value))
            .scaledToFit()
    }

    /// Apply weight to the icon
    public func iconWeight(_ weight: IconAssets.IconWeight) -> some View {
        self.font(.system(size: 24, weight: weight.fontWeight, design: .default))
    }

    /// Apply color tint
    public func iconTint(_ color: Color) -> some View {
        self.foregroundColor(color)
    }

    /// Create an icon button view
    public func asIconButton(
        size: IconAssets.IconSize = .medium,
        color: Color = ColorPalette.utsa_primary,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            self
                .font(.system(size: size.value, weight: .semibold, design: .default))
                .foregroundColor(color)
        }
    }
}

// MARK: - Badge Icons
public struct BadgeIcon: View {
    let icon: Image
    let badgeCount: Int
    let size: IconAssets.IconSize
    let color: Color

    public init(
        icon: Image,
        badgeCount: Int,
        size: IconAssets.IconSize = .medium,
        color: Color = ColorPalette.utsa_primary
    ) {
        self.icon = icon
        self.badgeCount = badgeCount
        self.size = size
        self.color = color
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            icon
                .font(.system(size: size.value, weight: .semibold, design: .default))
                .foregroundColor(color)

            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(ColorPalette.error)
                    .cornerRadius(10)
                    .offset(x: 8, y: -8)
            }
        }
    }
}
