/**
 * @file DatabaseManager.h
 * @brief 数据库管理器头文件
 * @details 提供对 SQLite 数据库的完整封装，包括连接管理、表创建、数据 CRUD 操作
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QString>
#include <QSqlDatabase>
#include <QMutex>
#include <QList>
#include <QSqlQuery>

// 前向声明
class Subscription;
class Server;
class User;

#define DATABASE_VERSION 5 // 数据库版本升级 - 添加resolvedIP字段

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager& instance();
    static void destroy();

    bool initialize();
    void close();
    bool isOpen() const;

    // Subscription operations
    bool saveSubscription(Subscription* subscription);
    QList<Subscription*> loadSubscriptions(QObject* parent = nullptr);
    bool deleteSubscription(const QString& subscriptionId);
    bool updateSubscriptionInfo(const QString& subscriptionId, const QDateTime& lastUpdated, int serverCount);

    // Server operations
    bool saveServer(Server* server);
    bool saveServers(const QList<Server*>& servers);
    bool deleteServer(const QString& serverId);
    bool deleteServers(const QStringList& serverIds);
    bool deleteServersBySubscription(const QString& subscriptionId);
    bool deleteServersNotInList(const QString& subscriptionId, const QStringList& serverIds);
    Server* getServer(const QString& serverId, QObject* parent = nullptr);
    QList<Server*> loadServers(QObject* parent = nullptr);
    QList<Server*> getServersBySubscription(const QString& subscriptionId, QObject* parent = nullptr);

    // 新方法：原子性更新订阅服务器（直接操作数据库，不创建对象）
    bool updateSubscriptionServers(const QString& subscriptionId, const QList<QJsonObject>& serverConfigs);
    Q_INVOKABLE bool cleanupUnavailableServers(); // 清理所有不可用的服务器
    QList<Server*> searchServers(const QString& keyword, QObject* parent = nullptr);
    QList<Server*> getFavoriteServers(QObject* parent = nullptr);
    bool updateServerStats(const QString& serverId, qint64 upload, qint64 download);

    // User operations
    bool saveUser(User* user);
    bool deleteUser(const QString& userId);
    User* getUser(const QString& userId, QObject* parent = nullptr);
    QList<User*> loadUsers(QObject* parent = nullptr);
    User* getCurrentUser(QObject* parent = nullptr);
    bool setCurrentUser(const QString& userId);
    bool clearCurrentUser();

    // User Subscribe Info operations
    bool saveUserSubscribeInfo(const QString& userId, const QJsonObject& subscribeInfo);
    QJsonObject getUserSubscribeInfo(const QString& userId);
    bool deleteUserSubscribeInfo(const QString& userId);
    bool hasUserSubscribeInfo(const QString& userId);

    // Plans operations
    bool savePlans(const QJsonArray& plans);
    QJsonArray getPlans();
    bool deletePlans();
    bool hasPlans();

    // Config operations
    bool saveConfig(const QString& key, const QString& value);
    QString getConfig(const QString& key, const QString& defaultValue = QString());
    bool deleteConfig(const QString& key);
    bool clearAllConfigs();

    // Maintenance
    bool clearAllData();
    bool vacuum();
    bool backup(const QString& backupPath);
    bool restore(const QString& backupPath);
    QString getDatabaseInfo() const;
    qint64 getDatabaseSize() const;

signals:
    void errorOccurred(const QString& error);
    void dataUpdated(const QString& table);

private:
    explicit DatabaseManager(QObject* parent = nullptr);
    ~DatabaseManager();
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;

    bool createTables();
    bool createServerTable();
    bool createSubscriptionTable();
    bool createUserTable();
    bool createUserSubscribeInfoTable();
    bool createPlansTable();
    bool createConfigTable();
    bool createVersionTable();

    bool upgradeDatabase(int fromVersion, int toVersion);
    int getDatabaseVersion() const;
    bool setDatabaseVersion(int version);

    Server* loadServerFromQuery(QSqlQuery& query, QObject* parent);
    Subscription* loadSubscriptionFromQuery(QSqlQuery& query, QObject* parent);
    User* loadUserFromQuery(QSqlQuery& query, QObject* parent);

    bool executeTransaction(std::function<bool()> operation);
    void logError(const QString& operation, const QSqlQuery& query);

    static DatabaseManager* s_instance;
    static QMutex s_instanceMutex;

    QSqlDatabase m_database;
    mutable QMutex m_mutex;
    QString m_databasePath;
};

#endif // DATABASEMANAGER_H
