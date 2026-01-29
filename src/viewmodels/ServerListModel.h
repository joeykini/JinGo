/**
 * @file ServerListModel.h
 * @brief 服务器列表模型（基于 QAbstractListModel）
 * @details 提供高效的增量更新，避免列表闪烁和滚动位置丢失
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef SERVERLISTMODEL_H
#define SERVERLISTMODEL_H

#include <QAbstractListModel>
#include <QPointer>
#include <QHash>
#include "models/Server.h"

/**
 * @class ServerListModel
 * @brief 服务器列表数据模型
 * @details 使用 QAbstractListModel 实现，支持：
 * - 增量更新（只更新变化的行）
 * - 保持 ListView 滚动位置
 * - 避免界面闪烁
 * - 使用 Server::id() 作为唯一标识符
 */
class ServerListModel : public QAbstractListModel
{
    Q_OBJECT

    /// 服务器数量
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    /**
     * @brief 数据角色枚举
     */
    enum ServerRole {
        IdRole = Qt::UserRole + 1,      ///< 服务器ID（唯一标识）
        NameRole,                        ///< 服务器名称
        AddressRole,                     ///< 服务器地址
        PortRole,                        ///< 端口
        ProtocolRole,                    ///< 协议
        LocationRole,                    ///< 位置
        CountryCodeRole,                 ///< 国家代码
        LatencyRole,                     ///< 延迟（毫秒）
        IsAvailableRole,                 ///< 是否可用
        IsTestingSpeedRole,              ///< 是否正在测速
        ServerObjectRole                 ///< Server* 对象指针
    };
    Q_ENUM(ServerRole)

    /**
     * @brief 构造函数
     * @param parent 父对象
     */
    explicit ServerListModel(QObject* parent = nullptr);

    // ========================================================================
    // QAbstractListModel 必须实现的方法
    // ========================================================================

    /**
     * @brief 获取行数
     * @param parent 父索引（列表模型忽略此参数）
     * @return 服务器数量
     */
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;

    /**
     * @brief 获取指定索引和角色的数据
     * @param index 模型索引
     * @param role 数据角色
     * @return 对应的数据值
     */
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    /**
     * @brief 获取角色名称映射（供 QML 使用）
     * @return 角色 ID 到名称的映射
     */
    QHash<int, QByteArray> roleNames() const override;

    // ========================================================================
    // 公共方法
    // ========================================================================

    /**
     * @brief 获取服务器数量
     * @return 当前模型中的服务器数量
     */
    int count() const { return m_servers.count(); }

    /**
     * @brief 增量更新服务器列表
     * @param newServers 新的服务器列表
     * @details 使用 Server::id() 比较新旧列表，只更新变化的部分：
     * - 新增的服务器：调用 beginInsertRows/endInsertRows
     * - 删除的服务器：调用 beginRemoveRows/endRemoveRows
     * - 属性变化的服务器：发出 dataChanged 信号
     */
    void updateServers(const QList<Server*>& newServers);

    /**
     * @brief 清空所有服务器
     */
    void clear();

    /**
     * @brief 获取指定索引的服务器
     * @param index 行索引
     * @return 服务器指针，无效索引返回 nullptr
     */
    Q_INVOKABLE Server* serverAt(int index) const;

    /**
     * @brief 通过 ID 获取服务器
     * @param serverId 服务器 ID
     * @return 服务器指针，未找到返回 nullptr
     */
    Q_INVOKABLE Server* serverById(const QString& serverId) const;

    /**
     * @brief 通过 ID 获取服务器索引
     * @param serverId 服务器 ID
     * @return 索引，未找到返回 -1
     */
    Q_INVOKABLE int indexOfId(const QString& serverId) const;

    /**
     * @brief 通知指定服务器的数据已变化
     * @param server 数据变化的服务器
     */
    void notifyServerChanged(Server* server);

    /**
     * @brief 获取所有服务器列表
     * @return 服务器指针列表
     */
    QList<Server*> servers() const;

signals:
    /**
     * @brief 服务器数量变化信号
     */
    void countChanged();

    /**
     * @brief 服务器列表更新完成信号
     * @param added 新增的服务器数量
     * @param removed 删除的服务器数量
     * @param updated 更新的服务器数量
     */
    void updateCompleted(int added, int removed, int updated);

private:
    /**
     * @brief 检查两个服务器是否有属性差异
     * @param oldServer 旧服务器
     * @param newServer 新服务器
     * @return true 表示有差异需要更新
     */
    bool hasServerChanged(Server* oldServer, Server* newServer) const;

    /**
     * @brief 连接服务器的属性变化信号
     * @param server 要连接的服务器
     */
    void connectServerSignals(Server* server);

    QList<QPointer<Server>> m_servers;           ///< 服务器列表（使用 QPointer 安全持有）
    QHash<QString, int> m_idToIndex;             ///< ID 到索引的快速查找映射
};

#endif // SERVERLISTMODEL_H
