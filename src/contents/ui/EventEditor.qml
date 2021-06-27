// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.OverlaySheet {
    id: eventEditorSheet

    Item {
        EventWrapper {
            id: event
        }
    }

    signal added(int collectionId, EventWrapper event)
    signal edited(int collectionId, EventWrapper event)

    property bool editMode: false
    property bool validDates: eventStartDateCombo.validDate && (eventEndDateCombo.validDate || allDayCheckBox.checked)

    header: Kirigami.Heading {
        text: editMode ? i18n("Edit event") : i18n("Add event")
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            text: editMode ? i18n("Done") : i18n("Add")
            enabled: titleField.text && eventEditorSheet.validDates && calendarCombo.currentValue
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: eventEditorSheet.close()
        onAccepted: {
            if (editMode) {
                return
            } else {
                added(calendarCombo.currentValue, event);
            }
            eventEditorSheet.close();
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Kirigami.InlineMessage {
            id: invalidDateMessage

            Layout.fillWidth: true
            visible: !eventEditorSheet.validDates
            type: Kirigami.MessageType.Error
            text: i18n("Invalid dates provided.")
        }

        Kirigami.FormLayout {
            id: eventForm

            property date todayDate: new Date()

            QQC2.ComboBox {
                id: calendarCombo

                Kirigami.FormData.label: i18n("Calendar:")
                Layout.fillWidth: true

                property int selectedCollectionId: null

                textRole: "display"
                valueRole: "collectionId"

                // Should default to default collection
                // Should also only show *calendars*
                model: CalendarManager.collections
                delegate: Kirigami.BasicListItem {
                    leftPadding: Kirigami.Units.largeSpacing * kDescendantLevel
                    label: display
                    icon: decoration
                }
                popup.z: 1000
            }
            QQC2.TextField {
                id: titleField

                Kirigami.FormData.label: i18n("<b>Title</b>:")
                placeholderText: i18n("Required")
                text: event.summary
                onTextChanged: event.summary = text
            }
            QQC2.TextField {
                id: locationField

                Kirigami.FormData.label: i18n("Location:")
                placeholderText: i18n("Optional")
                text: event.location
                onTextChanged: event.location = text
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
            }

            QQC2.CheckBox {
                id: allDayCheckBox

                Kirigami.FormData.label: i18n("All day event:")
                onCheckedChanged: event.allDay = checked
            }
            RowLayout {
                id: eventStartLayout

                Kirigami.FormData.label: i18n("Start:")
                Layout.fillWidth: true

                QQC2.ComboBox {
                    id: eventStartDateCombo
                    Layout.fillWidth: true

                    editable: true
                    editText: event.eventStart.toLocaleDateString(Qt.locale(), Locale.NarrowFormat)

                    inputMethodHints: Qt.ImhDate

                    property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                    property bool validDate: !isNaN(dateFromText.getTime())

                    onEditTextChanged: {
                        // Set date from text here because it otherwise updates after this handler
                        dateFromText = Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                        let datePicker = eventStartDatePicker

                        if (validDate && activeFocus) {
                            datePicker.selectedDate = dateFromText;
                            datePicker.clickedDate = dateFromText;
                            event.eventEnd = new Date(dateFromText.setHours(timePicker.hours, timePicker.minutes));
                        }
                    }

                    popup: QQC2.Popup {
                        id: eventStartDatePopup

                        width: parent.width*2
                        height: Kirigami.Units.gridUnit * 18
                        z: 1000

                        DatePicker {
                            id: eventStartDatePicker

                            anchors.fill: parent
                            onDatePicked: {
                                eventStartDatePopup.close();
                                let hours = event.eventStart.getHours();
                                let minutes = event.eventStart.getMinutes();
                                event.eventStart = new Date(pickedDate.setHours(hours, minutes));
                            }
                        }
                    }
                }
                QQC2.ComboBox {
                    id: eventStartTimeCombo

                    Layout.fillWidth: true

                    editable: true
                    editText: event.eventStart.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                    enabled: !allDayCheckBox.checked
                    visible: !allDayCheckBox.checked

                    inputMethodHints: Qt.ImhTime
                    validator: RegularExpressionValidator {
                        regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
                    }

                    onEditTextChanged: {
                        let timePicker = eventStartTimePicker

                        if (acceptableInput && activeFocus) { // Need to check for activeFocus or on load the text gets reset to 00:00
                            timePicker.setToTimeFromString(editText);
                            event.eventStart = new Date(event.eventStart.setHours(timePicker.hours, timePicker.minutes));
                            editText = event.eventStart.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                        }
                    }

                    popup: QQC2.Popup {
                        id: eventStartTimePopup
                        width: parent.width
                        height: parent.width * 2
                        z: 1000

                        TimePicker {
                            id: eventStartTimePicker

                            onDone: {
                                eventStartTimePopup.close();
                                event.eventStart = new Date(event.eventStart.setHours(hours, minutes));

                            }

                            Component.onCompleted: {
                                hours = event.eventStart.getHours();
                                minutes = event.eventStart.getMinutes();
                            }
                        }
                    }
                }
            }
            RowLayout {
                id: eventEndLayout

                Kirigami.FormData.label: i18n("End:")
                Layout.fillWidth: true
                visible: !allDayCheckBox.checked

                QQC2.ComboBox {
                    id: eventEndDateCombo

                    Layout.fillWidth: true

                    property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                    property bool validDate: !isNaN(dateFromText.getTime())

                    editable: true
                    editText: event.eventEnd.toLocaleDateString(Qt.locale(), Locale.NarrowFormat)
                    enabled: !allDayCheckBox.checked

                    onEditTextChanged: {
                        // Set date from text here because it otherwise updates after this handler
                        dateFromText = Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat);
                        let datePicker = eventEndDatePicker;

                        if (validDate && activeFocus) {
                            datePicker.selectedDate = dateFromText;
                            datePicker.clickedDate = dateFromText;
                            let hours = event.eventEnd.getHours();
                            let minutes = event.eventEnd.getMinutes();
                            event.eventEnd = new Date(dateFromText.setHours(hours, minutes));
                        }
                    }

                    popup: QQC2.Popup {
                        id: eventEndDatePopup

                        width: parent.width*2
                        height: Kirigami.Units.gridUnit * 18
                        z: 1000

                        DatePicker {
                            id: eventEndDatePicker
                            anchors.fill: parent
                            onDatePicked: {
                                eventEndDatePopup.close();
                                let hours = event.eventEnd.getHours();
                                let minutes = event.eventEnd.getMinutes();
                                event.eventEnd = new Date(pickedDate.setHours(hours, minutes));
                            }
                        }
                    }
                }
                QQC2.ComboBox {
                    id: eventEndTimeCombo

                    Layout.fillWidth: true

                    editable: true
                    editText: event.eventEnd.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                    enabled: !allDayCheckBox.checked

                    inputMethodHints: Qt.ImhTime
                    validator: RegularExpressionValidator {
                        regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
                    }

                    onEditTextChanged: {
                        let timePicker = eventEndTimePicker

                        if (acceptableInput && activeFocus) {
                            timePicker.setToTimeFromString(editText);
                            event.eventEnd = new Date(event.eventEnd.setHours(timePicker.hours, timePicker.minutes));
                            editText = event.eventEnd.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                        }
                    }

                    popup: QQC2.Popup {
                        id: eventEndTimePopup

                        width: parent.width
                        height: parent.width * 2
                        z: 1000

                        TimePicker {
                            id: eventEndTimePicker

                            onDone: {
                                eventEndTimePopup.close();
                                event.eventEnd = new Date(event.eventEnd.setHours(hours, minutes));
                                eventEndTimeCombo.editText = event.eventEnd.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                            }

                            Component.onCompleted: {
                                hours = event.eventEnd.getHours();
                                minutes = event.eventEnd.getMinutes();
                            }
                        }
                    }
                }
            }

            QQC2.ComboBox {
                id: repeatComboBox

                Kirigami.FormData.label: i18n("Repeat:")
                Layout.fillWidth: true
                textRole: "display"
                valueRole: "interval"
                onCurrentValueChanged: if(currentValue >= 0) { event.setRegularRecurrence(currentValue); }
                model: [
                    {key: "never", display: i18n("Never"), interval: -1},
                    {key: "daily", display: i18n("Daily"), interval: event.recurrenceIntervals["Daily"]},
                    {key: "weekly", display: i18n("Weekly"), interval: event.recurrenceIntervals["Weekly"]},
                    {key: "monthly", display: i18n("Monthly"), interval: event.recurrenceIntervals["Monthly"]},
                    {key: "yearly", display: i18n("Yearly"), interval: event.recurrenceIntervals["Yearly"]},
                    {key: "custom", display: i18n("Custom"), interval: -1}
                ]
                popup.z: 1000
            }

            GridLayout {
                id: customRecurrenceLayout

                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                columns: 5
                visible: repeatComboBox.currentIndex > 0 // Not "Never" index

                function setOcurrence() {
                    event.setRegularRecurrence(recurScaleRuleCombobox.currentValue, recurFreqRuleSpinbox.value);

                    if(recurScaleRuleCombobox.currentValue === event.recurrenceIntervals["Weekly"]) {
                        weekdayCheckboxRepeater.setWeekdaysRepeat();
                    }
                }

                // Custom controls
                QQC2.Label {
                    visible: repeatComboBox.currentIndex === 5
                    Layout.columnSpan: 1
                    text: i18n("Every:")
                }
                QQC2.SpinBox {
                    id: recurFreqRuleSpinbox

                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    visible: repeatComboBox.currentIndex === 5
                    from: 1
                    onValueChanged: if(visible) { customRecurrenceLayout.setOcurrence(); }
                }
                QQC2.ComboBox {
                    id: recurScaleRuleCombobox

                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    visible: repeatComboBox.currentIndex === 5
                    textRole: recurFreqRuleSpinbox.value > 1 ? "displayPlural" : "displaySingular"
                    valueRole: "interval"
                    onCurrentValueChanged: if(visible) { customRecurrenceLayout.setOcurrence(); }

                    model: [
                        {key: "day", displaySingular: i18n("day"), displayPlural: i18n("days"), interval: event.recurrenceIntervals["Daily"]},
                        {key: "week", displaySingular: i18n("week"), displayPlural: i18n("weeks"), interval: event.recurrenceIntervals["Weekly"]},
                        {key: "month", displaySingular: i18n("month"), displayPlural: i18n("months"), interval: event.recurrenceIntervals["Monthly"]},
                        {key: "year", displaySingular: i18n("year"), displayPlural: i18n("years"), interval: event.recurrenceIntervals["Yearly"]},
                    ]
                    popup.z: 1000
                }

                // Custom controls specific to weekly
                GridLayout {
                    id: recurWeekdayRuleLayout

                    Layout.row: 1
                    Layout.column: 1
                    Layout.columnSpan: 4
                    columns: 7
                    visible: recurScaleRuleCombobox.currentIndex === 1 && repeatComboBox.currentIndex === 5 // "week"/"weeks" index

                    Repeater {
                        model: 7
                        delegate: QQC2.Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName(Qt.locale().firstDayOfWeek + index, Locale.ShortFormat)
                        }
                    }

                    Repeater {
                        id: weekdayCheckboxRepeater

                        property var checkboxes: []
                        function setWeekdaysRepeat() {
                            let selectedDays = new Array(7)
                            for(let checkbox of checkboxes) {
                                // C++ func takes 7 bit array
                                selectedDays[checkbox.dayNumber] = checkbox.checked
                            }
                            event.setWeekdaysRecurrence(selectedDays);
                        }

                        model: 7
                        delegate: QQC2.CheckBox {
                            Layout.alignment: Qt.AlignHCenter
                            // We make sure we get dayNumber per the day of the week number used by C++ Qt
                            property int dayNumber: Qt.locale().firstDayOfWeek + index > 7 ?
                                                    Qt.locale().firstDayOfWeek + index - 1 - 7 :
                                                    Qt.locale().firstDayOfWeek + index - 1
                            onClicked: weekdayCheckboxRepeater.setWeekdaysRepeat()
                            Component.onCompleted: weekdayCheckboxRepeater.checkboxes.push(this)
                        }
                    }
                }

                // Controls specific to monthly recurrence
                QQC2.Label {
                    Layout.columnSpan: 1
                    visible: recurScaleRuleCombobox.currentIndex === 2 && repeatComboBox.currentIndex === 5 // "month/months" index
                    text: i18n("On:")
                }

                QQC2.ButtonGroup {
                    buttons: monthlyRecurRadioColumn.children
                }

                ColumnLayout {
                    id: monthlyRecurRadioColumn

                    Layout.fillWidth: true
                    Layout.columnSpan: 4
                    visible: recurScaleRuleCombobox.currentIndex === 2 && repeatComboBox.currentIndex === 5 // "month/months" index

                    function numberToString(number) {
                        // The code in here was adapted from an article by Johnathan Wood, see:
                        // http://www.blackbeltcoder.com/Articles/strings/converting-numbers-to-ordinal-strings

                        let numSuffixes = [ "th",
                                            "st",
                                            "nd",
                                            "rd",
                                            "th",
                                            "th",
                                            "th",
                                            "th",
                                            "th",
                                            "th" ];

                        let i = (number % 100);
                        let j = (i > 10 && i < 20) ? 0 : (number % 10);
                        return i18n(number + numSuffixes[j]);
                    }

                    QQC2.RadioButton {
                        property int dateOfMonth: eventStartDateCombo.dateFromText.getDate()
                        text: i18nc("%1 is the day number of month", "the %1 of each month", parent.numberToString(dateOfMonth))
                        onClicked: customRecurrenceLayout.setOcurrence()
                    }
                    QQC2.RadioButton {
                        property int dayOfWeek: eventStartDateCombo.dateFromText.getDay() > 0 ?
                                                eventStartDateCombo.dateFromText.getDay() - 1 :
                                                7 // C++ Qt day of week index goes Mon-Sun, 0-7
                        property int weekOfMonth: Math.ceil((eventStartDateCombo.dateFromText.getDate() + 6 - eventStartDateCombo.dateFromText.getDay())/7);
                        property string dayOfWeekString: Qt.locale().dayName(eventStartDateCombo.dateFromText.getDay())

                        text: i18nc("the weekOfMonth dayOfWeekString of each month", "the %1 %2 of each month", parent.numberToString(weekOfMonth), dayOfWeekString)
                        onTextChanged: if(checked) { event.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek); }
                        onClicked: event.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek)
                    }
                }


                // Repeat end controls (visible on all recurrences)
                QQC2.Label {
                    Layout.columnSpan: 1
                    text: i18n("Ends:")
                }
                QQC2.ComboBox {
                    id: endRecurType

                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    model: [i18n("Never"), i18n("On"), i18n("After")]
                    popup.z: 1000
                }
                QQC2.ComboBox {
                    id: recurEndDateCombo

                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    visible: endRecurType.currentIndex == 1
                    editable: true
                    editText: recurEndDatePicker.clickedDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);

                    inputMethodHints: Qt.ImhDate

                    property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                    property bool validDate: !isNaN(dateFromText.getTime())

                    onDateFromTextChanged: {
                        const datePicker = recurEndDatePicker
                        if (validDate && activeFocus) {
                            datePicker.selectedDate = dateFromText;
                            datePicker.clickedDate = dateFromText;

                            if (visible) {
                                event.setRecurrenceEndDateTime(dateFromText);
                            }
                        }
                    }

                    popup: QQC2.Popup {
                        id: recurEndDatePopup

                        width: parent.width*2
                        height: Kirigami.Units.gridUnit * 18
                        z: 1000

                        DatePicker {
                            id: recurEndDatePicker
                            anchors.fill: parent
                            onDatePicked: recurEndDatePopup.close()
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    visible: endRecurType.currentIndex === 2
                    onVisibleChanged: event.setRecurrenceOcurrences(recurOcurrenceEndSpinbox.value)

                    QQC2.SpinBox {
                        id: recurOcurrenceEndSpinbox
                        Layout.fillWidth: true
                        from: 1
                        onValueChanged: event.setRecurrenceOcurrences(value)
                    }
                    QQC2.Label {
                        text: i18np("ocurrence", "ocurrences", recurOcurrenceEndSpinbox.value)
                    }
                }
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
            }

            QQC2.TextArea {
                id: descriptionTextArea

                Kirigami.FormData.label: i18n("Description:")
                Layout.fillWidth: true
                placeholderText: i18n("Optional")
                text: event.description
                onTextChanged: event.description = text
            }

            ColumnLayout {
                id: remindersColumn

                Kirigami.FormData.label: i18n("Reminder:")
                Layout.fillWidth: true

                function secondsToReminderLabel(seconds) { // Gives prettified time

                    function numAndUnit(secs) {
                        if(secs >= 2 * 24 * 60 * 60)
                            return Math.round(secs / (24*60*60)) + i18n(" days"); // 2 days +
                        else if (secs >= 1 * 24 * 60 * 60)
                            return "1 day";
                        else if (secs >= 2 * 60 * 60)
                            return i18n("%1 is 2 or mores", "%1 hours", Math.round(secs / (60*60))); // 2 hours +
                        else if (secs >= 1 * 60 * 60)
                            return "1 hour";
                        else
                            return Math.round(secs / 60) + i18n(" minutes");
                    }

                    if (seconds < 0) {
                        return numAndUnit(seconds * -1) + i18n(" before");
                    } else if (seconds < 0) {
                        return numAndUnit(seconds) + i18n(" after");
                    } else {
                        return i18n("On event start");
                    }
                }

                property var reminderCombos: []

                QQC2.Button {
                    id: remindersButton

                    text: i18n("Add reminder")
                    Layout.fillWidth: true

                    onClicked: event.remindersModel.addAlarm();
                }

                Repeater {
                    id: remindersRepeater

                    Layout.fillWidth: true

                    model: event.remindersModel
                    // All of the alarms are handled within the delegates.

                    delegate: RowLayout {
                        Layout.fillWidth: true

                        QQC2.ComboBox {
                            // There is also a chance here to add a feature for the user to pick reminder type.
                            Layout.fillWidth: true

                            property var selectedIndex: 0

                            displayText: remindersColumn.secondsToReminderLabel(startOffset)
                            //textRole: "DisplayNameRole"
                            onCurrentValueChanged: event.remindersModel.setData(event.remindersModel.index(index, 0),
                                                                                currentValue,
                                                                                event.remindersModel.dataroles["startOffset"])
                            onCountChanged: selectedIndex = currentIndex // Gets called *just* before modelChanged
                            onModelChanged: currentIndex = selectedIndex

                            model: [0, // We times by -1 to make times be before event
                                    -1 * 5 * 60, // 5 minutes
                                    -1 * 10 * 60,
                                    -1 * 15 * 60,
                                    -1 * 30 * 60,
                                    -1 * 45 * 60,
                                    -1 * 1 * 60 * 60, // 1 hour
                                    -1 * 2 * 60 * 60,
                                    -1 * 1 * 24 * 60 * 60, // 1 day
                                    -1 * 2 * 24 * 60 * 60,
                                    -1 * 5 * 24 * 60 * 60]
                                    // All these times are in seconds.
                            delegate: Kirigami.BasicListItem {
                                text: remindersColumn.secondsToReminderLabel(modelData)
                            }

                            popup.z: 1000
                        }

                        QQC2.Button {
                            icon.name: "edit-delete-remove"
                            onClicked: event.remindersModel.deleteAlarm(model.index);
                        }
                    }
                }
            }

            ColumnLayout {
                id: attendeesColumn

                Kirigami.FormData.label: i18n("Attendees:")
                Layout.fillWidth: true

                QQC2.Button {
                    id: attendeesButton
                    text: i18n("Add attendee")
                    Layout.fillWidth: true

                    onClicked: event.attendeesModel.addAttendee();
                }

                Repeater {
                    model: event.attendeesModel
                    // All of the alarms are handled within the delegates.

                    delegate: ColumnLayout {
                        Layout.leftMargin: Kirigami.Units.largeSpacing

                        RowLayout {
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Attendee " + String(index + 1))
                            }
                            QQC2.Button {
                                icon.name: "edit-delete-remove"
                                onClicked: event.attendeesModel.deleteAttendee(index);
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 5

                            QQC2.Label{
                                text: i18n("Name:")
                            }
                            QQC2.TextField {
                                Layout.fillWidth: true
                                Layout.columnSpan: 4
                                onTextChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                            text,
                                                                            event.attendeesModel.dataroles["name"])
                                Component.onCompleted: text = model.name
                            }

                            QQC2.Label {
                                text: i18n("Email:")
                            }
                            QQC2.TextField {
                                Layout.fillWidth: true
                                Layout.columnSpan: 4
                                //editText: Email
                                onTextChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                            text,
                                                                            event.attendeesModel.dataroles["email"])
                                Component.onCompleted: text = model.email
                            }
                            QQC2.Label {
                                text: i18n("Status:")
                            }
                            QQC2.ComboBox {
                                Layout.columnSpan: 2
                                model: event.attendeesModel.attendeeStatusModel
                                textRole: "display"
                                valueRole: "value"
                                currentIndex: status // role of parent
                                onCurrentValueChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                                    currentValue,
                                                                                    event.attendeesModel.dataroles["status"])

                                popup.z: 1000
                            }
                            QQC2.CheckBox {
                                Layout.columnSpan: 2
                                text: i18n("Request RSVP")
                                checked: model.rsvp
                                onCheckedChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                               checked,
                                                                               event.attendeesModel.dataroles["rsvp"])
                            }
                        }
                    }
                }
            }
        }
    }
}
