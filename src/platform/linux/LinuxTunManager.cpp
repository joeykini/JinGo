/**
 * @file LinuxTunManager.cpp
 * @brief Linux TUN虚拟网卡管理器实现
 * @details 使用Linux内核原生TUN/TAP设备实现VPN功能
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright © 2025 JinGo Team. All rights reserved.
 */

#ifdef __linux__

#include "LinuxTunManager.h"

#include <iostream>
#include <sstream>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <net/if.h>
#include <linux/if_tun.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <fstream>
#include <cstdlib>

namespace JinGo {

LinuxTunManager::LinuxTunManager()
    : tunFd_(-1)
    , mtu_(1500)
    , bytesReceived_(0)
    , bytesSent_(0)
    , packetsReceived_(0)
    , packetsSent_(0)
    , errorsReceived_(0)
    , errorsSent_(0)
{
}

LinuxTunManager::~LinuxTunManager()
{
    shutdown();
}

int LinuxTunManager::createTunDevice(const std::string& deviceName)
{
    // 打开TUN设备
    int fd = open("/dev/net/tun", O_RDWR);
    if (fd < 0) {
        std::cerr << "[LinuxTun] Failed to open /dev/net/tun: " << strerror(errno) << std::endl;
        return -1;
    }

    // 配置TUN设备
    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));

    // IFF_TUN: TUN设备（三层网络设备）
    // IFF_NO_PI: 不包含包信息头
    ifr.ifr_flags = IFF_TUN | IFF_NO_PI;

    if (!deviceName.empty()) {
        strncpy(ifr.ifr_name, deviceName.c_str(), IFNAMSIZ - 1);
        ifr.ifr_name[IFNAMSIZ - 1] = '\0';  // 确保 null 终止
    }

    // 创建TUN设备
    if (ioctl(fd, TUNSETIFF, &ifr) < 0) {
        std::cerr << "[LinuxTun] Failed to create TUN device: " << strerror(errno) << std::endl;
        close(fd);
        return -1;
    }

    // 保存实际的设备名称
    deviceName_ = ifr.ifr_name;

    // 设置非阻塞模式
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0 || fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) {
        std::cerr << "[LinuxTun] Failed to set non-blocking mode: " << strerror(errno) << std::endl;
        close(fd);
        return -1;
    }

    std::cout << "[LinuxTun] TUN device created: " << deviceName_ << std::endl;
    return fd;
}

bool LinuxTunManager::initialize(const std::string& deviceName, int mtu)
{
    if (tunFd_ >= 0) {
        std::cerr << "[LinuxTun] Already initialized" << std::endl;
        return false;
    }

    mtu_ = mtu;

    // 创建TUN设备
    tunFd_ = createTunDevice(deviceName);
    if (tunFd_ < 0) {
        return false;
    }

    // 设置MTU
    if (!setMTU(mtu_)) {
        std::cerr << "[LinuxTun] Warning: Failed to set MTU" << std::endl;
    }

    return true;
}

void LinuxTunManager::shutdown()
{
    if (tunFd_ >= 0) {
        // 关闭设备
        setDeviceState(false);
        close(tunFd_);
        tunFd_ = -1;
        std::cout << "[LinuxTun] Device closed: " << deviceName_ << std::endl;
    }
}

bool LinuxTunManager::executeCommand(const std::string& command)
{
    std::cout << "[LinuxTun] Executing: " << command << std::endl;
    int result = system(command.c_str());
    if (result != 0) {
        std::cerr << "[LinuxTun] Command failed with code: " << result << std::endl;
        return false;
    }
    return true;
}

