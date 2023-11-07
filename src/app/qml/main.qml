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

ApplicationWindow {
    id: mainWindow
    visible: true
    minimumWidth: Math.max(640, units.gridUnit * 32)
    maximumWidth: Math.max(640, units.gridUnit * 32)
    minimumHeight: Math.max(480, units.gridUnit * 25)
    maximumHeight: Math.max(480, units.gridUnit * 25)

    property int selectedPage: Units.Page.MainPage
    property int selectedVersion: Units.Source.Product
    property int selectedOption: Units.MainSelect.Download
    property QtObject lastRestoreable
    property bool eraseVariant: false
    property string fileName: ""

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        
        anchors.leftMargin: units.gridUnit * 3
        anchors.rightMargin: units.gridUnit * 3
        anchors.topMargin: units.gridUnit * 2
        anchors.bottomMargin: units.gridUnit * 2
    
        StackView {
            id: stackView
            initialItem: "MainPage.qml"
            focus: true
            
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: parent.width / 8
            Layout.rightMargin: parent.width / 8
            Layout.bottomMargin: units.gridUnit * 2
            
            pushEnter: Transition {
                XAnimator {
                    from: mainWindow.width
                    to: 0
                    duration: 250
                }
            }
            pushExit: Transition {
                XAnimator {
                    from: 0
                    to: -mainWindow.width
                    duration: 250
                }
            }
            popEnter: Transition {
              XAnimator {
                    from: -mainWindow.width
                    to: 0
                    duration: 250
                }
            }
            popExit: Transition {
                XAnimator {
                    from: 0
                    to: mainWindow.width
                    duration: 250
                }
            }
        }
        
        RowLayout {
            Layout.alignment: Qt.AlignBottom
            
            Button {
                id: prevButton
                visible: true
                text: getPrevButtonText()
            }
        
            Item {
                Layout.fillWidth: true
            }
            
            Button {
                id: nextButton
                visible: mainLayout.state != "downloadPage" 
                enabled: mainLayout.state != "drivePage" 
                text: getNextButtonText()
            }
        }
        
        states: [
            State {
                name: "mainPage"
                when: selectedPage == Units.Page.MainPage
                PropertyChanges { 
                    target: mainWindow
                    title: qsTr("Fedora Media Writer") 
                }
                //When comming back from restore page, after successfull restoring a USB drive
                PropertyChanges { 
                    target: prevButton
                    text: getPrevButtonText()
                    onClicked: setPreviousPage()
                }
                PropertyChanges { 
                    target: nextButton
                    visible: true
                    onClicked: setNextPage()
                }
                StateChangeScript {
                    script: {
                        //reset of source on versionPage
                        releases.filterSource = 0
                        if (stackView.depth > 1)  {
                            while (stackView.depth != 1) {
                                stackView.pop()
                            }
                        }
                    }
                }
            },
            State {
                name: "versionPage"
                when: selectedPage == Units.Page.VersionPage
                PropertyChanges { target: mainWindow; title: qsTr("Select Fedora Version") }
                PropertyChanges { target: nextButton; visible: true; onClicked: setNextPage() }
                PropertyChanges { target: prevButton; visible: true; onClicked: setPreviousPage() }
                StateChangeScript {
                    script: {
                        //state was pushing same page when returing from drivePage
                        if (stackView.depth <= 1)  
                            stackView.push("VersionPage.qml")
                    }
                }
            },
            State {
                name: "drivePage"
                when: selectedPage == Units.Page.DrivePage
                PropertyChanges { 
                    target: mainWindow
                    title: qsTr("Select Drive") 
                }
                PropertyChanges {
                    target: nextButton;
                    visible: true
                    onClicked: setNextPage()
                }
                PropertyChanges {
                    target: prevButton
                    visible: true
                    onClicked: setPreviousPage()
                }
                StateChangeScript { 
                    script: { 
                        stackView.push("DrivePage.qml") 
                        eraseVariant = false
                    }
                }
            },
            State {
                name: "downloadPage"
                when: selectedPage == Units.Page.DownloadPage
                PropertyChanges {  
                    target: mainWindow
                    title: releases.variant.statusString
                }
                StateChangeScript {
                    script: { stackView.push("DownloadPage.qml") }
                }
                PropertyChanges {
                    target: prevButton
                    visible: true
                    onClicked: setPreviousPage()
                }
                PropertyChanges {
                    target: nextButton
                    onClicked: setNextPage()
                }
            },
            State {
                name: "restorePage"
                when: selectedPage == Units.Page.RestorePage
                PropertyChanges { 
                    target: mainWindow
                    title: qsTr("Restore") 
                }
                PropertyChanges {
                    target: nextButton
                    visible: true
                    onClicked: setNextPage()
                }
                PropertyChanges {
                    target: prevButton
                    visible: true
                    onClicked: setPreviousPage()
                }
                StateChangeScript { 
                    script: { stackView.push("RestorePage.qml") }
                }
            }
        ]

        Keys.onPressed: (event)=> {
            switch (event.key) {
                case (Qt.Key_I):
                    if (selectedPage != Units.Page.DownloadPage)
                        aboutDialog.show()
                    break
                case (Qt.Key_Right):
                case (Qt.Key_N):
                    if (selectedOption == Units.MainSelect.Write && selectedPage == Units.Page.DrivePage) {
                        if (drives.length && releases.localFile.iso)
                            mainWindow.setNextPage()
                    } else
                        mainWindow.setNextPage()
                    break
                case (Qt.Key_Left):
                case (Qt.Key_P):
                    if (!(lastRestoreable && lastRestoreable.restoreStatus == Units.RestoreStatus.Restoring))
                        setPreviousPage()
                    break
                case (Qt.Key_Enter):
                case (Qt.Key_Return):
                    if (selectedPage == Units.Page.DownloadPage && releases.variant.status != Units.DownloadStatus.Finished)
                        cancelDialog.show()
                    break
            }
        }
    }
    
    Units {
        id: units
    }
    
    AboutDialog {
        id: aboutDialog
    }
    
    CancelDialog {
        id: cancelDialog
    }
    
    
    function getNextButtonText() {
        if (mainLayout.state == "restorePage") {
            if (lastRestoreable && lastRestoreable.restoreStatus == Units.RestoreStatus.Restored)
                return qsTr("Finish")
            return qsTr("Restore")
        } else if (mainLayout.state == "drivePage") {
            if (selectedOption == Units.MainSelect.Write || downloadManager.isDownloaded(releases.selected.version.variant.url))
                return qsTr("Write")
            if (Qt.platform.os === "windows" || Qt.platform.os === "osx") 
                return qsTr("Download && Write")
            return qsTr("Download & Write") 
        } else if (mainLayout.state == "downloadPage") {
            if (releases.variant.status === Units.DownloadStatus.Write_Verifying || releases.variant.status === Units.DownloadStatus.Writing || releases.variant.status === Units.DownloadStatus.Downloading || releases.variant.status === Units.DownloadStatus.Download_Verifying)
                return qsTr("Cancel")
            else if (releases.variant.status == Units.DownloadStatus.Ready)
                return qsTr("Write")
            else if (releases.variant.status === Units.DownloadStatus.Finished)
                return qsTr("Finish")
            else
                return qsTr("Retry")
        }
        return qsTr("Next")
    }
    
    function getPrevButtonText() {
        if (mainLayout.state == "mainPage") 
            return qsTr("About")
        else if (mainLayout.state == "downloadPage")
            return qsTr("Cancel")
        return qsTr("Previous")
    }

    function setNextPage() {
        if (selectedPage == Units.Page.MainPage) {
            if (selectedOption == Units.MainSelect.Write) {
                if (releases.localFile.iso)
                    releases.selectLocalFile(fileName)
                selectedPage = Units.Page.DrivePage
            } else if (selectedOption == Units.MainSelect.Restore && drives.lastRestoreable)
                selectedPage = Units.Page.RestorePage
            else if (selectedOption == Units.MainSelect.Download)
                selectedPage = Units.Page.VersionPage
        } else if (selectedPage == Units.Page.VersionPage) {
            selectedPage += 1
        } else if (selectedPage == Units.Page.DrivePage) {
            selectedPage = Units.Page.DownloadPage
            if (selectedOption != Units.MainSelect.Write)
                releases.variant.download()
            if (drives.length) {
                drives.selected.setImage(releases.variant)
                drives.selected.write(releases.variant)
            }
        } else if (selectedPage == Units.Page.DownloadPage) {
            if (releases.variant.status === Units.DownloadStatus.Finished) {
                drives.lastRestoreable = drives.selected
                drives.lastRestoreable.setRestoreStatus(Units.RestoreStatus.Contains_Live)
                releases.variant.resetStatus()
                downloadManager.cancel()
                selectedPage = Units.Page.MainPage
            } else if ((releases.variant.status === Units.DownloadStatus.Failed && drives.length) || releases.variant.status === Units.DownloadStatus.Failed_Download || (releases.variant.status === Units.DownloadStatus.Failed_Verification && drives.length) || releases.variant.status === Units.DownloadStatus.Ready) {
                if (selectedOption != Units.MainSelect.Write)
                    releases.variant.download()
                drives.selected.setImage(releases.variant)
                drives.selected.write(releases.variant)
            }
        } else {
            if (lastRestoreable && lastRestoreable.restoreStatus == Units.RestoreStatus.Restored)
                selectedPage = Units.Page.MainPage
            else
                drives.lastRestoreable.restore()
        }
    }

    function setPreviousPage() {
        if (selectedPage == Units.Page.MainPage)
            aboutDialog.show()
        else if (selectedPage == Units.Page.VersionPage)
            selectedPage -= 1
        else if (selectedPage == Units.Page.DrivePage) {
            if (selectedOption == Units.MainSelect.Write)
                selectedPage = Units.Page.MainPage
            else {
                selectedPage -= 1
                stackView.pop()
            }
        } else if (selectedPage == Units.Page.DownloadPage) {
            if (releases.variant.status === Units.DownloadStatus.Write_Verifying || releases.variant.status === Units.DownloadStatus.Writing || releases.variant.status === Units.DownloadStatus.Downloading || releases.variant.status === Units.DownloadStatus.Download_Verifying) {
                cancelDialog.show()
            } else {
                releases.variant.resetStatus()
                downloadManager.cancel()
                mainWindow.selectedPage = Units.Page.MainPage
            }
        } else
            selectedPage = Units.Page.MainPage
    }
}

