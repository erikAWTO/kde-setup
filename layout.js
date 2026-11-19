// Plasma shell script, run by install.sh through org.kde.PlasmaShell.evaluateScript.
// install.sh replaces @HOME@ and @GPU@ before running it.

var HOME = "@HOME@";
var GPU = "@GPU@";
var VIDEO = "luisbocanegra.smart.video.wallpaper.reborn";

function rgb(h) {
    return [1, 3, 5].map(function (i) { return parseInt(h.substr(i, 2), 16); }).join(",");
}

function monitor(a, title, face, high, low, colors, faceCfg) {
    a.currentConfigGroup = ["Appearance"];
    a.writeConfig("Title", title);
    a.writeConfig("chartFace", face);
    a.currentConfigGroup = ["Sensors"];
    a.writeConfig("highPrioritySensorIds", JSON.stringify(high));
    a.writeConfig("lowPrioritySensorIds", JSON.stringify(low || []));
    a.currentConfigGroup = ["SensorColors"];
    for (var k in colors)
        a.writeConfig(k, rgb(colors[k]));
    a.currentConfigGroup = [face, "General"];
    for (var k in (faceCfg || {}))
        a.writeConfig(k, faceCfg[k]);
    return a;
}

panels().forEach(function (p) { p.remove(); });

// top bar
var top = new Panel;
top.location = "top";
top.height = 26;
top.floating = false;
top.addWidget("org.kde.plasma.kicker");
var pager = top.addWidget("com.github.tilorenz.compact_pager");
pager.currentConfigGroup = ["General"];
pager.writeConfig("forceLayout", 1);
top.addWidget("org.kde.plasma.marginsseparator");
top.addWidget("plasmusic-toolbar");
top.addWidget("org.kde.plasma.panelspacer");
var stats = monitor(top.addWidget("org.kde.plasma.systemmonitor"), "", "org.local.textint",
    ["cpu/all/usage", "cpu/all/averageTemperature", "memory/physical/usedPercent"], [],
    {"cpu/all/usage": "#a6e3a1", "cpu/all/averageTemperature": "#bdbdbd",
     "memory/physical/usedPercent": "#f5c2e7"});
stats.currentConfigGroup = ["Appearance"];
stats.writeConfig("updateRateLimit", 2000);
stats.currentConfigGroup = ["SensorLabels"];
stats.writeConfig("cpu/all/usage", "CPU");
// zero width space: a visible label gets elided next to the wider temperature value
stats.writeConfig("cpu/all/averageTemperature", "​");
stats.writeConfig("memory/physical/usedPercent", "RAM");
top.addWidget("org.kde.plasma.panelspacer");
var toggle = top.addWidget("org.kde.plasma.icon");
toggle.currentConfigGroup = ["General"];
toggle.writeConfig("url", "file://" + HOME + "/.local/share/applications/wallpaper-toggle.desktop");
top.addWidget("org.kde.plasma.systemtray");
top.addWidget("org.kde.plasma.keyboardlayout");
var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", false);
top.addWidget("org.kde.plasma.showdesktop");

// dock
var dock = new Panel;
dock.location = "bottom";
dock.height = 48;
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", ["preferred://filemanager", "applications:kitty.desktop",
    "preferred://browser", "applications:code.desktop"]);
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "autohide";
print("PANELS " + top.id + " " + dock.id + "\n");

// wallpaper and desktop widgets
var tile = {showLegend: true, showGridLines: false, showYAxisLabels: false, lineChartSmooth: true,
    lineChartFillOpacity: 30, historyAmount: 60, rangeAutoY: false, rangeFromY: 0, rangeToY: 100};

function stat(d, title, high, colors, labels, autoY) {
    var cfg = JSON.parse(JSON.stringify(tile));
    cfg.rangeAutoY = !!autoY;
    var a = monitor(d.addWidget("org.kde.plasma.systemmonitor"), title, "org.kde.ksysguard.linechart",
        high, [], colors, cfg);
    a.currentConfigGroup = ["Appearance"];
    a.writeConfig("updateRateLimit", 1000);
    // short legend names keep every tile at the same minimum width
    a.currentConfigGroup = ["SensorLabels"];
    for (var k in labels)
        a.writeConfig(k, labels[k]);
    return a;
}

// Units only. The place is picked in the widget settings after install.
function weather(w) {
    w.currentConfigGroup = ["General"];
    w.writeConfig("firstRun", false);
    w.currentConfigGroup = ["Units"];
    w.writeConfig("temperatureType", 0);
    w.writeConfig("pressureType", 0);
    w.writeConfig("windSpeedType", 0);
    return w;
}

desktops().forEach(function (d) {
    var g = screenGeometry(d.screen);
    var portrait = g.height > g.width;
    var file = HOME + "/.local/share/wallpapers/manet/manet_wallpaper" + (portrait ? "_portrait" : "") + ".mp4";
    d.wallpaperPlugin = VIDEO;
    d.currentConfigGroup = ["Wallpaper", VIDEO, "General"];
    d.writeConfig("VideoUrls", JSON.stringify([{filename: "file://" + file, enabled: true, duration: 0,
        customDuration: 0, playbackRate: 0.0, alternativePlaybackRate: 0.0, loop: true,
        dayNightCycleAssignment: 0}]));
    d.writeConfig("FillMode", 2);

    if (d.screen != 0)
        return;
    d.widgets().forEach(function (w) { w.remove(); });

    var gpuColors = {}, gpuLabels = {};
    gpuColors[GPU + "/usage"] = "#f9e2af";
    gpuLabels[GPU + "/usage"] = "Load";

    // Calendar, weather and music on the left edge, stats on the right, on a 16 px grid.
    // Heights respect each widget's minimum size (media player 368, network tile 192),
    // otherwise Plasma moves them.
    var info = 16, stats = g.width - 16 - 208;
    var place = [
        [d.addWidget("org.kde.plasma.calendar"), info, 48, 416, 288],
        [weather(d.addWidget("org.kde.weatherWidget-3")), info, 352, 416, 208],
        [d.addWidget("org.kde.plasma.mediacontroller"), info, 576, 416, 416],
        [stat(d, "CPU", ["cpu/all/usage"], {"cpu/all/usage": "#a6e3a1"}, {"cpu/all/usage": "Load"}), stats, 48, 208, 224],
        [stat(d, "GPU", [GPU + "/usage"], gpuColors, gpuLabels), stats, 288, 208, 224],
        [stat(d, "RAM", ["memory/physical/usedPercent"], {"memory/physical/usedPercent": "#f5c2e7"},
            {"memory/physical/usedPercent": "Used"}), stats, 528, 208, 224],
        [stat(d, "Network", ["network/all/download", "network/all/upload"],
            {"network/all/download": "#89dceb", "network/all/upload": "#fab387"},
            {"network/all/download": "Down", "network/all/upload": "Up"}, true), stats, 768, 208, 224],
    ];
    var geo = "";
    place.forEach(function (p) { geo += "Applet-" + p[0].id + ":" + p[1] + "," + p[2] + "," + p[3] + "," + p[4] + ",0;"; });
    print("GEOMETRY " + d.id + " " + g.width + "x" + g.height + " " + geo + "\n");
});