bool LinuxTunManager::setIPAddress(const std::string& ipAddress, uint8_t prefixLength)
{
    if (tunFd_ < 0) {
        std::cerr << "[LinuxTun] Device not initialized" << std::endl;
        return false;
    }

    // 优先使用netlink API（不需要子进程，可继承CAP_NET_ADMIN）
    if (netlinkAddIPAddress(ipAddress, prefixLength)) {
        std::cout << "[LinuxTun] IP address set via netlink: " << ipAddress << "/" << (int)prefixLength << std::endl;
        return true;
    }

    // 回退到ip命令（需要root权限）
    std::cout << "[LinuxTun] Netlink failed, falling back to ip command" << std::endl;
    std::ostringstream cmd;
    cmd << "ip addr add " << ipAddress << "/" << (int)prefixLength
        << " dev " << deviceName_;

    if (!executeCommand(cmd.str())) {
        return false;
    }

    std::cout << "[LinuxTun] IP address set: " << ipAddress << "/" << (int)prefixLength << std::endl;
    return true;
}

bool LinuxTunManager::setDeviceState(bool up)
{
    if (tunFd_ < 0) {
        std::cerr << "[LinuxTun] Device not initialized" << std::endl;
        return false;
    }

    // 优先使用netlink API（不需要子进程，可继承CAP_NET_ADMIN）
    if (netlinkSetDeviceState(up)) {
        std::cout << "[LinuxTun] Device state via netlink: " << (up ? "UP" : "DOWN") << std::endl;
        return true;
    }

    // 回退到ip命令（需要root权限）
    std::cout << "[LinuxTun] Netlink failed, falling back to ip command" << std::endl;
    std::ostringstream cmd;
    cmd << "ip link set dev " << deviceName_ << (up ? " up" : " down");

    if (!executeCommand(cmd.str())) {
        return false;
    }

    std::cout << "[LinuxTun] Device state: " << (up ? "UP" : "DOWN") << std::endl;
    return true;
}

bool LinuxTunManager::setMTU(int mtu)
{
    if (tunFd_ < 0) {
        std::cerr << "[LinuxTun] Device not initialized" << std::endl;
        return false;
    }

    mtu_ = mtu;

    // 优先使用netlink API（不需要子进程，可继承CAP_NET_ADMIN）
    if (netlinkSetMTU(mtu)) {
        std::cout << "[LinuxTun] MTU set via netlink: " << mtu << std::endl;
        return true;
    }

    // 回退到ip命令（需要root权限）
    std::cout << "[LinuxTun] Netlink failed, falling back to ip command" << std::endl;
    std::ostringstream cmd;
    cmd << "ip link set dev " << deviceName_ << " mtu " << mtu;

    if (!executeCommand(cmd.str())) {
        return false;
    }

    std::cout << "[LinuxTun] MTU set: " << mtu << std::endl;
    return true;
}

bool LinuxTunManager::addRoute(const std::string& destination, uint8_t prefixLength,
                                const std::string& gateway)
{
    if (tunFd_ < 0) {
        std::cerr << "[LinuxTun] Device not initialized" << std::endl;
        return false;
    }

    // 优先使用netlink API（支持CAP_NET_ADMIN权限）
    bool success = netlinkAddRoute(destination, prefixLength, gateway);

    if (!success) {
        std::cerr << "[LinuxTun] Failed to add route via netlink, trying ip command..." << std::endl;

        // 备用方案：使用ip命令（需要sudo或root）
        std::ostringstream cmd;
        cmd << "ip route add ";

        if (destination == "0.0.0.0" && prefixLength == 0) {
            cmd << "default";
        } else {
            cmd << destination << "/" << (int)prefixLength;
        }

        if (!gateway.empty()) {
            cmd << " via " << gateway;
        }

        cmd << " dev " << deviceName_;
        cmd << " metric 0";  // 最高优先级，确保VPN路由优先

        if (!executeCommand(cmd.str())) {
            // 如果路由已存在，不认为是错误
            std::cout << "[LinuxTun] Route may already exist" << std::endl;
        }

        std::cout << "[LinuxTun] Route added via ip command: " << destination << "/" << (int)prefixLength;
        if (!gateway.empty()) {
            std::cout << " via " << gateway;
        }
        std::cout << std::endl;

        return true;
    }

    return true;
}

