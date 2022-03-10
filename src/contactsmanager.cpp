// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later
#include "contactsmanager.h"
#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Monitor>
#include <QObject>
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 19, 40)
#include <Akonadi/EmailAddressSelectionModel>
#else
#include <Akonadi/Contact/EmailAddressSelectionModel>
#endif
#else
#include <Akonadi/EmailAddressSelectionModel>
#endif
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KDescendantsProxyModel>
#include <QBuffer>
#include <QImage>

class ContactsModel : public QSortFilterProxyModel
{
public:
    explicit ContactsModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        auto sourceModel = new Akonadi::EmailAddressSelectionModel;
        auto filterModel = new Akonadi::ContactsFilterProxyModel;
        auto flatModel = new KDescendantsProxyModel;
        auto addresseeOnlyModel = new Akonadi::EntityMimeTypeFilterModel;

        filterModel->setSourceModel(sourceModel->model());
        filterModel->setFilterFlags(Akonadi::ContactsFilterProxyModel::HasEmail);
        flatModel->setSourceModel(filterModel);

        addresseeOnlyModel->setSourceModel(flatModel);
        addresseeOnlyModel->addMimeTypeInclusionFilter(KContacts::Addressee::mimeType());

        setSourceModel(addresseeOnlyModel);
        setDynamicSortFilter(true);
        sort(0);
    }

protected:
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override
    {
        // Eliminate duplicate Akonadi items
        const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
        Q_ASSERT(sourceIndex.isValid());

        auto data = sourceIndex.data(Akonadi::EntityTreeModel::ItemIdRole);
        auto matches = match(index(0, 0), Akonadi::EntityTreeModel::ItemIdRole, data, 2, Qt::MatchExactly | Qt::MatchWrap | Qt::MatchRecursive);

        return matches.length() < 1;
    }
};

ContactsManager::ContactsManager(QObject *parent)
    : QObject(parent)
{
    auto model = new ContactsModel(this);
    m_model = new QSortFilterProxyModel;
    m_model->setSourceModel(model);
    m_model->setDynamicSortFilter(true);
    m_model->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_model->setFilterCaseSensitivity(Qt::CaseInsensitive);
    m_model->sort(0);
}

QSortFilterProxyModel *ContactsManager::contactsModel()
{
    return m_model;
}

void ContactsManager::contactEmails(qint64 itemId)
{
    Akonadi::Item item(itemId);

    auto job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();

    connect(job, &Akonadi::ItemFetchJob::result, this, [this, itemId](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        auto item = fetchJob->items().at(0);
        auto payload = item.payload<KContacts::Addressee>();

        Q_EMIT emailsFetched(payload.emails(), itemId);
    });
}

QUrl ContactsManager::decorationToUrl(QVariant decoration)
{
    if (!decoration.canConvert<QImage>()) {
        return {};
    }

    auto imgDecoration = decoration.value<QImage>();
    QByteArray byteArray;
    QBuffer buffer(&byteArray);
    buffer.open(QIODevice::WriteOnly);
    imgDecoration.save(&buffer, "png");
    QString base64 = QString::fromUtf8(byteArray.toBase64());
    return QUrl(QLatin1String("data:image/png;base64,") + base64);
}
