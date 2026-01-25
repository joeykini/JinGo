/**
 * @file RsaCrypto_windows.cpp
 * @brief RSA 加密工具 Windows 实现
 * @details 使用 Windows BCrypt/NCrypt (CNG) 实现 RSA 加密、解密、签名和验签
 */

#include "RsaCrypto.h"
#include "../core/Logger.h"

#ifdef Q_OS_WIN

#include <windows.h>
#include <bcrypt.h>
#include <ncrypt.h>
#include <wincrypt.h>
#include <ntstatus.h>

#pragma comment(lib, "bcrypt.lib")
#pragma comment(lib, "ncrypt.lib")
#pragma comment(lib, "crypt32.lib")

// MinGW 可能未定义 STATUS_INVALID_SIGNATURE
#ifndef STATUS_INVALID_SIGNATURE
#define STATUS_INVALID_SIGNATURE ((NTSTATUS)0xC000A000L)
#endif

namespace {

/**
 * @brief 从 PEM 格式提取 Base64 数据并解码为 DER
 */
QByteArray pemToDer(const QByteArray& pemData, bool isPrivate)
{
    // 查找 PEM 边界
    QByteArray header = isPrivate ? "-----BEGIN PRIVATE KEY-----" : "-----BEGIN PUBLIC KEY-----";
    QByteArray footer = isPrivate ? "-----END PRIVATE KEY-----" : "-----END PUBLIC KEY-----";
    QByteArray rsaHeader = isPrivate ? "-----BEGIN RSA PRIVATE KEY-----" : "-----BEGIN RSA PUBLIC KEY-----";
    QByteArray rsaFooter = isPrivate ? "-----END RSA PRIVATE KEY-----" : "-----END RSA PUBLIC KEY-----";

    QByteArray data = pemData.trimmed();

    // 移除 PEM 头尾
    int startPos = data.indexOf(header);
    int endPos = data.indexOf(footer);

    if (startPos == -1 || endPos == -1) {
        startPos = data.indexOf(rsaHeader);
        endPos = data.indexOf(rsaFooter);
        if (startPos != -1) {
            startPos += rsaHeader.length();
        }
    } else {
        startPos += header.length();
    }

    if (startPos == -1 || endPos == -1 || startPos >= endPos) {
        LOG_ERROR("RsaCrypto Windows: Invalid PEM format");
        return QByteArray();
    }

    // 提取 Base64 数据
    QByteArray base64Data = data.mid(startPos, endPos - startPos);
    base64Data.replace('\n', "");
    base64Data.replace('\r', "");
    base64Data = base64Data.trimmed();

    // Base64 解码
    return QByteArray::fromBase64(base64Data);
}

/**
 * @brief 从 DER 编码的 SubjectPublicKeyInfo 导入公钥
 */
BCRYPT_KEY_HANDLE importPublicKey(const QByteArray& derData)
{
    BCRYPT_ALG_HANDLE hAlgorithm = NULL;
    BCRYPT_KEY_HANDLE hKey = NULL;

    // 打开 RSA 算法提供程序
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlgorithm, BCRYPT_RSA_ALGORITHM, NULL, 0);
    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptOpenAlgorithmProvider failed: 0x%1").arg(status, 0, 16));
        return NULL;
    }

    // 使用 CryptDecodeObjectEx 解码 SubjectPublicKeyInfo
    CERT_PUBLIC_KEY_INFO* pKeyInfo = NULL;
    DWORD keyInfoSize = 0;

    if (!CryptDecodeObjectEx(
            X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
            X509_PUBLIC_KEY_INFO,
            reinterpret_cast<const BYTE*>(derData.constData()),
            static_cast<DWORD>(derData.size()),
            CRYPT_DECODE_ALLOC_FLAG,
            NULL,
            &pKeyInfo,
            &keyInfoSize)) {
        DWORD err = GetLastError();
        LOG_ERROR(QString("RsaCrypto Windows: CryptDecodeObjectEx failed: 0x%1").arg(err, 0, 16));
        BCryptCloseAlgorithmProvider(hAlgorithm, 0);
        return NULL;
    }

    // 导入公钥到 BCrypt
    // 需要将 CERT_PUBLIC_KEY_INFO 转换为 BCRYPT_RSAKEY_BLOB
    BCRYPT_RSAKEY_BLOB* pRsaBlob = NULL;
    DWORD rsaBlobSize = 0;

    if (!CryptDecodeObjectEx(
            X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
            CNG_RSA_PUBLIC_KEY_BLOB,
            pKeyInfo->PublicKey.pbData,
            pKeyInfo->PublicKey.cbData,
            CRYPT_DECODE_ALLOC_FLAG,
            NULL,
            &pRsaBlob,
            &rsaBlobSize)) {
        DWORD err = GetLastError();
        LOG_ERROR(QString("RsaCrypto Windows: CryptDecodeObjectEx (RSA blob) failed: 0x%1").arg(err, 0, 16));
        LocalFree(pKeyInfo);
        BCryptCloseAlgorithmProvider(hAlgorithm, 0);
        return NULL;
    }

    // 导入密钥
    status = BCryptImportKeyPair(
        hAlgorithm,
        NULL,
        BCRYPT_RSAPUBLIC_BLOB,
        &hKey,
        reinterpret_cast<PUCHAR>(pRsaBlob),
        rsaBlobSize,
        0);

    LocalFree(pRsaBlob);
    LocalFree(pKeyInfo);
    BCryptCloseAlgorithmProvider(hAlgorithm, 0);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptImportKeyPair failed: 0x%1").arg(status, 0, 16));
        return NULL;
    }

    return hKey;
}