bool LinuxTunManager::deleteRoute(const std::string& destination, uint8_t prefixLength)
{
    if (tunFd_ < 0) {
        std::cerr << "[LinuxTun] Device not initialized" << std::endl;
        return false;
    }

    // 优先使用netlink API（支持CAP_NET_ADMIN权限）
    bool success = netlinkDeleteRoute(destination, prefixLength);

    if (!success) {
        std::cerr << "[LinuxTun] Failed to delete route via netlink, trying ip command..." << std::endl;

        // 备用方案：使用ip命令（需要sudo或root）
        std::ostringstream cmd;
        cmd << "ip route del ";

        if (destination == "0.0.0.0" && prefixLength == 0) {
            cmd << "default";
        } else {
            cmd << destination << "/" << (int)prefixLength;
        }

        cmd << " dev " << deviceName_;

        if (!executeCommand(cmd.str())) {
            return false;
        }

        std::cout << "[LinuxTun] Route deleted via ip command: " << destination << "/" << (int)prefixLength << std::endl;
        return true;
    }

    return true;
}

bool LinuxTunManager::setDNS(const std::vector<std::string>& dnsServers)
{
    if (dnsServers.empty()) {
        std::cerr << "[LinuxTun] No DNS servers specified" << std::endl;
        return false;
    }

    // 方法1: 修改/etc/resolv.conf（需要root权限）
    // 注意：这是临时修改，系统重启或网络管理器更新会覆盖

    // 备份原文件
    executeCommand("cp /etc/resolv.conf /etc/resolv.conf.jingo.backup");

    // 创建新的resolv.conf内容
    std::ofstream resolvConf("/etc/resolv.conf.jingo", std::ios::out | std::ios::trunc);
    if (!resolvConf.is_open()) {
        std::cerr << "[LinuxTun] Failed to create resolv.conf" << std::endl;
        return false;
    }

    resolvConf << "# Generated by JinGoVPN\n";
    for (const auto& dns : dnsServers) {
        resolvConf << "nameserver " << dns << "\n";
    }
    resolvConf.close();

    // 替换resolv.conf
    if (!executeCommand("mv /etc/resolv.conf.jingo /etc/resolv.conf")) {
        return false;
    }

    std::cout << "[LinuxTun] DNS servers set: ";
    for (const auto& dns : dnsServers) {
        std::cout << dns << " ";
    }
    std::cout << std::endl;

    // 方法2: 使用systemd-resolved（如果可用）
    // resolvectl dns <interface> <dns1> <dns2> ...
    std::ostringstream resolvectlCmd;
    resolvectlCmd << "resolvectl dns " << deviceName_;
    for (const auto& dns : dnsServers) {
        resolvectlCmd << " " << dns;
    }

    // 尝试使用resolvectl（如果失败不算错误）
    if (system(resolvectlCmd.str().c_str()) == 0) {
        std::cout << "[LinuxTun] DNS configured via systemd-resolved" << std::endl;
    }

    return true;
}

ssize_t LinuxTunManager::readPacket(uint8_t* buffer, size_t bufferSize)
{
    if (tunFd_ < 0) {
        errorsReceived_++;
        return -1;
    }

    ssize_t n = read(tunFd_, buffer, bufferSize);

    if (n > 0) {
        packetsReceived_++;
        bytesReceived_ += n;
    } else if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
        errorsReceived_++;
        std::cerr << "[LinuxTun] Read error: " << strerror(errno) << std::endl;
    }

    return n;
}

ssize_t LinuxTunManager::writePacket(const uint8_t* buffer, size_t size)
{
    if (tunFd_ < 0) {
        errorsSent_++;
        return -1;
    }

    ssize_t n = write(tunFd_, buffer, size);

    if (n > 0) {
        packetsSent_++;
        bytesSent_ += n;
    } else if (n < 0) {
        errorsSent_++;
        std::cerr << "[LinuxTun] Write error: " << strerror(errno) << std::endl;
    }

    return n;
}

