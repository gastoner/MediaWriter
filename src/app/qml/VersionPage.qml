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
import QtQuick.Layouts 6.2
import QtQml 6.2


Page {
    id: versionPage
    property int prevSource: 0
    property int prevIndex: 0
    
    ColumnLayout {
        anchors.fill: parent
        
        Heading {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Select Fedora Release")
            level: 5
        }
        
        ButtonGroup {
            id: radioGroup
        }
        
        ColumnLayout {
            id: radioColumn
            Layout.alignment: Qt.AlignTop
            
            Label {
                text: qsTr("Select from:")
            }
        
            RadioButton {
                checked: releases.filterSource == Units.Source.Product
                text: qsTr("Official Editions")
                onClicked: changeFilter(Units.Source.Product)
                ButtonGroup.group: radioGroup
            }
    
            RadioButton {
                checked: releases.filterSource == Units.Source.Emerging
                text: qsTr("Emerging Editions")
                onClicked: changeFilter(Units.Source.Emerging)
                ButtonGroup.group: radioGroup
            }
            
            RadioButton {
                checked: releases.filterSource == Units.Source.Spins
                text: qsTr("Spins")
                onClicked: changeFilter(Units.Source.Spins)
                ButtonGroup.group: radioGroup
            }
            
            RadioButton {
                checked: releases.filterSource == Units.Source.Labs
                text: qsTr("Labs")
                onClicked: changeFilter(Units.Source.Labs)
                ButtonGroup.group: radioGroup
            }
        
            ComboBox {
                id: selectFromComboBox
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: units.gridUnit / 2
                textRole: "name"
                valueRole: "sourceIndex"
                model: releases
                onCurrentValueChanged: updateSelectedIndex()

            }
        }
    }
    
    function changeFilter(filter) {
        releases.filterSource = filter
        if (releases.filterSource != prevSource) {
            prevSource = releases.filterSource
            selectFromComboBox.currentIndex = 0
        }
    }

    function updateSelectedIndex() {
        // Guard passing an invalid value we get when resetting
        // index while changing filter above
        if (selectFromComboBox.currentValue) {
            releases.selectedIndex = parseInt(selectFromComboBox.currentValue)
        }
    }

    StackView.onActivated: {
        prevButton.text = qsTr("Previous")
        nextButton.text = qsTr("Next")
    }

    function setNextPage() {
        mainWindow.selectedPage += 1
    }

    function setPreviousPage() {
        selectedPage -= 1
    }

    Keys.onPressed: (event)=> {
        switch (event.key) {
            case (Qt.Key_1):
                changeFilter(Units.Source.Product)
                break
            case (Qt.Key_2):
                changeFilter(Units.Source.Emerging)
                break
            case (Qt.Key_3):
                changeFilter(Units.Source.Spins)
                break
            case (Qt.Key_4):
                changeFilter(Units.Source.Labs)
                break
            case (Qt.Key_Return):
            case (Qt.Key_Enter):
                if (selectFromComboBox.down)
                    selectFromComboBox.popup.close()
                else
                    selectFromComboBox.popup.open()
                break
            case (Qt.Key_Up):
                if (selectFromComboBox.down)
                    if (releases.firstSource < releases.selectedIndex)
                        selectFromComboBox.currentIndex -= 1
                break
            case (Qt.Key_Down):
                if (selectFromComboBox.down)
                    if (selectFromComboBox.count > selectFromComboBox.currentIndex + 1)
                        selectFromComboBox.currentIndex += 1
                break
            case (Qt.Key_I):
                aboutDialog.show()
                break
            case (Qt.Key_Right):
            case (Qt.Key_N):
                setNextPage()
                break
            case (Qt.Key_Left):
            case (Qt.Key_P):
                setPreviousPage()
                break
        }
    }
}
