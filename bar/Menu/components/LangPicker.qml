import QtQuick
import QtQuick.Layouts
import "../.."
import "../../../"

Item {
    id: picker

    property string labelText: ""
    property string selectedCode: ""
    property bool includeAuto: false
    property bool dropdownOpen: false
    property var languages: []
    signal codeSelected(string code)
    signal toggled(bool open)

    implicitWidth: Theme.scaled(140)
    implicitHeight: picker.dropdownOpen ? pickerButton.height + Theme.scaled(6) + Math.min(Theme.scaled(260), pickerList.contentHeight + Theme.scaled(8)) : pickerButton.height
    height: implicitHeight

    function langName(code) {
        for (let i = 0; i < picker.languages.length; i++) {
            if (picker.languages[i].code === code) return picker.languages[i].name;
        }
        return code;
    }

    function filtered() {
        let langs = [];
        for (let i = 0; i < picker.languages.length; i++) {
            if (picker.languages[i].code === "auto" && !picker.includeAuto) continue;
            langs.push(picker.languages[i]);
        }
        return langs;
    }

    Rectangle {
        id: pickerButton
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.scaled(38)
        radius: Theme.bubbleRadiusSmall
        color: picker.dropdownOpen ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
        border.color: Theme.glassBorder
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(10)
            spacing: Theme.scaled(6)

            Text {
                text: picker.labelText
                color: Theme.accentColor
                font.pixelSize: Theme.scaled(9)
                font.weight: Font.Black
                font.letterSpacing: 1
            }
            Text {
                Layout.fillWidth: true
                text: picker.langName(picker.selectedCode)
                color: Theme.text
                font.pixelSize: Theme.scaled(11)
                font.weight: Font.Bold
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
            Text {
                text: picker.dropdownOpen ? "󰅀" : "󰅂"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(12)
                color: Theme.subtext0
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                picker.dropdownOpen = !picker.dropdownOpen;
                picker.toggled(picker.dropdownOpen);
            }
        }
    }

    Rectangle {
        id: pickerList
        visible: picker.dropdownOpen
        anchors.top: pickerButton.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Theme.scaled(6)
        height: Math.min(Theme.scaled(260), list.contentHeight + Theme.scaled(8))
        radius: Theme.bubbleRadiusSmall
        color: Theme.surfaceContainerHigh
        border.color: Theme.glassBorder

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: Theme.scaled(4)
            clip: true
            spacing: Theme.scaled(2)
            model: picker.filtered()
            delegate: Rectangle {
                width: list.width
                height: Theme.scaled(30)
                radius: Theme.bubbleRadiusSmall
                color: modelData.code === picker.selectedCode ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.25) : (langMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(8)
                    spacing: Theme.scaled(6)
                    Text {
                        visible: modelData.code === picker.selectedCode
                        text: "󰄱"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(11)
                        color: Theme.accentColor
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: modelData.code === picker.selectedCode ? Theme.accentColor : Theme.text
                        font.pixelSize: Theme.scaled(10)
                        font.weight: modelData.code === picker.selectedCode ? Font.Bold : Font.Normal
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: langMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        picker.selectedCode = modelData.code;
                        picker.codeSelected(modelData.code);
                        picker.dropdownOpen = false;
                        picker.toggled(false);
                    }
                }
            }
        }
    }
}