LinuxTunManager::Statistics LinuxTunManager::getStatistics() const
{
    Statistics stats;
    stats.bytesReceived = bytesReceived_.load();
    stats.bytesSent = bytesSent_.load();
    stats.packetsReceived = packetsReceived_.load();
    stats.packetsSent = packetsSent_.load();
    stats.errorsReceived = errorsReceived_.load();
    stats.errorsSent = errorsSent_.load();
    return stats;
}

// ============================================================================
// Netlink API实现（使用Linux netlink直接配置网络，继承CAP_NET_ADMIN）
// ============================================================================

int LinuxTunManager::createNetlinkSocket()
{
    int sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0) {
        std::cerr << "[LinuxTun] Failed to create netlink socket: " << strerror(errno) << std::endl;
        return -1;
    }

    struct sockaddr_nl addr;
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = getpid();

    if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        std::cerr << "[LinuxTun] Failed to bind netlink socket: " << strerror(errno) << std::endl;
        close(sock);
        return -1;
    }

    return sock;
}

bool LinuxTunManager::netlinkAddIPAddress(const std::string& ipAddress, uint8_t prefixLength)
{
    int sock = createNetlinkSocket();
    if (sock < 0) {
        return false;
    }

    // 获取接口索引
    unsigned int ifIndex = if_nametoindex(deviceName_.c_str());
    if (ifIndex == 0) {
        std::cerr << "[LinuxTun] Failed to get interface index: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 构建netlink消息
    struct {
        struct nlmsghdr  nlh;
        struct ifaddrmsg ifa;
        char             attrbuf[512];
    } req;

    memset(&req, 0, sizeof(req));

    // Netlink消息头
    req.nlh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ifaddrmsg));
    req.nlh.nlmsg_flags = NLM_F_REQUEST | NLM_F_CREATE | NLM_F_EXCL | NLM_F_ACK;
    req.nlh.nlmsg_type = RTM_NEWADDR;

    // 地址消息
    req.ifa.ifa_family = AF_INET;
    req.ifa.ifa_prefixlen = prefixLength;
    req.ifa.ifa_flags = IFA_F_PERMANENT;
    req.ifa.ifa_scope = RT_SCOPE_UNIVERSE;
    req.ifa.ifa_index = ifIndex;

    // 添加IP地址属性
    struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
    rta->rta_type = IFA_LOCAL;
    rta->rta_len = RTA_LENGTH(4);

    struct in_addr addr;
    if (inet_pton(AF_INET, ipAddress.c_str(), &addr) != 1) {
        std::cerr << "[LinuxTun] Invalid IP address: " << ipAddress << std::endl;
        close(sock);
        return false;
    }
    memcpy(RTA_DATA(rta), &addr, 4);
    req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;

    // 发送消息
    if (send(sock, &req, req.nlh.nlmsg_len, 0) < 0) {
        std::cerr << "[LinuxTun] Failed to send netlink message: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 接收ACK
    char buffer[4096];
    ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
    close(sock);

    if (len < 0) {
        std::cerr << "[LinuxTun] Failed to receive netlink response: " << strerror(errno) << std::endl;
        return false;
    }

    struct nlmsghdr *nlh = (struct nlmsghdr *)buffer;
    if (nlh->nlmsg_type == NLMSG_ERROR) {
        struct nlmsgerr *err = (struct nlmsgerr *)NLMSG_DATA(nlh);
        if (err->error != 0) {
            std::cerr << "[LinuxTun] Netlink error: " << strerror(-err->error) << std::endl;
            return false;
        }
    }

    return true;
}

