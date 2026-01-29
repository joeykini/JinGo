/**
 * @file ServerListModel.cpp
 * @brief 服务器列表模型实现
 * @details 使用 QAbstractListModel 实现增量更新
 * @author JinGo VPN Team
 * @date 2025
 */

#include "ServerListModel.h"
#include "core/Logger.h"
#include <QSet>

ServerListModel::ServerListModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int ServerListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_servers.count();
}

QVariant ServerListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_servers.count()) {
        return QVariant();
    }

    Server* server = m_servers.at(index.row()).data();
    if (!server) {
        return QVariant();
    }

    switch (role) {
    case IdRole:
        return server->id();
    case NameRole:
        return server->name();
    case AddressRole:
        return server->address();
    case PortRole:
        return server->port();
    case ProtocolRole:
        return server->protocol();
    case LocationRole:
        return server->location();
    case CountryCodeRole:
        return server->countryCode();
    case LatencyRole:
        return server->latency();
    case IsAvailableRole:
        return server->isAvailable();
    case IsTestingSpeedRole:
        return server->isTestingSpeed();
    case ServerObjectRole:
        return QVariant::fromValue(server);
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ServerListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "serverId";
    roles[NameRole] = "name";
    roles[AddressRole] = "address";
    roles[PortRole] = "port";
    roles[ProtocolRole] = "protocol";
    roles[LocationRole] = "location";
    roles[CountryCodeRole] = "countryCode";
    roles[LatencyRole] = "latency";
    roles[IsAvailableRole] = "isAvailable";
    roles[IsTestingSpeedRole] = "isTestingSpeed";
    roles[ServerObjectRole] = "serverObject";
    return roles;
}

void ServerListModel::updateServers(const QList<Server*>& newServers)
{
    // 构建新列表的 ID 集合和 ID->Server 映射
    QSet<QString> newIds;
    QHash<QString, Server*> newIdToServer;
    for (Server* server : newServers) {
        if (server) {
            QString id = server->id();
            newIds.insert(id);
            newIdToServer[id] = server;
        }
    }

    // 构建旧列表的 ID 集合
    QSet<QString> oldIds;
    for (const QPointer<Server>& serverPtr : m_servers) {
        if (!serverPtr.isNull()) {
            oldIds.insert(serverPtr->id());
        }
    }

    int addedCount = 0;
    int removedCount = 0;
    int updatedCount = 0;

    // 第一步：删除不在新列表中的服务器（从后往前删除，避免索引偏移问题）
    for (int i = m_servers.count() - 1; i >= 0; --i) {
        Server* oldServer = m_servers.at(i).data();
        if (!oldServer || !newIds.contains(oldServer->id())) {
            beginRemoveRows(QModelIndex(), i, i);
            if (oldServer) {
                m_idToIndex.remove(oldServer->id());
            }
            m_servers.removeAt(i);
            endRemoveRows();
            removedCount++;
        }
    }

    // 重建索引映射（删除后索引可能变化）
    m_idToIndex.clear();
    for (int i = 0; i < m_servers.count(); ++i) {
        Server* server = m_servers.at(i).data();
        if (server) {
            m_idToIndex[server->id()] = i;
        }
    }

    // 第二步：更新已存在的服务器，添加新服务器
    for (Server* newServer : newServers) {
        if (!newServer) continue;

        QString id = newServer->id();
        int existingIndex = m_idToIndex.value(id, -1);

        if (existingIndex >= 0) {
            // 服务器已存在，检查是否需要更新
            Server* oldServer = m_servers.at(existingIndex).data();
            if (oldServer && hasServerChanged(oldServer, newServer)) {
                // 替换为新的服务器指针
                m_servers[existingIndex] = QPointer<Server>(newServer);
                connectServerSignals(newServer);

                // 发出数据变化信号
                QModelIndex modelIndex = index(existingIndex, 0);
                emit dataChanged(modelIndex, modelIndex);
                updatedCount++;
            } else if (oldServer != newServer) {
                // 指针不同但数据相同，仍需更新指针
                m_servers[existingIndex] = QPointer<Server>(newServer);
                connectServerSignals(newServer);
            }
        } else {
            // 新服务器，添加到列表末尾
            int newIndex = m_servers.count();
            beginInsertRows(QModelIndex(), newIndex, newIndex);
            m_servers.append(QPointer<Server>(newServer));
            m_idToIndex[id] = newIndex;
            connectServerSignals(newServer);
            endInsertRows();
            addedCount++;
        }
    }

    // 更新计数
    if (addedCount > 0 || removedCount > 0) {
        emit countChanged();
    }

    LOG_INFO(QString("ServerListModel updated: added=%1, removed=%2, updated=%3, total=%4")
                 .arg(addedCount).arg(removedCount).arg(updatedCount).arg(m_servers.count()));

    emit updateCompleted(addedCount, removedCount, updatedCount);
}

void ServerListModel::clear()
{
    if (m_servers.isEmpty()) {
        return;
    }

    beginResetModel();
    m_servers.clear();
    m_idToIndex.clear();
    endResetModel();

    emit countChanged();
}

Server* ServerListModel::serverAt(int index) const
{
    if (index < 0 || index >= m_servers.count()) {
        return nullptr;
    }
    return m_servers.at(index).data();
}

Server* ServerListModel::serverById(const QString& serverId) const
{
    int index = m_idToIndex.value(serverId, -1);
    if (index >= 0 && index < m_servers.count()) {
        return m_servers.at(index).data();
    }
    return nullptr;
}

int ServerListModel::indexOfId(const QString& serverId) const
{
    return m_idToIndex.value(serverId, -1);
}

void ServerListModel::notifyServerChanged(Server* server)
{
    if (!server) return;

    int idx = m_idToIndex.value(server->id(), -1);
    if (idx >= 0) {
        QModelIndex modelIndex = index(idx, 0);
        emit dataChanged(modelIndex, modelIndex);
    }
}

QList<Server*> ServerListModel::servers() const
{
    QList<Server*> result;
    for (const QPointer<Server>& serverPtr : m_servers) {
        if (!serverPtr.isNull()) {
            result.append(serverPtr.data());
        }
    }
    return result;
}

bool ServerListModel::hasServerChanged(Server* oldServer, Server* newServer) const
{
    if (!oldServer || !newServer) return true;

    // 比较关键属性
    return oldServer->name() != newServer->name() ||
           oldServer->address() != newServer->address() ||
           oldServer->port() != newServer->port() ||
           oldServer->protocol() != newServer->protocol() ||
           oldServer->location() != newServer->location() ||
           oldServer->countryCode() != newServer->countryCode() ||
           oldServer->latency() != newServer->latency() ||
           oldServer->isAvailable() != newServer->isAvailable();
}

void ServerListModel::connectServerSignals(Server* server)
{
    if (!server) return;

    // 连接服务器属性变化信号，自动通知模型
    // 注意：Qt::UniqueConnection 不支持 lambda，移除该标志
    connect(server, &Server::latencyChanged, this, [this, server]() {
        notifyServerChanged(server);
    });

    connect(server, &Server::isAvailableChanged, this, [this, server]() {
        notifyServerChanged(server);
    });

    connect(server, &Server::isTestingSpeedChanged, this, [this, server]() {
        notifyServerChanged(server);
    });
}
