// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.10
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Window 2.15
import org.kde.kalendar 1.0

QQC2.MenuBar {
    id: bar
    property var parentWindow: null
    property bool todoMode: false

    QQC2.Menu {
        title: i18nc("@action:menu", "File")

        QQC2.MenuItem {
            text: i18nc("@action:menu", "Import Calendar") // todo
            visible: false
        }

        QQC2.MenuItem {
            text: i18nc("@action:menu", "Quit Kalendar")
            icon.name: "application-exit"
            onTriggered: Qt.quit()
        }
    }
    QQC2.Menu {
        id: editMenu
        title: i18nc("@action:menu", "Edit")
        Connections {
            target: parentWindow
            onActiveFocusItemChanged: {
                if (parentWindow.activeFocusItem instanceof TextEdit || parentWindow.activeFocusItem instanceof TextInput) {
                    editMenu.field = parentWindow.activeFocusItem;
                }
            }
        }
        field: null

        required property Item field

        KActionFromAction {
            kalendarAction: "edit_undo"
        }

        KActionFromAction {
            kalendarAction: "edit_redo"
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canUndo
            text: i18nc("text editing menu action", "Undo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canRedo
            text: i18nc("text editing menu action", "Redo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Cut")
            onTriggered: {
                editMenu.field.cut()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Copy")
            onTriggered: {
                editMenu.field.copy()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canPaste
            text: i18nc("text editing menu action", "Paste")
            onTriggered: {
                editMenu.field.paste()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText !== ""
            text: i18nc("text editing menu action", "Delete")
            onTriggered: {
                editMenu.field.remove(editMenu.field.selectionStart, editMenu.field.selectionEnd)
                editMenu.close()
            }
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null
            text: i18nc("text editing menu action", "Select All")
            onTriggered: {
                editMenu.field.selectAll()
                editMenu.close()
            }
        }
    }
    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        KActionFromAction {
            kalendarAction: "open_month_view"
        }
        KActionFromAction {
            kalendarAction: "open_schedule_view"
        }
        KActionFromAction {
            kalendarAction: "open_todo_view"
        }

        QQC2.MenuSeparator {
        }

        QQC2.Menu {
            title: i18n("Sort Todos")
            enabled: bar.todoMode

            KActionFromAction {
                kalendarAction: "todoview_sort_by_due_date"
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_by_priority"
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_alphabetically"
            }

            QQC2.MenuSeparator {
            }

            KActionFromAction {
                kalendarAction: "todoview_order_ascending"
            }
            KActionFromAction {
                kalendarAction: "todoview_order_descending"
            }
        }

        KActionFromAction {
            kalendarAction: "todoview_show_completed"
            enabled: bar.todoMode
        }

    }
    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        KActionFromAction {
            kalendarAction: "create_event"
        }
        KActionFromAction {
            kalendarAction: "create_todo"
        }
    }
    QQC2.Menu {
        title: i18nc("@action:menu", "Window")

        Kirigami.Action {
            text: root.visibility === Window.FullScreen ? i18nc("@action:menu", "Exit Full Screen") : i18nc("@action:menu", "Enter Full Screen")
            icon.name: "view-fullscreen"
            shortcut: "F11"
            onTriggered: root.visibility === Window.FullScreen ? root.showNormal() : root.showFullScreen()
        }
    }
    QQC2.Menu {
        title: i18nc("@action:menu", "Settings")
        KActionFromAction {
            kalendarAction: "options_configure"
        }
    }
    QQC2.Menu {
        title: i18nc("@action:menu", "Help")

        QQC2.MenuItem {
            text: i18nc("@action:menu", "Kalendar Handbook") // todo
            visible: false
        }
    }
}


