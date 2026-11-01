// The focused-window border, for shell panels: a 2px blue -> green gradient that
// slowly turns. Same formula as patches/kde-rounded-corners-spin-gradient.patch
// (t = dot(uv - 0.5, dir) + 0.5, one clockwise turn every Theme.spinSeconds), so
// a panel looks exactly like the active window. Fill it over its parent.
import QtQuick
import QtQuick.Shapes

Shape {
    id: border

    property real radius: Theme.radius
    property real thickness: Theme.border
    property bool running: true
    property real angle: 0

    // The gradient line whose ends match t = 0 and t = 1 of the formula above
    readonly property real gx: Math.cos(angle * Math.PI / 180) / Math.max(1, width)
    readonly property real gy: Math.sin(angle * Math.PI / 180) / Math.max(1, height)
    readonly property real halfX: gx / (gx * gx + gy * gy) / 2
    readonly property real halfY: gy / (gx * gx + gy * gy) / 2

    preferredRendererType: Shape.CurveRenderer

    NumberAnimation on angle {
        from: 0
        to: 360
        duration: Theme.spinSeconds * 1000
        loops: Animation.Infinite
        running: border.running
    }

    // A ring: the outer rounded rectangle minus the inner one
    ShapePath {
        strokeWidth: -1
        fillRule: ShapePath.OddEvenFill
        fillGradient: LinearGradient {
            x1: border.width / 2 - border.halfX
            y1: border.height / 2 - border.halfY
            x2: border.width / 2 + border.halfX
            y2: border.height / 2 + border.halfY
            GradientStop { position: 0; color: Theme.blue }
            GradientStop { position: 1; color: Theme.neon }
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
