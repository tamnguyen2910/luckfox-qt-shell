// Shared JS helpers for Music Player

function formatTime(seconds) {
    if (!seconds || seconds < 0 || isNaN(seconds)) {
        return "0:00"
    }
    var mins = Math.floor(seconds / 60)
    var secs = Math.floor(seconds % 60)
    return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs
}

function trackTitle(path) {
    var t = path
    t = t.replace(/^.*\//, "")
    t = t.replace(/\.[^/.]+$/, "")
    t = t.replace(/^\d+[\s\-_\.]+/, "")
    return t
}
