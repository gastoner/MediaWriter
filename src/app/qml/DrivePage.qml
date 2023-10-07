/*
 * Fedora Media Writer
 * Copyright (C) 2021-2022 Evžen Gasta <evzen.ml@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Window 6.2
import QtQuick.Layouts 6.2
import QtQml 6.2
import QtQuick.Dialogs 6.2

Page {
    id: drivePage
    
    ColumnLayout {
        anchors.fill: parent
        spacing: units.gridUnit
        
        Heading {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Write Options")
            level: 5
        }
        
        ColumnLayout {
            id: versionCol
            visible: selectedOption != Units.MainSelect.Write
            
            Heading {
                text: qsTr("Version")
            }
            
            ComboBox {
                id: versionCombo
                Layout.fillWidth: true
                model: releases.selected.versions
                textRole: "name"
                onCurrentIndexChanged: releases.selected.versionIndex = currentIndex
                Component.onCompleted: {
                    if (releases.selected.version.status != Units.Status.FINAL && releases.selected.versions.length > 1) {
                        currentIndex++
                    }
                }
            }
        }
        
        ColumnLayout {
            id: architectureCol
            visible: selectedOption != Units.MainSelect.Write
            
            Heading {
                text: qsTr("Hardware Architecture")
            }
            
            ComboBox {
                id: hwArchCombo
                Layout.fillWidth: true
                model: releases.selected.version.variants
                textRole: "name"
                onCurrentIndexChanged: releases.selected.version.variantIndex = currentIndex
            }
        }
        
        ColumnLayout {
            id: selectFileColumn
            visible: selectedOption == Units.MainSelect.Write
            
            Heading {
                text: qsTr("Selected file")
            }
            
            RowLayout {
                id: fileCol
                
                Label {
                    text: releases.localFile.iso ? (String)(releases.localFile.iso).split("/").slice(-1)[0] : ("<font color=\"gray\">" + qsTr("None") + "</font>")
                    Layout.fillWidth: true
                    elide: Label.ElideRight
                }
                
                Button {
                    id: selectFileButton
                    Layout.alignment: Qt.AlignRight
                    text: qsTr("Select...")
                    onClicked: {
                        if (portalFileDialog.isAvailable)
                            portalFileDialog.open()
                        else
                            fileDialog.open()
                    }

                    Connections {
                        target: portalFileDialog
                        function onFileSelected(fileName) {
                            releases.selectLocalFile(fileName)
                        }
                    }
                    
                    FileDialog {
                        id: fileDialog
                        nameFilters: [ qsTr("Image files") + " (*.iso *.raw *.xz)", qsTr("All files (*)")]
                        onAccepted: {
                            releases.selectLocalFile(currentFile)
                        }
                    }
                }
            }
        }
        
        ColumnLayout {
            Heading {
                text: qsTr("USB Drive")
            }
            
            ComboBox {
                id: driveCombo
                Layout.fillWidth: true
                model: drives
                enabled: !(currentIndex === -1 || !currentText)
                displayText: currentIndex === -1 || !currentText ? qsTr("There are no portable drives connected") : currentText
                textRole: "display"
                
                Binding on currentIndex {
                    when: drives
                    value: drives.selectedIndex
                }
                Binding {
                    target: drives
                    property: "selectedIndex"
                    value: driveCombo.currentIndex
                }
            }
        }
        
        ColumnLayout {
            visible: selectedOption != Units.MainSelect.Write
            Layout.bottomMargin: units.gridUnit * 5
            
            Heading {
                text: qsTr("Download")
                level: 1
            }
        
            CheckBox {
                id: deleteCheck
                text: qsTr("Delete download after writing")
                onCheckedChanged: mainWindow.eraseVariant = !mainWindow.eraseVariant
            }
        }
        
        Item {
            visible: selectedOption == Units.MainSelect.Write
            Layout.fillHeight: true
        }
    }
    
    states: [
        State {
            name: "Downloading"
            when: selectedOption != Units.MainSelect.Write && selectedPage == Units.Page.DrivePage
            PropertyChanges { target: nextButton; enabled: true }
            StateChangeScript { script: releases.setSelectedVariantIndex = 0 }
        },
        State {
            name: "WritingISO"
            when: selectedOption == Units.MainSelect.Write && selectedPage == Units.Page.DrivePage
            PropertyChanges { target: nextButton; enabled: driveCombo.enabled && releases.localFile.iso }
        }
    ]

    Keys.onPressed: (event)=> {
        if (drivePage.state == "Downloading") {
            switch (event.key) {
                case (Qt.Key_1):
                    closePopups()
                    if (!versionCombo.down)
                        versionCombo.popup.open()
                    break
                case (Qt.Key_2):
                    closePopups()
                    if (!hwArchCombo.down)
                        hwArchCombo.popup.open()
                    break
                case (Qt.Key_3):
                    closePopups()
                    if (!driveCombo.down && driveCombo.count)
                        driveCombo.popup.open()
                    break
                case (Qt.Key_D):
                case (Qt.Key_4):
                    deleteCheck.checked = !deleteCheck.checked
                    break
                case (Qt.Key_Return):
                case (Qt.Key_Enter):
                    closePopups()
                    break
                case (Qt.Key_Up):
                    if (versionCombo.down && versionCombo.currentIndex > 0)
                        versionCombo.currentIndex -= 1
                    else if (hwArchCombo.down && hwArchCombo.currentIndex > 0)
                        hwArchCombo.currentIndex -= 1
                    else if (driveCombo.down && driveCombo.currentIndex > 0)
                        driveCombo.currentIndex -= 1
                    break
                case (Qt.Key_Down):
                    if (versionCombo.down && versionCombo.currentIndex < versionCombo.count - 1)
                        versionCombo.currentIndex += 1
                    else if (hwArchCombo.down && hwArchCombo.currentIndex < hwArchCombo.count - 1)
                        hwArchCombo.currentIndex += 1
                    else if (driveCombo.down && driveCombo.currentIndex < driveCombo.count - 1)
                        driveCombo.currentIndex += 1
                    break
            }
        } else {
            switch (event.key) {
                case (Qt.Key_1):
                    if (portalFileDialog.isAvailable)
                        portalFileDialog.open()
                    else
                        fileDialog.open()
                    break
                case (Qt.Key_2):
                    driveCombo.focus = true
                    break
            }
        }
    }

    function closePopups() {
        versionCombo.popup.close()
        hwArchCombo.popup.close()
        driveCombo.popup.close()
    }
}