/**
 * @brief 从 DER 编码的 PKCS#8 导入私钥
 */
BCRYPT_KEY_HANDLE importPrivateKey(const QByteArray& derData)
{
    BCRYPT_ALG_HANDLE hAlgorithm = NULL;
    BCRYPT_KEY_HANDLE hKey = NULL;

    // 打开 RSA 算法提供程序
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlgorithm, BCRYPT_RSA_ALGORITHM, NULL, 0);
    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptOpenAlgorithmProvider failed: 0x%1").arg(status, 0, 16));
        return NULL;
    }

    // 解码 PKCS#8 私钥
    CRYPT_PRIVATE_KEY_INFO* pKeyInfo = NULL;
    DWORD keyInfoSize = 0;

    if (!CryptDecodeObjectEx(
            X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
            PKCS_PRIVATE_KEY_INFO,
            reinterpret_cast<const BYTE*>(derData.constData()),
            static_cast<DWORD>(derData.size()),
            CRYPT_DECODE_ALLOC_FLAG,
            NULL,
            &pKeyInfo,
            &keyInfoSize)) {
        DWORD err = GetLastError();
        LOG_ERROR(QString("RsaCrypto Windows: CryptDecodeObjectEx (PKCS8) failed: 0x%1").arg(err, 0, 16));
        BCryptCloseAlgorithmProvider(hAlgorithm, 0);
        return NULL;
    }

    // 解码 RSA 私钥 blob
    BCRYPT_RSAKEY_BLOB* pRsaBlob = NULL;
    DWORD rsaBlobSize = 0;

    if (!CryptDecodeObjectEx(
            X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
            CNG_RSA_PRIVATE_KEY_BLOB,
            pKeyInfo->PrivateKey.pbData,
            pKeyInfo->PrivateKey.cbData,
            CRYPT_DECODE_ALLOC_FLAG,
            NULL,
            &pRsaBlob,
            &rsaBlobSize)) {
        DWORD err = GetLastError();
        LOG_ERROR(QString("RsaCrypto Windows: CryptDecodeObjectEx (RSA private blob) failed: 0x%1").arg(err, 0, 16));
        LocalFree(pKeyInfo);
        BCryptCloseAlgorithmProvider(hAlgorithm, 0);
        return NULL;
    }

    // 导入私钥
    status = BCryptImportKeyPair(
        hAlgorithm,
        NULL,
        BCRYPT_RSAFULLPRIVATE_BLOB,
        &hKey,
        reinterpret_cast<PUCHAR>(pRsaBlob),
        rsaBlobSize,
        0);

    LocalFree(pRsaBlob);
    LocalFree(pKeyInfo);
    BCryptCloseAlgorithmProvider(hAlgorithm, 0);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptImportKeyPair (private) failed: 0x%1").arg(status, 0, 16));
        return NULL;
    }

    return hKey;
}

} // anonymous namespace

