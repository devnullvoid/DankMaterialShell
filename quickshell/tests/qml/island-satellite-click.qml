import QtQuick
import QtTest
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.DankBar
import qs.Modules.DankIsland
import qs.DankCommon.Common as DC

// A press on a satellite widget of a docked island must reach the widget's own MouseArea,
// and no MouseArea may paint over it: MouseArea installs an arrow cursor that hides the widget's.
ShellRoot {
    id: root

    TestCase { id: input; when: false }
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
    DankIsland { id: islands }

    function check(value, label) {
        if (!value)
            throw new Error(label);
    }

    function pressAreas(item, found) {
        if (item.containsPress !== undefined && item.acceptedButtons !== undefined)
            found.push(item);
        for (const child of item.children || [])
            pressAreas(child, found);
        return found;
    }

    function chain(item) {
        const items = [];
        for (let node = item; node; node = node.parent)
            items.unshift(node);
        return items;
    }

    // Paint order: z first, then declaration order under the first diverging ancestor.
    function paintsAbove(a, b) {
        const ca = chain(a), cb = chain(b);
        let i = 0;
        while (i < ca.length && i < cb.length && ca[i] === cb[i])
            i++;
        if (i === ca.length)
            return false;
        if (i === cb.length)
            return true;
        if (ca[i].z !== cb[i].z)
            return ca[i].z > cb[i].z;
        const siblings = ca[i - 1].children;
        return siblings.indexOf(ca[i]) > siblings.indexOf(cb[i]);
    }

    function areasAbove(widget, x, y) {
        return pressAreas(widget.Window.window.contentItem, []).filter(area => {
            if (!area.visible || !area.enabled || chain(area).includes(widget) || !paintsAbove(area, widget))
                return false;
            return area.contains(widget.mapToItem(area, x, y));
        });
    }

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
            SettingsData.frameEnabled = false;
            SettingsData.reduceMotion = true;
            SettingsData.barConfigs = [{ id: "isle", island: true, enabled: true, visible: true, position: 0, leftWidgets: ["launcherButton"], rightWidgets: ["clock"] }];
        }
    }
    Timer {
        id: steps

        property int waited: 0
        readonly property var screen: Quickshell.screens[0]
        readonly property var widget: BarWidgetService.getWidget("launcherButton", screen.name)

        interval: 25
        repeat: true
        running: islands.hosts().length === 1

        function finish(message) {
            running = false;
            if (message)
                console.error("FIXTURE_FAIL", message);
            else
                console.info("FIXTURE_PASS");
            Qt.quit();
        }

        onTriggered: {
            if (!widget || widget.width <= 0 || !widget.visible) {
                if (++waited > 400)
                    finish("launcher button never appeared: widget=" + widget + " width=" + (widget?.width) + " visible=" + (widget?.visible) + " hosts=" + islands.hosts().length);
                return;
            }
            try {
                const areas = root.pressAreas(widget, []);
                root.check(areas.length > 0, "widget has a press area");
                const above = root.areasAbove(widget, widget.width / 2, widget.height / 2);
                root.check(above.length === 0, "no MouseArea painted above the widget covers it: " + above);
                input.mouseMove(widget, widget.width / 2, widget.height / 2, 0);
                input.mousePress(widget, widget.width / 2, widget.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
                const pressedArea = areas.some(area => area.containsPress || area.pressed);
                input.mouseRelease(widget, widget.width / 2, widget.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
                root.check(pressedArea, "press reaches the satellite widget");
                finish("");
            } catch (error) {
                finish(error.message);
            }
        }
    }
}
