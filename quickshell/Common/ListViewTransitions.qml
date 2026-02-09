pragma Singleton
import QtQuick
import qs.Common

// Reusable ListView/GridView transitions
QtObject {
    id: root

    readonly property Transition add: Transition {
        ParallelAnimation {
            DankAnim {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.expressiveDurations.expressiveDefaultSpatial
                easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
            }
            DankAnim {
                property: "scale"
                from: 0.92
                to: 1
                duration: Theme.expressiveDurations.expressiveDefaultSpatial
                easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
            }
        }
    }

    readonly property Transition remove: Transition {
        ParallelAnimation {
            DankAnim {
                property: "opacity"
                to: 0
                duration: Theme.expressiveDurations.fast
                easing.bezierCurve: Theme.expressiveCurves.emphasizedAccel
            }
            DankAnim {
                property: "scale"
                to: 0.92
                duration: Theme.expressiveDurations.fast
                easing.bezierCurve: Theme.expressiveCurves.emphasizedAccel
            }
        }
    }

    readonly property Transition displaced: Transition {
        DankAnim {
            properties: "x,y"
            duration: Theme.expressiveDurations.expressiveDefaultSpatial
            easing.bezierCurve: Theme.expressiveCurves.expressiveDefaultSpatial
        }
    }

    readonly property Transition move: Transition {
        DankAnim {
            properties: "x,y"
            duration: Theme.expressiveDurations.expressiveDefaultSpatial
            easing.bezierCurve: Theme.expressiveCurves.standard
        }
    }
}
