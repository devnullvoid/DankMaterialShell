pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property string query: ""
    property var results: []
    property string targetSection: ""
    property string highlightSection: ""
    property var registeredCards: ({})
    property var settingsIndex: []
    property bool indexLoaded: false

    readonly property var conditionMap: ({
            "isNiri": () => CompositorService.isNiri,
            "isHyprland": () => CompositorService.isHyprland,
            "isDwl": () => CompositorService.isDwl,
            "keybindsAvailable": () => KeybindsService.available,
            "soundsAvailable": () => AudioService.soundsAvailable,
            "cupsAvailable": () => CupsService.cupsAvailable,
            "networkNotLegacy": () => !NetworkService.usingLegacy,
            "dmsConnected": () => DMSService.isConnected && DMSService.apiVersion >= 23,
            "matugenAvailable": () => Theme.matugenAvailable
        })

    Component.onCompleted: indexFile.reload()

    FileView {
        id: indexFile
        path: Qt.resolvedUrl("../translations/settings_search_index.json")
        onLoaded: {
            try {
                root.settingsIndex = JSON.parse(text());
                root.indexLoaded = true;
            } catch (e) {
                console.warn("SettingsSearchService: Failed to parse index:", e);
                root.settingsIndex = [];
            }
        }
        onLoadFailed: error => console.warn("SettingsSearchService: Failed to load index:", error)
    }

    function registerCard(settingKey, item, flickable) {
        if (!settingKey)
            return;
        registeredCards[settingKey] = {
            item: item,
            flickable: flickable
        };
        if (targetSection === settingKey)
            scrollTimer.restart();
    }

    function unregisterCard(settingKey) {
        if (!settingKey)
            return;
        let cards = registeredCards;
        delete cards[settingKey];
        registeredCards = cards;
    }

    function navigateToSection(section) {
        targetSection = section;
        if (registeredCards[section])
            scrollTimer.restart();
    }

    function scrollToTarget() {
        if (!targetSection)
            return;
        const entry = registeredCards[targetSection];
        if (!entry || !entry.item || !entry.flickable)
            return;
        const flickable = entry.flickable;
        const item = entry.item;
        const contentItem = flickable.contentItem;

        if (!contentItem)
            return;
        const mapped = item.mapToItem(contentItem, 0, 0);
        const maxY = Math.max(0, flickable.contentHeight - flickable.height);
        const targetY = Math.min(maxY, Math.max(0, mapped.y - 16));
        flickable.contentY = targetY;

        highlightSection = targetSection;
        targetSection = "";
        highlightTimer.restart();
    }

    function clearHighlight() {
        highlightSection = "";
    }

    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: root.scrollToTarget()
    }

    Timer {
        id: highlightTimer
        interval: 2500
        onTriggered: root.highlightSection = ""
    }

    function checkCondition(item) {
        if (!item.conditionKey)
            return true;
        const condFn = conditionMap[item.conditionKey];
        if (!condFn)
            return true;
        return condFn();
    }

    function translateItem(item) {
        return {
            section: item.section,
            label: I18n.tr(item.label),
            tabIndex: item.tabIndex,
            category: I18n.tr(item.category),
            keywords: item.keywords || [],
            icon: item.icon || "settings",
            description: item.description ? I18n.tr(item.description) : "",
            conditionKey: item.conditionKey
        };
    }

    function search(text) {
        query = text;
        if (!text) {
            results = [];
            return;
        }

        const queryLower = text.toLowerCase().trim();
        const queryWords = queryLower.split(/\s+/).filter(w => w.length > 0);
        const scored = [];

        for (const item of settingsIndex) {
            if (!checkCondition(item))
                continue;

            const translated = translateItem(item);
            const labelLower = translated.label.toLowerCase();
            const categoryLower = translated.category.toLowerCase();
            let score = 0;

            if (labelLower === queryLower) {
                score = 10000;
            } else if (labelLower.startsWith(queryLower)) {
                score = 5000;
            } else if (labelLower.includes(queryLower)) {
                score = 1000;
            } else if (categoryLower.includes(queryLower)) {
                score = 500;
            }

            if (score === 0) {
                for (const keyword of item.keywords) {
                    if (keyword.startsWith(queryLower)) {
                        score = Math.max(score, 800);
                        break;
                    }
                    if (keyword.includes(queryLower)) {
                        score = Math.max(score, 400);
                    }
                }
            }

            if (score === 0 && queryWords.length > 1) {
                let allMatch = true;
                for (const word of queryWords) {
                    const inLabel = labelLower.includes(word);
                    const inKeywords = item.keywords.some(k => k.includes(word));
                    const inCategory = categoryLower.includes(word);
                    if (!inLabel && !inKeywords && !inCategory) {
                        allMatch = false;
                        break;
                    }
                }
                if (allMatch)
                    score = 300;
            }

            if (score > 0) {
                scored.push({
                    item: translated,
                    score: score
                });
            }
        }

        scored.sort((a, b) => b.score - a.score);
        results = scored.slice(0, 15).map(s => s.item);
    }

    function clear() {
        query = "";
        results = [];
    }
}
