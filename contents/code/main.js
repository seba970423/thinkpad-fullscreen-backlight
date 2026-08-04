const SYSTEMD_SERVICE = "org.freedesktop.systemd1";
const SYSTEMD_PATH = "/org/freedesktop/systemd1";
const SYSTEMD_MANAGER = "org.freedesktop.systemd1.Manager";

let lightIsOff = false;

function startUnit(unitName) {
    callDBus(
        SYSTEMD_SERVICE,
        SYSTEMD_PATH,
        SYSTEMD_MANAGER,
        "StartUnit",
        unitName,
        "replace"
    );
}

function relevantFullscreenExists() {
    const windows = workspace.stackingOrder;

    for (let i = 0; i < windows.length; ++i) {
        const window = windows[i];

        if (
            window &&
            window.fullScreen &&
            !window.minimized &&
            !window.specialWindow
        ) {
            return true;
        }
    }

    return false;
}

function updateBacklight() {
    const shouldBeOff = relevantFullscreenExists();

    if (shouldBeOff === lightIsOff) {
        return;
    }

    lightIsOff = shouldBeOff;
    startUnit(`kbdlight@${shouldBeOff ? "off" : "restore"}.service`);
}

function watchWindow(window) {
    if (!window) {
        return;
    }

    window.fullScreenChanged.connect(updateBacklight);
    window.minimizedChanged.connect(updateBacklight);
}

workspace.windowAdded.connect(function(window) {
    watchWindow(window);
    updateBacklight();
});

workspace.windowRemoved.connect(updateBacklight);

const existingWindows = workspace.stackingOrder;
for (let i = 0; i < existingWindows.length; ++i) {
    watchWindow(existingWindows[i]);
}

updateBacklight();
