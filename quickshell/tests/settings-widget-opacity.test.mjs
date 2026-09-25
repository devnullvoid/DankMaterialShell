import assert from "node:assert/strict";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

const store = loadScript(new URL("../Common/settings/SettingsStore.js", import.meta.url));

test("bar widgets follow the interface style only when their opacity already matches it", () => {
    const layered = store.migrateToVersion({
        configVersion: 30,
        foregroundLayerTransparency: 0.6,
        barConfigs: [{ id: "a", widgetTransparency: 0.6 }, { id: "b" }, { id: "c", widgetTransparency: 0.6, widgetFollowInterfaceStyle: false }]
    }, 31);
    const glass = store.migrateToVersion({
        configVersion: 30,
        blurEnabled: true,
        blurForegroundLayers: false,
        barConfigs: [{ id: "a", widgetTransparency: 0 }, { id: "b" }]
    }, 31);
    const follows = settings => JSON.parse(JSON.stringify(settings.barConfigs.map(bc => bc.widgetFollowInterfaceStyle)));
    assert.deepEqual(follows(layered), [true, false, false]);
    assert.deepEqual(follows(glass), [true, false]);
});
