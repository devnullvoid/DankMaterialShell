import QtQuick
import QtTest
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Lock
import qs.DankCommon.Common as DC

ShellRoot {
    id: root

    TestCase {
        id: input
        when: false
        name: "lock-status-row"
    }

    Item {
        width: 1200
        height: 100

        LockStatusRow {
            id: full
            showMediaPlayer: true
        }
        LockStatusRow {
            id: quiet
            showMediaPlayer: false
            y: 50
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        DC.Style.theme = Theme;
        DC.Style.settings = SettingsData;
        DC.I18n.backend = I18n;
    }

    function check(value, message) {
        if (!value)
            throw new Error(message);
    }

    function find(item, predicate) {
        if (predicate(item))
            return item;
        for (const child of item.children ?? []) {
            const found = find(child, predicate);
            if (found)
                return found;
        }
        return null;
    }

    Timer {
        interval: 0
        running: true
        onTriggered: {
            try {
                input.tryVerify(() => !!MprisController.activePlayer, 3000);

                const quietLoader = quiet.children.find(c => c.sourceComponent !== undefined && c.active !== undefined);
                root.check(quietLoader && !quietLoader.active && quietLoader.item === null, "media group stays unloaded when showMediaPlayer is off");
                const fullLoader = full.children.find(c => c.sourceComponent !== undefined && c.active !== undefined);
                input.tryVerify(() => fullLoader.active && fullLoader.item && fullLoader.visible, 1000, "media group loads with an active player");
                root.check(root.find(fullLoader.item, c => c.elide === Text.ElideRight).text !== "", "media title renders");
                root.check(quiet.implicitWidth === 0, "empty row takes no width");

                WeatherService.weather = {
                    available: true,
                    temp: 21,
                    tempF: 70,
                    wCode: 0
                };
                const temperature = root.find(full, c => c.text !== undefined && String(c.text).includes("21"));
                root.check(temperature && temperature.text.includes("21"), "weather shows celsius: " + (temperature ? temperature.text : "none"));
                full.useFahrenheit = true;
                root.check(temperature.text.includes("70"), "weather follows useFahrenheit");
                full.showWeather = false;

                const keyboardArea = root.find(full.children[0], c => c.hasOwnProperty("cursorShape") && c.hasOwnProperty("hoverEnabled"));
                full.interactive = true;
                root.check(keyboardArea.enabled, "interactive enables keyboard layout input");
                full.interactive = false;
                root.check(!keyboardArea.enabled, "interactive off disables the keyboard layout click");

                console.log("FIXTURE_PASS lock status row: media loader gating, weather units, interactive");
            } catch (error) {
                console.error("FIXTURE_FAIL", error.message);
            }
            Qt.quit();
        }
    }
}