bool LinuxTunManager::netlinkSetDeviceState(bool up)
{
    int sock = createNetlinkSocket();
    if (sock < 0) {
        return false;
    }

    // 获取接口索引
    unsigned int ifIndex = if_nametoindex(deviceName_.c_str());
    if (ifIndex == 0) {
        std::cerr << "[LinuxTun] Failed to get interface index: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 构建netlink消息
    struct {
        struct nlmsghdr nlh;
        struct ifinfomsg ifi;
    } req;

    memset(&req, 0, sizeof(req));

    // Netlink消息头
    req.nlh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ifinfomsg));
    req.nlh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;
    req.nlh.nlmsg_type = RTM_NEWLINK;

    // 接口信息
    req.ifi.ifi_family = AF_UNSPEC;
    req.ifi.ifi_index = ifIndex;
    req.ifi.ifi_flags = up ? IFF_UP : 0;
    req.ifi.ifi_change = IFF_UP;

    // 发送消息
    if (send(sock, &req, req.nlh.nlmsg_len, 0) < 0) {
        std::cerr << "[LinuxTun] Failed to send netlink message: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 接收ACK
    char buffer[4096];
    ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
    close(sock);

    if (len < 0) {
        std::cerr << "[LinuxTun] Failed to receive netlink response: " << strerror(errno) << std::endl;
        return false;
    }

    struct nlmsghdr *nlh = (struct nlmsghdr *)buffer;
    if (nlh->nlmsg_type == NLMSG_ERROR) {
        struct nlmsgerr *err = (struct nlmsgerr *)NLMSG_DATA(nlh);
        if (err->error != 0) {
            std::cerr << "[LinuxTun] Netlink error: " << strerror(-err->error) << std::endl;
            return false;
        }
    }

    return true;
}

bool LinuxTunManager::netlinkSetMTU(int mtu)
{
    int sock = createNetlinkSocket();
    if (sock < 0) {
        return false;
    }

    // 获取接口索引
    unsigned int ifIndex = if_nametoindex(deviceName_.c_str());
    if (ifIndex == 0) {
        std::cerr << "[LinuxTun] Failed to get interface index: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 构建netlink消息
    struct {
        struct nlmsghdr  nlh;
        struct ifinfomsg ifi;
        char             attrbuf[512];
    } req;

    memset(&req, 0, sizeof(req));

    // Netlink消息头
    req.nlh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ifinfomsg));
    req.nlh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;
    req.nlh.nlmsg_type = RTM_NEWLINK;

    // 接口信息
    req.ifi.ifi_family = AF_UNSPEC;
    req.ifi.ifi_index = ifIndex;

    // 添加MTU属性
    struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
    rta->rta_type = IFLA_MTU;
    rta->rta_len = RTA_LENGTH(sizeof(int));
    memcpy(RTA_DATA(rta), &mtu, sizeof(int));
    req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;

    // 发送消息
    if (send(sock, &req, req.nlh.nlmsg_len, 0) < 0) {
        std::cerr << "[LinuxTun] Failed to send netlink message: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 接收ACK
    char buffer[4096];
    ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
    close(sock);

    if (len < 0) {
        std::cerr << "[LinuxTun] Failed to receive netlink response: " << strerror(errno) << std::endl;
        return false;
    }

    struct nlmsghdr *nlh = (struct nlmsghdr *)buffer;
    if (nlh->nlmsg_type == NLMSG_ERROR) {
        struct nlmsgerr *err = (struct nlmsgerr *)NLMSG_DATA(nlh);
        if (err->error != 0) {
            std::cerr << "[LinuxTun] Netlink error: " << strerror(-err->error) << std::endl;
            return false;
        }
    }

    return true;
}

