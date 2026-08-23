import QtQuick 2.12

// Slideshow stage: two clipped layers, cross-fades between them.
// Effects (settings.transitionMode): 0 Fade, 1 Slide, 2 Zoom, 3 Wipe, 4 Random.
// Optional slow Ken Burns zoom on the visible layer with random pan origin.
Item {
    id: stage

    property int fadeDuration: 350
    property int activeLayer: 0
    readonly property bool kenBurns: settings.kenBurnsEnabled
    readonly property real kenScale: 1.06
    property int kenDurationMs: 9000
    property int effect: 0 // 0 Fade, 1 Slide, 2 Zoom, 3 Wipe, 4 Random

    readonly property int modeFade: 0
    readonly property int modeSlide: 1
    readonly property int modeZoom: 2
    readonly property int modeWipe: 3
    readonly property int modeRandom: 4

    readonly property int fitFillMode: settings.fitMode === 0 ? Image.PreserveAspectFit
                                         : settings.fitMode === 1 ? Image.PreserveAspectCrop
                                                                  : Image.Stretch

    property bool noAnim: false
    property var kenOrigins: [Item.Center, Item.TopLeft, Item.TopRight,
                              Item.BottomLeft, Item.BottomRight]

    // ------------------------------------------------------------------
    // Layer 0
    Item {
        id: wrap0
        x: 0
        y: 0
        width: stage.width
        height: stage.height
        clip: true
        z: stage.activeLayer === 0 ? 1 : 0

        Behavior on x { enabled: !stage.noAnim; NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on width { enabled: !stage.noAnim; NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: !stage.noAnim; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !stage.noAnim; NumberAnimation { duration: stage.fadeDuration; easing.type: Easing.InOutQuad } }

        Image {
            id: layer0
            x: 0
            y: 0
            width: wrap0.parent.width
            height: wrap0.parent.height
            fillMode: stage.fitFillMode
            asynchronous: true
            cache: true
            sourceSize.width: 800
            sourceSize.height: 480
            transformOrigin: Item.Center
            scale: (stage.activeLayer === 0 && stage.kenBurns) ? stage.kenScale : 1.0
            Behavior on scale {
                enabled: stage.kenBurns
                NumberAnimation { duration: stage.kenDurationMs; easing.type: Easing.Linear }
            }
        }
    }

    // ------------------------------------------------------------------
    // Layer 1
    Item {
        id: wrap1
        x: 0
        y: 0
        width: stage.width
        height: stage.height
        clip: true
        z: stage.activeLayer === 1 ? 1 : 0

        Behavior on x { enabled: !stage.noAnim; NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on width { enabled: !stage.noAnim; NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: !stage.noAnim; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !stage.noAnim; NumberAnimation { duration: stage.fadeDuration; easing.type: Easing.InOutQuad } }

        Image {
            id: layer1
            x: 0
            y: 0
            width: wrap1.parent.width
            height: wrap1.parent.height
            fillMode: stage.fitFillMode
            asynchronous: true
            cache: true
            sourceSize.width: 800
            sourceSize.height: 480
            transformOrigin: Item.Center
            scale: (stage.activeLayer === 1 && stage.kenBurns) ? stage.kenScale : 1.0
            Behavior on scale {
                enabled: stage.kenBurns
                NumberAnimation { duration: stage.kenDurationMs; easing.type: Easing.Linear }
            }
        }
    }

    Connections {
        target: browser
        function onCurrentIndexChanged() { stage.show(browser.currentFile) }
    }

    Component.onCompleted: stage.show(browser.currentFile)

    function show(file) {
        var source = file ? "file://" + file : ""
        var newWrap = stage.activeLayer === 0 ? wrap1 : wrap0
        var oldWrap = stage.activeLayer === 0 ? wrap0 : wrap1
        var newImg = stage.activeLayer === 0 ? layer1 : layer0

        // Neutral state for both wraps (no animation while resetting)
        stage.noAnim = true
        wrap0.x = 0;  wrap0.width = wrap0.parent.width; wrap0.scale = 1; wrap0.opacity = 1
        wrap1.x = 0;  wrap1.width = wrap1.parent.width; wrap1.scale = 1; wrap1.opacity = 1

        newImg.source = source
        newImg.transformOrigin = stage.kenOrigins[Math.floor(Math.random() * stage.kenOrigins.length)]

        // Resolve random effect per image
        var eff = stage.effect
        if (eff === stage.modeRandom)
            eff = Math.floor(Math.random() * 4)

        // Set pre-transition pose (animations off), then play to final pose
        if (eff === stage.modeSlide) {
            oldWrap.x = 0
            newWrap.x = newWrap.parent.width
        } else if (eff === stage.modeZoom) {
            newWrap.scale = 1.12
            newWrap.opacity = 0
            oldWrap.opacity = 1
        } else if (eff === stage.modeWipe) {
            newWrap.width = 0
            oldWrap.opacity = 1
        } else {
            newWrap.opacity = 0
            oldWrap.opacity = 1
        }

        stage.activeLayer = stage.activeLayer === 0 ? 1 : 0
        stage.noAnim = false

        if (eff === stage.modeSlide) {
            oldWrap.x = -oldWrap.width
            newWrap.x = 0
        } else if (eff === stage.modeZoom) {
            newWrap.scale = 1.0
            newWrap.opacity = 1
        } else if (eff === stage.modeWipe) {
            newWrap.width = newWrap.parent.width
            newWrap.opacity = 1
        } else {
            newWrap.opacity = 1
            oldWrap.opacity = 0
        }
    }
}