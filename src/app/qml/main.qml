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
            id: buttonRow
            Layout.alignment: Qt.AlignBottom
            
            Button {
                id: prevButton
                visible: true
                // text: getPrevButtonText()
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
                    // text: getPrevButtonText()
                    onClicked: stackView.currentItem.setPreviousPage()
                }
                PropertyChanges { 
                    target: nextButton
                    visible: true
                    onClicked: stackView.currentItem.setNextPage()
                }
                StateChangeScript {
                    script: {
                        //reset of source on versionPage
                        selectedOption = Units.MainSelect.Download
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
                PropertyChanges { target: nextButton; visible: true; onClicked: stackView.currentItem.setNextPage() }
                PropertyChanges { target: prevButton; visible: true; onClicked: stackView.currentItem.setPreviousPage() }
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
                    onClicked: stackView.currentItem.setNextPage()
                }
                PropertyChanges {
                    target: prevButton
                    visible: true
                    onClicked: stackView.currentItem.setPreviousPage()
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
                    onClicked: stackView.currentItem.setPreviousPage()
                }
                PropertyChanges {
                    target: nextButton
                    onClicked: stackView.currentItem.setNextPage()
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
                    onClicked: stackView.currentItem.setNextPage()
                }
                PropertyChanges {
                    target: prevButton
                    visible: true
                    onClicked: stackView.currentItem.setPreviousPage()
                }
                StateChangeScript { 
                    script: { stackView.push("RestorePage.qml") }
                }
            }
        ]
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
}

