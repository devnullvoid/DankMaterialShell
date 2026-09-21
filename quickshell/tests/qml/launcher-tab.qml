import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Settings
import qs.DankCommon.Common as DC

ShellRoot {
    id: root

    property bool failed: false

    function check(condition, label) {
        if (condition)
            return;
        failed = true;
        console.log("FIXTURE_FAIL " + label);
    }

    function finish() {
        console.log(root.failed ? "FIXTURE_FAIL see above" : "FIXTURE_PASS");
    }

    Component {
        id: tabComponent
        LauncherTab {}
    }

    PanelWindow {
        color: "transparent"
        implicitWidth: 900
        implicitHeight: 1600
        anchors {
            top: true
            left: true
        }

        Item {
            id: stage
            anchors.fill: parent
        }
    }

    function typeName(item) {
        return String(item).split("(")[0].replace(/_QMLTYPE_\d+/, "").replace(/_QML_\d+/, "");
    }

    function collect(item, out) {
        const type = typeName(item);
        if (["QQuickImage", "IconImage", "AppIconRenderer", "StyledText", "DankIcon"].includes(type)) {
            const entry = {
                type: type,
                w: Math.round(item.width),
                h: Math.round(item.height),
                visible: item.visible
            };
            if (typeof item.text === "string")
                entry.text = item.text;
            if (item.source !== undefined)
                entry.source = String(item.source).replace(/^.*\//, "");
            if (item.status !== undefined)
                entry.status = item.status;
            out.push(entry);
        }
        for (const child of item.children || [])
            collect(child, out);
        return out;
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        property int step: 0
        onTriggered: {
            if (step++ === 0) {
                Quickshell.watchFiles = false;
                DC.Style.theme = Theme;
                DC.Style.settings = SettingsData;
                DC.I18n.backend = I18n;
                SessionData.hiddenApps = ["org.kde.dolphin", "missing.app"];
                SessionData.appOverrides = {
                    "kitty": {
                        name: "Kitty Renamed",
                        icon: ""
                    },
                    "ghost.app": {
                        name: "Ghost",
                        icon: "no-such-icon-name"
                    }
                };
                root.tab = tabComponent.createObject(stage, {
                    width: 860
                });
                if (!root.tab) {
                    console.error("FIXTURE_FAIL " + tabComponent.errorString());
                    Qt.quit();
                }
                return;
            }
            const nodes = collect(root.tab, []);
            const visibleTexts = nodes.filter(n => n.type === "StyledText" && n.visible).map(n => n.text);
            check(visibleTexts.includes("missing.app") && visibleTexts.includes("Ghost"), "hidden and overridden apps that are not installed still list by id or override name");
            console.log("PARITY " + JSON.stringify({
                count: nodes.length,
                images: nodes.filter(n => n.type !== "StyledText" && n.type !== "DankIcon"),
                texts: visibleTexts.filter(t => t === "Kitty Renamed" || t === "Ghost" || t === "missing.app" || t.startsWith("Dolphin"))
            }));
            root.finish();
            stop();
            Qt.quit();
        }
    }

    property var tab: null
}
