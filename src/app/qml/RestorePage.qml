/*
 * Fedora Media Writer
 * Copyright (C) 2024 Jan Grulich <jgrulich@redhat.com>
 * Copyright (C) 2021-2022 Evžen Gasta <evzen.ml@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 6.6
import QtQuick.Controls 6.6 as QQC2
import QtQuick.Layouts 6.6

Page {  
    id: restorePage

    text: qsTr("Restore Drive <b>%1</b>").arg(lastRestoreable.name)
    textLevel: 1

    QQC2.Label {
        id: warningText
        visible: lastRestoreable.restoreStatus == Units.RestoreStatus.Contains_Live
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        text: qsTr("<p align=\"justify\"> To reclaim all space available on the drive, it has to be restored to its factory settings. The live system and all saved data will be deleted.</p> <p align=\"justify\"> You don't need to restore the drive if you want to write another live system to it.</p> <p align=\"justify\"> Do you want to restore it to factory settings? </p>" )
        textFormat: Text.RichText
        wrapMode: QQC2.Label.Wrap
    }

    // Restore Options Section
    ColumnLayout {
        visible: lastRestoreable.restoreStatus == Units.RestoreStatus.Contains_Live
        Layout.fillWidth: true
        spacing: units.gridUnit / 2

        // Partition Table Selection
        ColumnLayout {
            Layout.fillWidth: true
            spacing: units.gridUnit / 4

            QQC2.Label {
                text: qsTr("Partition Table")
                font.bold: true
            }

            QQC2.ComboBox {
                id: partitionTableCombo
                Layout.fillWidth: true
                model: ListModel {
                    ListElement { text: "GPT (UEFI, recommended)"; value: "gpt" }
                    ListElement { text: "MBR (Legacy BIOS)"; value: "dos" }
                }
                textRole: "text"
                currentIndex: lastRestoreable.partitionTable === "dos" ? 1 : 0
                onCurrentIndexChanged: {
                    if (lastRestoreable)
                        lastRestoreable.partitionTable = model.get(currentIndex).value
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.italic: true
                font.pointSize: Qt.application.font.pointSize * 0.9
                opacity: 0.7
                text: partitionTableCombo.currentIndex === 0
                    ? qsTr("GPT supports drives larger than 2TB and is required for UEFI boot")
                    : qsTr("MBR is required for legacy BIOS systems and some older devices")
            }
        }

        // Filesystem Selection
        ColumnLayout {
            Layout.fillWidth: true
            spacing: units.gridUnit / 4

            QQC2.Label {
                text: qsTr("Filesystem")
                font.bold: true
            }

            QQC2.ComboBox {
                id: filesystemCombo
                Layout.fillWidth: true
                model: lastRestoreable ? lastRestoreable.availableFilesystems : []
                
                // Find the index matching the current filesystem (case-insensitive)
                function findFilesystemIndex() {
                    if (!lastRestoreable || !model) return 0
                    var currentFs = lastRestoreable.filesystem.toLowerCase()
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].toLowerCase() === currentFs) {
                            return i
                        }
                    }
                    return 0
                }
                
                Component.onCompleted: {
                    currentIndex = findFilesystemIndex()
                }
                
                onActivated: function(index) {
                    if (lastRestoreable && model[index]) {
                        lastRestoreable.filesystem = model[index].toLowerCase()
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.italic: true
                font.pointSize: Qt.application.font.pointSize * 0.9
                opacity: 0.7
                text: {
                    if (!filesystemCombo.currentText) return ""
                    var fs = filesystemCombo.currentText.toLowerCase()
                    if (fs === "exfat")
                        return qsTr("exFAT works on Windows, Mac, and Linux. Supports large files.")
                    else if (fs === "fat32" || fs === "vfat")
                        return qsTr("FAT32 has maximum compatibility but limits files to 4GB.")
                    else if (fs === "ntfs")
                        return qsTr("NTFS is the Windows native filesystem. Read-only on some systems.")
                    else if (fs === "ext4")
                        return qsTr("ext4 is the standard Linux filesystem with journaling.")
                    else if (fs === "ext3" || fs === "ext2")
                        return qsTr("ext2/3 are older Linux filesystems.")
                    else if (fs === "btrfs")
                        return qsTr("Btrfs supports snapshots and compression. Linux only.")
                    else if (fs === "xfs")
                        return qsTr("XFS is optimized for large files and high performance.")
                    else if (fs === "hfs+")
                        return qsTr("HFS+ is the macOS Extended filesystem.")
                    else if (fs === "apfs")
                        return qsTr("APFS is the modern Apple filesystem.")
                    return ""
                }
            }
        }

        // Volume Label
        ColumnLayout {
            Layout.fillWidth: true
            spacing: units.gridUnit / 4

            QQC2.Label {
                text: qsTr("Volume Label")
                font.bold: true
            }

            QQC2.TextField {
                id: labelField
                Layout.fillWidth: true
                placeholderText: qsTr("Enter label (optional)")
                text: lastRestoreable ? lastRestoreable.filesystemLabel : ""
                maximumLength: {
                    if (!filesystemCombo.currentText) return 32
                    var fs = filesystemCombo.currentText.toLowerCase()
                    if (fs === "vfat" || fs === "fat32" || fs === "exfat")
                        return 11
                    else if (fs === "ntfs")
                        return 32
                    else if (fs.startsWith("ext"))
                        return 16
                    return 32
                }
                validator: RegularExpressionValidator {
                    regularExpression: /[A-Za-z0-9_\-]*/
                }
                onTextChanged: {
                    if (lastRestoreable)
                        lastRestoreable.filesystemLabel = text.toUpperCase()
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.italic: true
                font.pointSize: Qt.application.font.pointSize * 0.9
                opacity: 0.7
                text: qsTr("The label will be displayed when the drive is mounted")
            }
        }
    }

    ColumnLayout {
        id: progress
        visible: lastRestoreable.restoreStatus == Units.RestoreStatus.Restoring

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: QQC2.Label.AlignHCenter
            wrapMode: QQC2.Label.Wrap
            text: qsTr("<p align=\"justify\">Please wait while Fedora Media Writer restores your portable drive.</p>")
        }

        QQC2.ProgressBar {
            id: progressIndicator
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            indeterminate: true
        }
    }

    QQC2.Label {
        id: restoredText
        visible: lastRestoreable.restoreStatus == Units.RestoreStatus.Restored
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        text: qsTr("Your drive was successfully restored!")
        wrapMode: QQC2.Label.Wrap
    }

    QQC2.Label {
        id: errorText
        visible: lastRestoreable.restoreStatus == Units.RestoreStatus.Restore_Error
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        text: qsTr("Unfortunately, an error occurred during the process. Please try restoring the drive using your system tools.")
        wrapMode: QQC2.Label.Wrap
    }
    
    Component.onCompleted: {
        lastRestoreable = drives.lastRestoreable
    }
    
    states: [
        State {
            name: "restored"
            when: lastRestoreable.restoreStatus == Units.RestoreStatus.Restored
            PropertyChanges {
                target: mainWindow;
                title: qsTr("Restoring finished")
            }
            StateChangeScript {
                script: drives.lastRestoreable = null
            }
        }
    ]

    previousButtonEnabled: lastRestoreable.restoreStatus != Units.RestoreStatus.Restored &&
                           lastRestoreable.restoreStatus != Units.RestoreStatus.Restoring
    previousButtonVisible: previousButtonEnabled
    onPreviousButtonClicked: {
        selectedPage = Units.Page.MainPage
    }

    nextButtonEnabled: lastRestoreable.restoreStatus == Units.RestoreStatus.Restored ||
                       lastRestoreable.restoreStatus == Units.RestoreStatus.Contains_Live
    nextButtonVisible: lastRestoreable.restoreStatus != Units.RestoreStatus.Restoring
    nextButtonText: lastRestoreable.restoreStatus == Units.RestoreStatus.Restored ? qsTr("Finish") : qsTr("Restore")
    onNextButtonClicked: {
        if (lastRestoreable.restoreStatus == Units.RestoreStatus.Restored)
            selectedPage = Units.Page.MainPage
        else
            drives.lastRestoreable.restore()
    }

}
