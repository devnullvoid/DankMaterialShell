import assert from "node:assert/strict";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

const store = loadScript(new URL("../Common/settings/SettingsStore.js", import.meta.url));

test("control center width percentages become square grid cells", () => {
    const migrated = store.migrateToVersion({
        configVersion: 26,
        controlCenterWidth: 800,
        controlCenterWidgets: [{ id: "wifi", width: 75 }, { id: "diskUsage", width: 25, mountPath: "/", instanceId: "disk" }, { id: "battery" }, { id: "plugin_x", width: 100, w: 3, h: 2, enabled: false }]
    }, 27);
    assert.equal(migrated.configVersion, 27);
    assert.equal(migrated.controlCenterColumns, 12);
    assert.equal(migrated.controlCenterWidth, undefined);
    assert.deepEqual(JSON.parse(JSON.stringify(migrated.controlCenterWidgets)), [{ id: "wifi", w: 6, h: 1 }, { id: "diskUsage", mountPath: "/", instanceId: "disk", w: 2, h: 1 }, { id: "battery", w: 4, h: 1 }, { id: "plugin_x", w: 6, h: 2, enabled: false }]);
    assert.equal(store.migrateToVersion(migrated, 27), null);
});

test("sparse settings migrate without inventing grid keys", () => {
    const migrated = store.migrateToVersion({ configVersion: 26, controlCenterWidth: 550, controlCenterWidgets: [{ id: "wifi", width: 50 }, { id: "battery", width: 100 }] }, 27);
    assert.equal(migrated.controlCenterColumns, 8);
    assert.deepEqual(JSON.parse(JSON.stringify(migrated.controlCenterWidgets)), [{ id: "wifi", w: 4, h: 1 }, { id: "battery", w: 8, h: 1 }]);
    const sparse = store.migrateToVersion({ configVersion: 26 }, 27);
    assert.equal(sparse.controlCenterColumns, undefined);
    assert.equal(sparse.controlCenterWidgets, undefined);
});

test("split header tiles collapse into one pinned header ahead of the layout", () => {
    const migrated = store.migrateToVersion({ configVersion: 32, controlCenterWidgets: [{ id: "userCard", w: 4, h: 1, hostname: false }, { id: "wifi", w: 4, h: 1, col: 0, row: 0 }, { id: "quickActions", w: 4, h: 1, powerAccent: true, actions: [{ id: "power", enabled: true }] }] }, 33);
    assert.deepEqual(JSON.parse(JSON.stringify(migrated.controlCenterWidgets)), [{ id: "header", enabled: true, w: 8, h: 1, hostname: false, actions: [{ id: "power", enabled: true }], powerAccent: true }, { id: "wifi", w: 4, h: 1, col: 0, row: 0 }]);
    assert.equal(migrated.configVersion, 33);
    assert.deepEqual(JSON.parse(JSON.stringify(store.migrateToVersion({ configVersion: 31, controlCenterWidgets: [{ id: "wifi", w: 4, h: 1 }] }, 33).controlCenterWidgets.map(w => w.id))), ["header", "wifi"]);
    assert.equal(store.migrateToVersion({ configVersion: 31 }, 33).controlCenterWidgets, undefined);
});
