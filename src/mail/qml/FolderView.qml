// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import org.kde.kalendar.mail 1.0
import org.kde.kitemmodels 1.0 as KItemModels

 Kirigami.ScrollablePage {
    id: folderView
    title: MailManager.selectedFolderName
    ListView {
        id: mails
        model: MailManager.folderModel
        section.delegate: Kirigami.ListSectionHeader {
            required property string section
            label: section
        }
        section.property: "date"
        delegate: Kirigami.BasicListItem {
            label: model.title
            subtitle: model.from
            labelItem.color: if (highlighted) {
                return Kirigami.Theme.highlightedTextColor;
            } else {
                return !model.status || model.status.isRead ? Kirigami.Theme.textColor : Kirigami.Theme.linkColor;
            }
            onClicked: {
                applicationWindow().pageStack.push(Qt.resolvedUrl('ConversationViewer.qml'), {
                    item: model.item,
                    props: model,
                });

                if (!model.status.isRead) {
                    const status = MailManager.folderModel.copyMessageStatus(model.status);
                    status.isRead = true;
                    MailManager.folderModel.updateMessageStatus(index, status)
                }
            }
        }
    }
}

