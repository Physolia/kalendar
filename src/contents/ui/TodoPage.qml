// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4 as QQC1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.Page {
    id: root
    title: i18n("Tasks")

    signal addTodo(int collectionId)
    signal viewTodo(var todoData, var collectionData)
    signal editTodo(var todoPtr, int collectionId)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal completeTodo(var todoPtr)
    signal addSubTodo(var parentWrapper)

    property int filterCollectionId
    property var filterCollectionDetails: filterCollectionId && filterCollectionId >= 0 ?
        Kalendar.CalendarManager.getCollectionDetails(filterCollectionId) : null
    property string filterCategoryString

    property int sortBy
    property bool ascendingOrder: false
    readonly property color standardTextColor: Kirigami.Theme.textColor
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)
    readonly property alias completedSheet: completedSheet

    Component.onCompleted: sortBy = Kalendar.TodoSortFilterProxyModel.EndTimeColumn // Otherwise crashes...

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        main: Kirigami.Action {
            text: i18n("Create")
            icon.name: "list-add"
            onTriggered: root.addTodo(filterCollectionId);
        }
        left: Kirigami.Action {
            text: i18n("Sort")
            icon.name: "view-sort"

            KActionFromAction {
                kalendarAction: "todoview_sort_by_due_date"
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.EndTimeColumn
                onCheckedChanged: __action.checked = checked // Needed for the actions in the menu bars to be checked on load
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_by_priority"
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.PriorityIntColumn
                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_alphabetically"
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.SummaryColumn
                onCheckedChanged: __action.checked = checked
            }

            Kirigami.Action { separator: true }

            KActionFromAction {
                kalendarAction: "todoview_order_ascending"
                checked: root.ascendingOrder
                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                kalendarAction: "todoview_order_descending"
                checked: !root.ascendingOrder
                onCheckedChanged: __action.checked = checked
            }
        }
        right: KActionFromAction {
            kalendarAction: "todoview_show_completed"
            text: i18n("Show Completed")
        }

    }

    Kirigami.OverlaySheet {
        id: completedSheet

        title: root.filterCollectionDetails && root.filterCollectionId > -1 ?
            i18n("Completed Tasks in %1", root.filterCollectionDetails.displayName) : i18n("Completed Tasks")
        showCloseButton: true

        property var retainedTodoData
        property var retainedCollectionData

        contentItem: Loader {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 30
            height: applicationWindow().height * 0.8
            active: completedSheet.sheetOpen
            sourceComponent: QQC2.ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                TodoTreeView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    filterCollectionId: root.filterCollectionId
                    filterCollectionDetails: root.filterCollectionDetails
                    filterCategoryString: root.filterCategoryString

                    showCompleted: Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly
                    sortBy: root.sortBy
                    ascendingOrder: root.ascendingOrder
                    onAddTodo: {
                        root.addTodo(collectionId)
                        completedSheet.close();
                    }
                    onViewTodo: {
                        completedSheet.retainedTodoData = {
                            incidencePtr: todoData.incidencePtr,
                            text: todoData.text,
                            color: todoData.color,
                            startTime: todoData.startTime,
                            endTime: todoData.endTime,
                            durationString: todoData.durationString
                        };
                        completedSheet.retainedCollectionData = Kalendar.CalendarManager.getCollectionDetails(collectionData.id);
                        root.viewTodo(completedSheet.retainedTodoData, completedSheet.retainedCollectionData);
                        completedSheet.close();
                    }
                    onEditTodo: {
                        root.editTodo(todoPtr, collectionId);
                        completedSheet.close();
                    }
                    onDeleteTodo: {
                        root.deleteTodo(todoPtr, deleteDate);
                        completedSheet.close();
                    }
                    onCompleteTodo: root.completeTodo(todoPtr);
                    onAddSubTodo: root.addSubTodo(parentWrapper)
                }
            }

        }
    }

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            id: headerLayout
            columns: 2
            rows: 2

            Kirigami.Heading {
                Layout.row: 0
                Layout.column: 0
                Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 30 || filterTag.visible ? 1 : 2
                Layout.fillWidth: true
                text: root.filterCollectionDetails && root.filterCollectionId > -1 ?
                    root.filterCollectionDetails.displayName : i18n("All Tasks")
                font.weight: Font.Bold
                color: root.filterCollectionDetails && root.filterCollectionId > -1 ?
                    LabelUtils.getIncidenceLabelColor(root.filterCollectionDetails.color, root.isDark) : Kirigami.Theme.textColor
                elide: Text.ElideRight
            }

            Tag {
                id: filterTag
                Layout.row: 0
                Layout.column: 1
                Layout.alignment: Qt.AlignRight
                visible: root.filterCategoryString
                text: root.filterCategoryString

                implicitWidth: itemLayout.implicitWidth > headerLayout.width - Kirigami.Units.gridUnit * 6 ?
                    headerLayout.width - Kirigami.Units.gridUnit * 6 : itemLayout.implicitWidth
                isHeading: true
                headingItem.color: root.filterCollectionDetails ?
                    LabelUtils.getIncidenceLabelColor(root.filterCollectionDetails.color, root.isDark) : Kirigami.Theme.textColor
                headingItem.font.weight: Font.Bold

                icon.name: "edit-delete-remove"
                onClicked: root.filterCategoryString = ""
                actionText: i18n("Remove filtering tag")
            }

            Kirigami.SearchField {
                id: searchField
                Layout.column: root.width < Kirigami.Units.gridUnit * 30 || filterTag.visible ? 0 : 1
                Layout.row: root.width < Kirigami.Units.gridUnit * 30 || filterTag.visible ? 1 : 0
                Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 30 || filterTag.visible ? 2 : 1
                Layout.fillWidth: Layout.row === 1
                onTextChanged: incompleteView.model.filterTodoName(text);
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

            TodoTreeView {
                id: incompleteView
                Layout.fillWidth: true
                Layout.fillHeight: true

                filterCollectionId: root.filterCollectionId
                filterCollectionDetails: root.filterCollectionDetails
                filterCategoryString: root.filterCategoryString

                showCompleted: Kalendar.TodoSortFilterProxyModel.ShowIncompleteOnly
                sortBy: root.sortBy
                ascendingOrder: root.ascendingOrder
                onAddTodo: root.addTodo(collectionId)
                onViewTodo: root.viewTodo(todoData, collectionData)
                onEditTodo: root.editTodo(todoPtr, collectionId)
                onDeleteTodo: root.deleteTodo(todoPtr, deleteDate)
                onCompleteTodo: root.completeTodo(todoPtr);
                onAddSubTodo: root.addSubTodo(parentWrapper)
            }
        }
    }

    Kirigami.OverlaySheet {
        id: collectionPickerSheet
        title: i18n("Choose a Task Calendar")

        property var incidenceWrapper

        ListView {
            id: collectionsList
            implicitWidth: Kirigami.Units.gridUnit * 30
            currentIndex: -1
            header: ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right

            }

            model: KDescendantsProxyModel {
                model: Kalendar.CalendarManager.todoCollections
            }

            delegate: DelegateChooser {
                role: 'kDescendantExpandable'
                DelegateChoice {
                    roleValue: true

                    Kirigami.BasicListItem {
                        label: display
                        labelItem.color: Kirigami.Theme.disabledTextColor
                        labelItem.font.weight: Font.DemiBold
                        topPadding: 2 * Kirigami.Units.largeSpacing
                        hoverEnabled: false
                        background: Item {}

                        separatorVisible: false

                        trailing: Kirigami.Icon {
                            width: Kirigami.Units.iconSizes.small
                            height: Kirigami.Units.iconSizes.small
                            source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                            x: -4
                        }

                        onClicked: collectionsList.model.toggleChildren(index)
                    }
                }

                DelegateChoice {
                    roleValue: false
                    Kirigami.BasicListItem {
                        label: display
                        labelItem.color: Kirigami.Theme.textColor

                        hoverEnabled: false

                        separatorVisible: false

                        onClicked: {
                            collectionPickerSheet.incidenceWrapper.collectionId = collectionId;
                            Kalendar.CalendarManager.addIncidence(collectionPickerSheet.incidenceWrapper);
                            collectionPickerSheet.close();
                            addField.clear();
                        }

                        trailing: Rectangle {
                            color: model.collectionColor
                            radius: Kirigami.Units.smallSpacing
                            width: height
                            height: Kirigami.Units.iconSizes.small
                        }
                    }
                }
            }
        }
    }

    footer: Kirigami.ActionTextField {
        id: addField
        placeholderText: i18n("Create a New Task…")
        FontMetrics {
            id: textMetrics
        }

        implicitHeight: textMetrics.height + Kirigami.Units.largeSpacing + 1 // To align with 'Show all' button in sidebar

        background: Rectangle {
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            color: Kirigami.Theme.backgroundColor
            Kirigami.Separator {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
            }
        }

        function addTodo() {
            if(addField.text) {
                let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                incidenceWrapper.setNewTodo();
                incidenceWrapper.summary = addField.text;

                if(root.filterCollectionId && root.filterCollectionId >= 0) {
                    incidenceWrapper.collectionId = root.filterCollectionId;
                    Kalendar.CalendarManager.addIncidence(incidenceWrapper);
                    addField.clear();
                } else {
                    collectionPickerSheet.incidenceWrapper = incidenceWrapper;
                    collectionPickerSheet.open();
                }
            }
        }

        rightActions: Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Quickly Add a New Task.")
            tooltip: i18n("Quickly Add a New Task.")
            onTriggered: addField.addTodo()
        }
        onAccepted: addField.addTodo()
    }
}