bool LinuxTunManager::netlinkAddRoute(const std::string& destination, uint8_t prefixLength,
                                      const std::string& gateway)
{
    int sock = createNetlinkSocket();
    if (sock < 0) {
        std::cerr << "[LinuxTun] Failed to create netlink socket for route" << std::endl;
        return false;
    }

    // 获取接口索引
    unsigned int ifIndex = if_nametoindex(deviceName_.c_str());
    if (ifIndex == 0) {
        std::cerr << "[LinuxTun] Failed to get interface index for route: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 构建netlink消息
    struct {
        struct nlmsghdr  nlh;
        struct rtmsg     rtm;
        char             attrbuf[1024];
    } req;

    memset(&req, 0, sizeof(req));

    // Netlink消息头
    req.nlh.nlmsg_len = NLMSG_LENGTH(sizeof(struct rtmsg));
    req.nlh.nlmsg_flags = NLM_F_REQUEST | NLM_F_CREATE | NLM_F_ACK;
    req.nlh.nlmsg_type = RTM_NEWROUTE;

    // 路由消息
    req.rtm.rtm_family = AF_INET;
    req.rtm.rtm_table = RT_TABLE_MAIN;
    req.rtm.rtm_protocol = RTPROT_STATIC;
    req.rtm.rtm_scope = RT_SCOPE_UNIVERSE;
    req.rtm.rtm_type = RTN_UNICAST;
    req.rtm.rtm_dst_len = prefixLength;

    // 添加目标地址属性
    if (!destination.empty() && destination != "0.0.0.0") {
        struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
        rta->rta_type = RTA_DST;
        rta->rta_len = RTA_LENGTH(4);

        struct in_addr dst_addr;
        if (inet_pton(AF_INET, destination.c_str(), &dst_addr) != 1) {
            std::cerr << "[LinuxTun] Invalid destination IP: " << destination << std::endl;
            close(sock);
            return false;
        }
        memcpy(RTA_DATA(rta), &dst_addr, 4);
        req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;
    }

    // 添加网关属性
    if (!gateway.empty()) {
        struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
        rta->rta_type = RTA_GATEWAY;
        rta->rta_len = RTA_LENGTH(4);

        struct in_addr gw_addr;
        if (inet_pton(AF_INET, gateway.c_str(), &gw_addr) != 1) {
            std::cerr << "[LinuxTun] Invalid gateway IP: " << gateway << std::endl;
            close(sock);
            return false;
        }
        memcpy(RTA_DATA(rta), &gw_addr, 4);
        req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;
    }

    // 添加出口接口属性
    // 注意：只在网关为空时设置 RTA_OIF 为 TUN 设备
    // 如果提供了网关，让内核自动选择能到达该网关的物理接口
    // 这样排除路由（如 10.0.0.0/8 via 172.16.1.1）会自动走物理网卡
    if (gateway.empty()) {
        struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
        rta->rta_type = RTA_OIF;
        rta->rta_len = RTA_LENGTH(4);
        memcpy(RTA_DATA(rta), &ifIndex, 4);
        req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;
        std::cout << "[LinuxTun] Route via TUN device (no gateway)" << std::endl;
    } else {
        std::cout << "[LinuxTun] Route via gateway (kernel will select interface)" << std::endl;
    }

    // 添加优先级属性（metric = 0 表示最高优先级）
    {
        uint32_t priority = 0;
        struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
        rta->rta_type = RTA_PRIORITY;
        rta->rta_len = RTA_LENGTH(4);
        memcpy(RTA_DATA(rta), &priority, 4);
        req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;
    }

    // 发送消息
    if (send(sock, &req, req.nlh.nlmsg_len, 0) < 0) {
        std::cerr << "[LinuxTun] Failed to send netlink route message: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 接收ACK
    char buffer[4096];
    ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
    close(sock);

    if (len < 0) {
        std::cerr << "[LinuxTun] Failed to receive netlink ACK: " << strerror(errno) << std::endl;
        return false;
    }

    struct nlmsghdr *ack = (struct nlmsghdr *)buffer;
    if (ack->nlmsg_type == NLMSG_ERROR) {
        struct nlmsgerr *err = (struct nlmsgerr *)NLMSG_DATA(ack);
        if (err->error != 0) {
            // 如果路由已存在，不认为是错误（EEXIST）
            if (err->error != -EEXIST) {
                std::cerr << "[LinuxTun] Netlink route add error: " << strerror(-err->error) << std::endl;
                return false;
            }
        }
    }

    std::cout << "[LinuxTun] Route added via netlink: " << destination << "/" << (int)prefixLength;
    if (!gateway.empty()) {
        std::cout << " via " << gateway;
    }
    std::cout << " dev " << deviceName_ << std::endl;

    return true;
}

bool LinuxTunManager::netlinkDeleteRoute(const std::string& destination, uint8_t prefixLength)
{
    int sock = createNetlinkSocket();
    if (sock < 0) {
        std::cerr << "[LinuxTun] Failed to create netlink socket for route deletion" << std::endl;
        return false;
    }

    // 获取接口索引
    unsigned int ifIndex = if_nametoindex(deviceName_.c_str());
    if (ifIndex == 0) {
        std::cerr << "[LinuxTun] Failed to get interface index: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 构建netlink消息
    struct {
        struct nlmsghdr  nlh;
        struct rtmsg     rtm;
        char             attrbuf[1024];
    } req;

    memset(&req, 0, sizeof(req));

    // Netlink消息头
    req.nlh.nlmsg_len = NLMSG_LENGTH(sizeof(struct rtmsg));
    req.nlh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;
    req.nlh.nlmsg_type = RTM_DELROUTE;

    // 路由消息
    req.rtm.rtm_family = AF_INET;
    req.rtm.rtm_table = RT_TABLE_MAIN;
    req.rtm.rtm_protocol = RTPROT_STATIC;
    req.rtm.rtm_scope = RT_SCOPE_UNIVERSE;
    req.rtm.rtm_type = RTN_UNICAST;
    req.rtm.rtm_dst_len = prefixLength;

    // 添加目标地址属性
    if (!destination.empty() && destination != "0.0.0.0") {
        struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
        rta->rta_type = RTA_DST;
        rta->rta_len = RTA_LENGTH(4);

        struct in_addr dst_addr;
        if (inet_pton(AF_INET, destination.c_str(), &dst_addr) != 1) {
            std::cerr << "[LinuxTun] Invalid destination IP: " << destination << std::endl;
            close(sock);
            return false;
        }
        memcpy(RTA_DATA(rta), &dst_addr, 4);
        req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;
    }

    // 添加出口接口属性
    {
        struct rtattr *rta = (struct rtattr *)(((char *)&req) + NLMSG_ALIGN(req.nlh.nlmsg_len));
        rta->rta_type = RTA_OIF;
        rta->rta_len = RTA_LENGTH(4);
        memcpy(RTA_DATA(rta), &ifIndex, 4);
        req.nlh.nlmsg_len = NLMSG_ALIGN(req.nlh.nlmsg_len) + rta->rta_len;
    }

    // 发送消息
    if (send(sock, &req, req.nlh.nlmsg_len, 0) < 0) {
        std::cerr << "[LinuxTun] Failed to send netlink route delete message: " << strerror(errno) << std::endl;
        close(sock);
        return false;
    }

    // 接收ACK
    char buffer[4096];
    ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
    close(sock);

    if (len < 0) {
        std::cerr << "[LinuxTun] Failed to receive netlink ACK: " << strerror(errno) << std::endl;
        return false;
    }

    struct nlmsghdr *ack = (struct nlmsghdr *)buffer;
    if (ack->nlmsg_type == NLMSG_ERROR) {
        struct nlmsgerr *err = (struct nlmsgerr *)NLMSG_DATA(ack);
        if (err->error != 0) {
            std::cerr << "[LinuxTun] Netlink route delete error: " << strerror(-err->error) << std::endl;
            return false;
        }
    }

    std::cout << "[LinuxTun] Route deleted via netlink: " << destination << "/" << (int)prefixLength
              << " dev " << deviceName_ << std::endl;

    return true;
}

} // namespace JinGo

#endif // __linux__
