import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.DankBar
import qs.Modules.DankIsland
import qs.Modules.Frame
import qs.DankCommon.Common as DC

// State pulses (caps lock, charging) and the mic level share the system transient with volume, and the duo status glyph loads in the home face.
ShellRoot {
    id: root

    readonly property var screen: Quickshell.screens[0]
    readonly property string barId: "main"

    Item {
        Repeater {
            model: ScriptModel {
                values: SettingsData.barConfigs
                objectProp: "id"
            }
            delegate: DankBar {
                required property var modelData
                barConfig: modelData
            }
        }
    }

    Frame {}

    DankIsland {}

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        DC.Style.theme = Theme;
        DC.Style.settings = SettingsData;
        DC.I18n.backend = I18n;
    }

    Timer {
        interval: 0
        running: SettingsData._hasLoaded && SessionData._hasLoaded
        onTriggered: {
            SettingsData.reduceMotion = true;
            SettingsData.frameMode = "connected";
            SettingsData.frameEnabled = true;
            FrameTransitionState.acknowledge(FrameTransitionState.revision);
            SettingsData.barConfigs = [
                {
                    id: root.barId,
                    enabled: true,
                    visible: true,
                    position: 0,
                    screenPreferences: ["all"],
                    leftWidgets: ["clock"],
                    centerWidgets: [
                        {
                            id: "island",
                            enabled: true,
                            islandBatteryStyle: "duo",
                            islandHomeLayout: [
                                {
                                    id: "status",
                                    enabled: true
                                },
                                {
                                    id: "clock",
                                    enabled: true
                                }
                            ]
                        }
                    ],
                    rightWidgets: ["clock"]
                }
            ];
        }
    }

    Timer {
        id: steps

        property int step: 0
        property int waited: 0
        readonly property var body: IslandHostRegistry.hostFor(root.screen.name, root.barId)

        interval: 25
        repeat: true
        running: !!body && !!body.islandController && SettingsData.frameEnabled

        function finish(message) {
            if (message)
                console.error("FIXTURE_FAIL", message);
            else
                console.log("FIXTURE_PASS");
            stop();
            Qt.quit();
        }

        function expectActivity(activityId) {
            if (body.islandController.activeActivity === activityId)
                return true;
            finish("expected " + activityId + " but the island shows " + body.islandController.activeActivity);
            return false;
        }

        onTriggered: {
            if (++waited > 800) {
                finish("timed out at step " + step);
                return;
            }
            if (body.motionRunning || body.bandThickness <= 0)
                return;
            const controller = body.islandController;
            waited = 0;
            switch (step++) {
            case 0:
                if (!controller.requestSystemActivity("capslock")) {
                    finish("caps lock is not a system transient");
                    return;
                }
                expectActivity("capslock");
                return;
            case 1:
                if (!controller.requestSystemActivity("charging"))
                    finish("charging is not a system transient");
                return;
            case 2:
                if (!expectActivity("charging"))
                    return;
                if (controller.compactTargetFor("charging").width === controller.compactTargetFor("volume").width)
                    finish("a state pulse borrows the level pill width");
                return;
            case 3:
                if (!controller.requestSystemActivity("mic"))
                    finish("mic is not a system level");
                return;
            case 4:
                if (!expectActivity("mic"))
                    return;
                controller.requestCollapse();
                return;
            default:
                if (expectActivity("home"))
                    finish("");
            }
        }
    }
}