QByteArray RsaCrypto::encryptWithWindowsBCrypt(const QByteArray& data, const QByteArray& publicKeyPem)
{
    if (data.isEmpty() || publicKeyPem.isEmpty()) {
        LOG_WARNING("RsaCrypto Windows: Empty input");
        return QByteArray();
    }

    QByteArray derData = pemToDer(publicKeyPem, false);
    if (derData.isEmpty()) {
        return QByteArray();
    }

    BCRYPT_KEY_HANDLE hKey = importPublicKey(derData);
    if (!hKey) {
        return QByteArray();
    }

    // 使用 OAEP with SHA-256
    BCRYPT_OAEP_PADDING_INFO paddingInfo;
    paddingInfo.pszAlgId = BCRYPT_SHA256_ALGORITHM;
    paddingInfo.pbLabel = NULL;
    paddingInfo.cbLabel = 0;

    DWORD cbResult = 0;

    // 获取加密后大小
    NTSTATUS status = BCryptEncrypt(
        hKey,
        reinterpret_cast<PUCHAR>(const_cast<char*>(data.constData())),
        static_cast<ULONG>(data.size()),
        &paddingInfo,
        NULL, 0,
        NULL, 0,
        &cbResult,
        BCRYPT_PAD_OAEP);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptEncrypt (size) failed: 0x%1").arg(status, 0, 16));
        BCryptDestroyKey(hKey);
        return QByteArray();
    }

    QByteArray result(static_cast<int>(cbResult), 0);

    status = BCryptEncrypt(
        hKey,
        reinterpret_cast<PUCHAR>(const_cast<char*>(data.constData())),
        static_cast<ULONG>(data.size()),
        &paddingInfo,
        NULL, 0,
        reinterpret_cast<PUCHAR>(result.data()),
        cbResult,
        &cbResult,
        BCRYPT_PAD_OAEP);

    BCryptDestroyKey(hKey);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptEncrypt failed: 0x%1").arg(status, 0, 16));
        return QByteArray();
    }

    result.resize(static_cast<int>(cbResult));
    return result;
}

QByteArray RsaCrypto::decryptWithWindowsBCrypt(const QByteArray& encryptedData, const QByteArray& privateKeyPem)
{
    if (encryptedData.isEmpty() || privateKeyPem.isEmpty()) {
        LOG_WARNING("RsaCrypto Windows: Empty input");
        return QByteArray();
    }

    QByteArray derData = pemToDer(privateKeyPem, true);
    if (derData.isEmpty()) {
        return QByteArray();
    }

    BCRYPT_KEY_HANDLE hKey = importPrivateKey(derData);
    if (!hKey) {
        return QByteArray();
    }

    // 使用 OAEP with SHA-256
    BCRYPT_OAEP_PADDING_INFO paddingInfo;
    paddingInfo.pszAlgId = BCRYPT_SHA256_ALGORITHM;
    paddingInfo.pbLabel = NULL;
    paddingInfo.cbLabel = 0;

    DWORD cbResult = 0;

    // 获取解密后大小
    NTSTATUS status = BCryptDecrypt(
        hKey,
        reinterpret_cast<PUCHAR>(const_cast<char*>(encryptedData.constData())),
        static_cast<ULONG>(encryptedData.size()),
        &paddingInfo,
        NULL, 0,
        NULL, 0,
        &cbResult,
        BCRYPT_PAD_OAEP);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptDecrypt (size) failed: 0x%1").arg(status, 0, 16));
        BCryptDestroyKey(hKey);
        return QByteArray();
    }

    QByteArray result(static_cast<int>(cbResult), 0);

    status = BCryptDecrypt(
        hKey,
        reinterpret_cast<PUCHAR>(const_cast<char*>(encryptedData.constData())),
        static_cast<ULONG>(encryptedData.size()),
        &paddingInfo,
        NULL, 0,
        reinterpret_cast<PUCHAR>(result.data()),
        cbResult,
        &cbResult,
        BCRYPT_PAD_OAEP);

    BCryptDestroyKey(hKey);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptDecrypt failed: 0x%1").arg(status, 0, 16));
        return QByteArray();
    }

    result.resize(static_cast<int>(cbResult));
    return result;
}

