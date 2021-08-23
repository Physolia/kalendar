// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import org.kde.kalendar 1.0

Kirigami.ScrollablePage {
    title: i18n("Views")
    Kirigami.FormLayout {
        Kirigami.Heading {
            level: 3
            Kirigami.FormData.isSection: true
            text: i18n("Month view settings")
        }
        Controls.ButtonGroup {
            buttons: weekdayLabelAlignmentButtonColumn.children
            exclusive: true
            onClicked: {
                Config.weekdayLabelAlignment = button.value;
                Config.save();
            }
        }
        Column {
            id: weekdayLabelAlignmentButtonColumn
            Kirigami.FormData.label: i18n("Weekday label alignment:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Controls.RadioButton {
                property int value: 0 // HACK: Ideally should use config enum
                text: i18n("Left")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
            }
            Controls.RadioButton {
                property int value: 1
                text: i18n("Center")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
            }
            Controls.RadioButton {
                property int value: 2
                text: i18n("Right")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
            }
        }
        Controls.ButtonGroup {
            buttons: weekdayLabelLengthButtonColumn.children
            exclusive: true
            onClicked: {
                Config.weekdayLabelLength = button.value;
                Config.save();
            }
        }
        Column {
            id: weekdayLabelLengthButtonColumn
            Kirigami.FormData.label: i18n("Weekday label length:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Controls.RadioButton {
                property int value: 0 // HACK: Ideally should use config enum
                text: i18n("Full name (Monday)")
                enabled: !Config.isWeekdayLabelLengthImmutable
                checked: Config.weekdayLabelLength === value
            }
            Controls.RadioButton {
                property int value: 1
                text: i18n("Abbreviated (Mon)")
                enabled: !Config.isWeekdayLabelLengthImmutable
                checked: Config.weekdayLabelLength === value
            }
            Controls.RadioButton {
                property int value: 2
                text: i18n("Letter only (M)")
                enabled: !Config.isWeekdayLabelLengthImmutable
                checked: Config.weekdayLabelLength === value
            }
        }
        Controls.CheckBox {
            text: i18n("Show week numbers")
            checked: Config.showWeekNumbers
            enabled: !Config.isShowWeekNumbersImmutable
            onClicked: {
                Config.showWeekNumbers = !Config.showWeekNumbers;
                Config.save();
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Schedule view settings")
        }
        Column {
            Kirigami.FormData.label: i18n("Headers:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Controls.CheckBox {
                text: i18n("Show month header")
                checked: Config.showMonthHeader
                enabled: !Config.isShowMonthHeaderImmutable
                onClicked: {
                    Config.showMonthHeader = !Config.showMonthHeader;
                    Config.save();
                }
            }
            Controls.CheckBox {
                text: i18n("Show week headers")
                checked: Config.showWeekHeaders
                enabled: !Config.isShowWeekHeadersImmutable
                onClicked: {
                    Config.showWeekHeaders = !Config.showWeekHeaders;
                    Config.save();
                }
            }
        }
    }
}
