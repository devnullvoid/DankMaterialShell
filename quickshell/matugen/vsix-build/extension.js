const vscode = require("vscode");
const path = require("path");
const fs = require("fs");

let watcher = null;
let reloadTimeout = null;

function activate(context) {
  const themesDir = path.join(context.extensionPath, "themes");

  try {
    watcher = vscode.workspace.createFileSystemWatcher(
      new vscode.RelativePattern(themesDir, "*.json")
    );
  } catch (e) {
    return;
  }

  if (!watcher) return;

  const reloadTheme = (uri) => {
    if (reloadTimeout) clearTimeout(reloadTimeout);

    reloadTimeout = setTimeout(async () => {
      const config = vscode.workspace.getConfiguration("workbench");
      const currentTheme = config.get("colorTheme");

      if (!currentTheme?.includes("DankShell")) return;

      let themeFile;
      switch (true) {
        case currentTheme.includes("Light"):
          themeFile = path.join(themesDir, "dankshell-light.json");
          break;
        case currentTheme.includes("Dark"):
          themeFile = path.join(themesDir, "dankshell-dark.json");
          break;
        default:
          themeFile = path.join(themesDir, "dankshell-default.json");
      }

      let themeData;
      try {
        const content = fs.readFileSync(themeFile, "utf8");
        themeData = JSON.parse(content);
      } catch (e) {
        return;
      }

      if (!themeData?.colors) return;

      await config.update(
        "colorCustomizations",
        { "[Dynamic Base16 DankShell]": themeData.colors },
        vscode.ConfigurationTarget.Global
      );
    }, 150);
  };

  watcher.onDidChange(reloadTheme);
  watcher.onDidCreate(reloadTheme);

  context.subscriptions.push(watcher);
}

function deactivate() {
  if (reloadTimeout) clearTimeout(reloadTimeout);
  if (watcher) watcher.dispose();
}

module.exports = { activate, deactivate };
