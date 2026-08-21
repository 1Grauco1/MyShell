pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../.."
import "../../../"
import "../../../services"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property var languages: [
        { code: "auto", name: "Auto Detect" },
        { code: "en", name: "English" },
        { code: "pt", name: "Portuguese" },
        { code: "es", name: "Spanish" },
        { code: "fr", name: "French" },
        { code: "de", name: "German" },
        { code: "it", name: "Italian" },
        { code: "nl", name: "Dutch" },
        { code: "ru", name: "Russian" },
        { code: "uk", name: "Ukrainian" },
        { code: "ja", name: "Japanese" },
        { code: "zh-CN", name: "Chinese (Simplified)" },
        { code: "zh-TW", name: "Chinese (Traditional)" },
        { code: "ko", name: "Korean" },
        { code: "ar", name: "Arabic" },
        { code: "hi", name: "Hindi" },
        { code: "tr", name: "Turkish" },
        { code: "pl", name: "Polish" },
        { code: "sv", name: "Swedish" },
        { code: "no", name: "Norwegian" },
        { code: "da", name: "Danish" },
        { code: "fi", name: "Finnish" },
        { code: "el", name: "Greek" },
        { code: "cs", name: "Czech" },
        { code: "th", name: "Thai" },
        { code: "vi", name: "Vietnamese" },
        { code: "id", name: "Indonesian" },
        { code: "he", name: "Hebrew" },
        { code: "fa", name: "Persian" }
    ]

    property string sourceCode: "auto"
    property string targetCode: "en"
    property bool copied: false

    function langName(code) {
        for (let i = 0; i < root.languages.length; i++) {
            if (root.languages[i].code === code) return root.languages[i].name;
        }
        return code;
    }

    function swapLangs() {
        if (root.sourceCode === "auto") return;
        let tmp = root.sourceCode;
        root.sourceCode = root.targetCode;
        root.targetCode = tmp;
        let txt = sourceEdit.text;
        sourceEdit.text = resultEdit.text;
        resultEdit.text = txt;
        TranslateService.result = null;
    }

    function doTranslate() {
        let text = sourceEdit.text;
        if (!text || text.trim() === "") return;
        TranslateService.translate(root.sourceCode, root.targetCode, text);
    }

    function copyResult() {
        if (!TranslateService.result || !TranslateService.result.translatedText) return;
        TranslateService.copyText(TranslateService.result.translatedText);
        root.copied = true;
        copyTimer.restart();
    }

    Timer {
        id: copyTimer
        interval: 1200
        repeat: false
        onTriggered: root.copied = false
    }

    Shortcut { sequence: "Ctrl+Return"; onActivated: root.doTranslate() }
    Shortcut { sequence: "Ctrl+Enter"; onActivated: root.doTranslate() }

    function handleKeys(event) {
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
            root.doTranslate();
            event.accepted = true;
        } else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
            sourceEdit.forceActiveFocus();
            sourceEdit.selectAll();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        radius: Theme.cardRadius
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(16)
            spacing: Theme.scaled(10)

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(8)
                Text {
                    text: "󰊿"
                    font.family: Theme.iconFont
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(16)
                }
                Text {
                    text: "TRANSLATE"
                    color: Colors.on_surface_variant
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Black
                    font.letterSpacing: 1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: TranslateService.translating ? "Translating..." : (TranslateService.result?.detectedLang && root.sourceCode === "auto" ? "Detected: " + root.langName(TranslateService.result.detectedLang) : "")
                    color: Colors.on_surface_variant
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Bold
                    opacity: (TranslateService.translating || (TranslateService.result?.detectedLang && root.sourceCode === "auto")) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                }
            }

            // --- SOURCE TEXT ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.surfaceContainer
                radius: Theme.bubbleRadiusMedium
                border.color: Theme.glassBorder

                TextArea {
                    id: sourceEdit
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(10)
                    background: null
                    padding: 0
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    color: Colors.on_background
                    font.pixelSize: Theme.scaled(12)
                    placeholderText: "Type or paste text to translate..."
                    placeholderTextColor: Colors.on_surface_variant
                    focus: true
                }
            }

            // --- LANGUAGE PICKERS + SWAP ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(10)

                LangPicker {
                    id: sourcePicker
                    Layout.fillWidth: true
                    labelText: "FROM"
                    selectedCode: root.sourceCode
                    includeAuto: true
                    onCodeSelected: (code) => { root.sourceCode = code }
                    onToggled: (open) => { if (open) targetPicker.dropdownOpen = false }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: Theme.scaled(34)
                    height: Theme.scaled(34)
                    radius: width / 2
                    color: swapMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: Theme.glassBorder
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰚦"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: Colors.on_background
                    }
                    MouseArea {
                        id: swapMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.swapLangs()
                    }
                }

                LangPicker {
                    id: targetPicker
                    Layout.fillWidth: true
                    labelText: "TO"
                    selectedCode: root.targetCode
                    includeAuto: false
                    onCodeSelected: (code) => { root.targetCode = code }
                    onToggled: (open) => { if (open) sourcePicker.dropdownOpen = false }
                }
            }

            // --- TRANSLATE BUTTON ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(38)
                radius: Theme.bubbleRadiusPill
                color: Theme.accentColor
                opacity: (TranslateService.translating || sourceEdit.text.trim() === "") ? 0.6 : 1.0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.scaled(8)
                    Text {
                        visible: TranslateService.translating
                        text: "󰝳"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: Colors.on_primary
                        RotationAnimation on rotation {
                            from: 0; to: 360
                            duration: 800
                            loops: Animation.Infinite
                            running: TranslateService.translating
                        }
                    }
                    Text {
                        text: TranslateService.translating ? "TRANSLATING..." : "TRANSLATE"
                        color: Colors.on_primary
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.Black
                        font.letterSpacing: 1
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.doTranslate()
                }
            }

            // --- RESULT ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.surfaceContainer
                radius: Theme.bubbleRadiusMedium
                border.color: Theme.glassBorder

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(10)
                    spacing: Theme.scaled(6)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(8)
                        Text {
                            text: "󰙣"
                            font.family: Theme.iconFont
                            color: Theme.accentColor
                            font.pixelSize: Theme.scaled(14)
                        }
                        Text {
                            text: "RESULT"
                            color: Colors.on_surface_variant
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.Black
                            font.letterSpacing: 1
                        }
                        Item { Layout.fillWidth: true }

                        Text {
                            text: TranslateService.result?.translatedText ? root.langName(root.targetCode) : ""
                            color: Colors.on_surface_variant
                            font.pixelSize: Theme.scaled(9)
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            width: Theme.scaled(28)
                            height: Theme.scaled(28)
                            radius: width / 2
                            color: copyMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                            visible: !!TranslateService.result?.translatedText
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: root.copied ? "󰄱" : "󰅌"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(13)
                                color: root.copied ? Theme.powerGreen : Colors.on_background
                            }
                            MouseArea {
                                id: copyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.copyResult()
                            }
                        }
                    }

                    TextArea {
                        id: resultEdit
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        background: null
                        padding: 0
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        readOnly: true
                        color: Colors.on_background
                        font.pixelSize: Theme.scaled(13)
                        font.weight: Font.Medium
                        text: TranslateService.result?.translatedText || ""
                        placeholderText: "Translation will appear here..."
                        placeholderTextColor: Colors.on_surface_variant
                    }
                }
            }
        }
    }
}