QByteArray RsaCrypto::signWithWindowsBCrypt(const QByteArray& data, const QByteArray& privateKeyPem)
{
    if (data.isEmpty() || privateKeyPem.isEmpty()) {
        LOG_WARNING("RsaCrypto Windows: Empty input");
        return QByteArray();
    }

    QByteArray derData = pemToDer(privateKeyPem, true);
    if (derData.isEmpty()) {
        return QByteArray();
    }

    BCRYPT_KEY_HANDLE hKey = importPrivateKey(derData);
    if (!hKey) {
        return QByteArray();
    }

    // 计算 SHA-256 哈希
    BCRYPT_ALG_HANDLE hHashAlg = NULL;
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hHashAlg, BCRYPT_SHA256_ALGORITHM, NULL, 0);
    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptOpenAlgorithmProvider (hash) failed: 0x%1").arg(status, 0, 16));
        BCryptDestroyKey(hKey);
        return QByteArray();
    }

    DWORD cbHash = 0;
    DWORD cbResult = 0;
    BCryptGetProperty(hHashAlg, BCRYPT_HASH_LENGTH, reinterpret_cast<PUCHAR>(&cbHash), sizeof(DWORD), &cbResult, 0);

    QByteArray hash(static_cast<int>(cbHash), 0);

    status = BCryptHash(
        hHashAlg,
        NULL, 0,
        reinterpret_cast<PUCHAR>(const_cast<char*>(data.constData())),
        static_cast<ULONG>(data.size()),
        reinterpret_cast<PUCHAR>(hash.data()),
        cbHash);

    BCryptCloseAlgorithmProvider(hHashAlg, 0);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptHash failed: 0x%1").arg(status, 0, 16));
        BCryptDestroyKey(hKey);
        return QByteArray();
    }

    // PKCS1 v1.5 签名
    BCRYPT_PKCS1_PADDING_INFO paddingInfo;
    paddingInfo.pszAlgId = BCRYPT_SHA256_ALGORITHM;

    // 获取签名大小
    status = BCryptSignHash(
        hKey,
        &paddingInfo,
        reinterpret_cast<PUCHAR>(hash.data()),
        cbHash,
        NULL, 0,
        &cbResult,
        BCRYPT_PAD_PKCS1);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptSignHash (size) failed: 0x%1").arg(status, 0, 16));
        BCryptDestroyKey(hKey);
        return QByteArray();
    }

    QByteArray signature(static_cast<int>(cbResult), 0);

    status = BCryptSignHash(
        hKey,
        &paddingInfo,
        reinterpret_cast<PUCHAR>(hash.data()),
        cbHash,
        reinterpret_cast<PUCHAR>(signature.data()),
        cbResult,
        &cbResult,
        BCRYPT_PAD_PKCS1);

    BCryptDestroyKey(hKey);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptSignHash failed: 0x%1").arg(status, 0, 16));
        return QByteArray();
    }

    signature.resize(static_cast<int>(cbResult));
    return signature;
}

bool RsaCrypto::verifyWithWindowsBCrypt(const QByteArray& data, const QByteArray& signature,
                                        const QByteArray& publicKeyPem)
{
    if (data.isEmpty() || signature.isEmpty() || publicKeyPem.isEmpty()) {
        LOG_WARNING("RsaCrypto Windows: Empty input");
        return false;
    }

    QByteArray derData = pemToDer(publicKeyPem, false);
    if (derData.isEmpty()) {
        return false;
    }

    BCRYPT_KEY_HANDLE hKey = importPublicKey(derData);
    if (!hKey) {
        return false;
    }

    // 计算 SHA-256 哈希
    BCRYPT_ALG_HANDLE hHashAlg = NULL;
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hHashAlg, BCRYPT_SHA256_ALGORITHM, NULL, 0);
    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptOpenAlgorithmProvider (hash) failed: 0x%1").arg(status, 0, 16));
        BCryptDestroyKey(hKey);
        return false;
    }

    DWORD cbHash = 0;
    DWORD cbResult = 0;
    BCryptGetProperty(hHashAlg, BCRYPT_HASH_LENGTH, reinterpret_cast<PUCHAR>(&cbHash), sizeof(DWORD), &cbResult, 0);

    QByteArray hash(static_cast<int>(cbHash), 0);

    status = BCryptHash(
        hHashAlg,
        NULL, 0,
        reinterpret_cast<PUCHAR>(const_cast<char*>(data.constData())),
        static_cast<ULONG>(data.size()),
        reinterpret_cast<PUCHAR>(hash.data()),
        cbHash);

    BCryptCloseAlgorithmProvider(hHashAlg, 0);

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptHash failed: 0x%1").arg(status, 0, 16));
        BCryptDestroyKey(hKey);
        return false;
    }

    // 验证签名
    BCRYPT_PKCS1_PADDING_INFO paddingInfo;
    paddingInfo.pszAlgId = BCRYPT_SHA256_ALGORITHM;

    status = BCryptVerifySignature(
        hKey,
        &paddingInfo,
        reinterpret_cast<PUCHAR>(hash.data()),
        cbHash,
        reinterpret_cast<PUCHAR>(const_cast<char*>(signature.constData())),
        static_cast<ULONG>(signature.size()),
        BCRYPT_PAD_PKCS1);

    BCryptDestroyKey(hKey);

    if (status == STATUS_INVALID_SIGNATURE) {
        LOG_WARNING("RsaCrypto Windows: Invalid signature");
        return false;
    }

    if (!BCRYPT_SUCCESS(status)) {
        LOG_ERROR(QString("RsaCrypto Windows: BCryptVerifySignature failed: 0x%1").arg(status, 0, 16));
        return false;
    }

    return true;
}

#endif // Q_OS_WIN
