import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    function slide(title, body) { return { t: title, b: body } }

    Slide {
        Rectangle { anchors.fill: parent; color: "#130B20" }
        Image { id: logo1; source: "logo.png"; width: 220; fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter; y: 40 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 330
               text: "Welcome to Lumora OS"; color: "#00F0FF"; font.pixelSize: 28; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 380; width: parent.width - 120
               horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
               text: "A calm, fast desktop in electric purple and neon cyan. Installing now."
               color: "#D8C8F5"; font.pixelSize: 16 }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#130B20" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 150
               text: "Find more apps"; color: "#B026FF"; font.pixelSize: 28; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 210; width: parent.width - 120
               horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
               text: "Open Software to install apps from Debian and Flathub."
               color: "#D8C8F5"; font.pixelSize: 16 }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#130B20" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 150
               text: "Stay up to date"; color: "#00F0FF"; font.pixelSize: 28; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 210; width: parent.width - 120
               horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
               text: "Security updates install automatically. Check anytime in Lumora Hub."
               color: "#D8C8F5"; font.pixelSize: 16 }
    }

    function onActivate() { }
    function onLeave() { }
}
