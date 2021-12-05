/*
 * Fedora Media Writer
 * Copyright (C) 2021 Evžen Gasta <evzen.ml@seznam.cz>
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

Page {
    ColumnLayout {
        anchors.fill: parent
        spacing: units.gridUnit
        
        Heading {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Write Options")
            level: 5
        }
        
        ColumnLayout {
            id: architectureCol
            Heading {
                text: qsTr("Hardware Architecture")
            }
            
            ComboBox {
                textRole: "text"
                valueRole: "value"
                Layout.fillWidth: true
                model: [
                    { value: 64, text: "x84_64" },
                    { value: 32, text: "x84" }
                ]
            }
        }
        
        ColumnLayout {
            Heading {
                text: qsTr("USB Drive")
            }
            
            ComboBox {
                textRole: "text"
                Layout.fillWidth: true
                model: [ drive ]
                
                Connections {
                    target: drives
                }
                
            }
        }
        
        ColumnLayout {
            Layout.bottomMargin: units.gridUnit * 5
            
            Heading {
                text: qsTr("Download")
                level: 1
            }
        
            CheckBox {
                text: qsTr("Delete download adter writing")
            }
        }
    }
    
    states: [
        State {
            name: "ISOSelected"
            when: !units.selectedISO
            PropertyChanges { target: architectureCol; visible: true }
        },
        State {
            name: "ISONotSelected"
            when: units.selectedISO
            PropertyChanges { target: architectureCol; visible: false }
        }
    ]
}
