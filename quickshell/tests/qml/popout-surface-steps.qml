import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Modules.ControlCenter
import qs.DankCommon.Common as DC

ShellRoot {
    id: root

    property var cc: null
    property bool failed: false
    property int step: 0
    property real originBefore: 0
    property real surfaceBefore: 0
    readonly property var screen: Quickshell.screens[0]

    function check(condition, label) {
        if (condition)
            return;
        failed = true;
        console.log("FIXTURE_FAIL " + label);
    }

    function origin() {
        const window = root.cc.contentWindow;
        if (window.anchors.right)
            return root.screen.width - window.WlrLayershell.margins.right - window.implicitWidth;
        return window.WlrLayershell.margins.left;
    }

    function surfaceWidth() {
        return root.cc.contentWindow.implicitWidth;
    }

    function content() {
        return root.cc.contentLoader.item;
    }

    function findGrid(item) {
        if (!item)
            return null;
        if (typeof item.displayedItems === "function")
            return item;
        for (const child of item.children) {
            const found = findGrid(child);
            if (found)
                return found;
        }
        return null;
    }

    Component {
        id: ccComponent
        ControlCenterPopout {}
    }

    function openAt(triggerX, section) {
        root.cc = ccComponent.createObject(root);
        root.cc.setBarContext(0, 0);
        root.cc.triggerScreen = root.screen;
        root.cc.setTriggerPosition(triggerX, 0, 40, section, root.screen);
        PopoutManager.requestPopout(root.cc, undefined, "main-" + section + "-cc");
        root.cc.open();
    }

    function enterEdit(label) {
        root.originBefore = origin();
        root.surfaceBefore = surfaceWidth();
        root.cc.editMode = true;
        check(origin() === root.originBefore, label + ": the surface origin holds until the buffer spans the target: " + JSON.stringify([origin(), root.originBefore]));
    }

    function settledEdit(label) {
        check(origin() < root.originBefore, label + ": the origin moves once the buffer grew: " + JSON.stringify([origin(), root.originBefore]));
    }

    function leaveEdit(label) {
        root.cc.editMode = false;
        check(origin() === root.originBefore && surfaceWidth() === root.surfaceBefore, label + ": leaving edit mode hands the surface back in one step: " + JSON.stringify([origin(), surfaceWidth(), root.originBefore, root.surfaceBefore]));
    }

    Timer {
        id: sequencer
        interval: 1500
        onTriggered: {
            switch (root.step++) {
            case 0:
                enterEdit("centered");
                interval = 400;
                break;
            case 1:
                settledEdit("centered");
                leaveEdit("centered");
                content().navigateTo("network");
                interval = 600;
                break;
            case 2:
                content().goBack();
                interval = 800;
                break;
            case 3:
                {
                    const grid = findGrid(content());
                    SettingsData.set("controlCenterColumns", CcMetrics.defaultColumns + 1);
                    check(grid.x === 0 && grid.width === grid.parent.width, "resizing after a page visit keeps the grid on the body: " + JSON.stringify([grid.x, grid.width, grid.parent.width]));
                    SettingsData.set("controlCenterColumns", CcMetrics.defaultColumns);
                }
                root.cc.close();
                interval = 800;
                break;
            case 4:
                root.cc.destroy();
                openAt(root.screen.width - 60, "right");
                interval = 1500;
                break;
            case 5:
                enterEdit("edge");
                interval = 400;
                break;
            case 6:
                settledEdit("edge");
                leaveEdit("edge");
                root.cc.close();
                interval = 500;
                break;
            case 7:
                console.log(root.failed ? "FIXTURE_FAIL see above" : "FIXTURE_PASS");
                stop();
                Qt.quit();
                return;
            }
            restart();
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        DC.Style.theme = Theme;
        DC.Style.settings = SettingsData;
        DC.I18n.backend = I18n;
        SettingsData.barConfigs = [
            {
                id: "main",
                enabled: true,
                visible: true,
                position: 0,
                spacing: 4,
                innerPadding: 4,
                leftWidgets: [],
                centerWidgets: [],
                rightWidgets: []
            }
        ];
        openAt(root.screen.width / 2, "center");
        sequencer.start();
    }
}
