// The focused-window border: a 2px blue -> green gradient that slowly turns.
// Same formula as home/.config/quickshell/kalango/SpinningBorder.qml (see #13).
import QtQuick
import QtQuick.Shapes

Shape {
    id: border

    property real radius: 14
    property real thickness: 2
    property real angle: 0

    readonly property real gx: Math.cos(angle * Math.PI / 180) / Math.max(1, width)
    readonly property real gy: Math.sin(angle * Math.PI / 180) / Math.max(1, height)
    readonly property real halfX: gx / (gx * gx + gy * gy) / 2
    readonly property real halfY: gy / (gx * gx + gy * gy) / 2

    preferredRendererType: Shape.CurveRenderer

    NumberAnimation on angle {
        from: 0
        to: 360
        duration: 8000
        loops: Animation.Infinite
    }

    ShapePath {
        strokeWidth: -1
        fillRule: ShapePath.OddEvenFill
        fillGradient: LinearGradient {
            x1: border.width / 2 - border.halfX
            y1: border.height / 2 - border.halfY
            x2: border.width / 2 + border.halfX
            y2: border.height / 2 + border.halfY
            GradientStop { position: 0; color: "#2E6BFF" }
            GradientStop { position: 1; color: "#3DFF9A" }
        }
        PathRectangle {
            width: border.width
            height: border.height
            radius: border.radius
        }
        PathRectangle {
            x: border.thickness
            y: border.thickness
            width: border.width - 2 * border.thickness
            height: border.height - 2 * border.thickness
            radius: border.radius - border.thickness
        }
    }
}
