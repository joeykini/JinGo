// android/src/work/opine/jingo/SecureStorage.java
package work.opine.jingo;

import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

public class SecureStorage {
    private static final String KEYSTORE_PROVIDER = "AndroidKeyStore";
    private static final String TRANSFORMATION = "AES/GCM/NoPadding";
    private static final int GCM_TAG_LENGTH = 128;
    private static Context sContext = null;

    // Initialize with context from Qt C++ side
    public static void initialize(Context context) {
        sContext = context.getApplicationContext();
    }

    public static boolean saveSecret(String service, String key, String value) {
        try {
            SecretKey secretKey = getOrCreateKey(service + "_" + key);

            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey);

            byte[] iv = cipher.getIV();
            byte[] encrypted = cipher.doFinal(value.getBytes(StandardCharsets.UTF_8));

            // 保存 IV 和加密数据
            SharedPreferences prefs = getPreferences();
            if (prefs == null) {
                return false;
            }

            String ivStr = Base64.encodeToString(iv, Base64.DEFAULT);
            String encryptedStr = Base64.encodeToString(encrypted, Base64.DEFAULT);

            prefs.edit()
                .putString(key + "_iv", ivStr)
                .putString(key + "_data", encryptedStr)
                .apply();

            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public static String loadSecret(String service, String key) {
        try {
            SharedPreferences prefs = getPreferences();
            if (prefs == null) {
                return null;
            }

            String ivStr = prefs.getString(key + "_iv", null);
            String encryptedStr = prefs.getString(key + "_data", null);

            if (ivStr == null || encryptedStr == null) {
                return null;
            }

            SecretKey secretKey = getOrCreateKey(service + "_" + key);

            byte[] iv = Base64.decode(ivStr, Base64.DEFAULT);
            byte[] encrypted = Base64.decode(encryptedStr, Base64.DEFAULT);

            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));

            byte[] decrypted = cipher.doFinal(encrypted);
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public static boolean deleteSecret(String service, String key) {
        SharedPreferences prefs = getPreferences();
        if (prefs == null) {
            return false;
        }
        prefs.edit()
            .remove(key + "_iv")
            .remove(key + "_data")
            .apply();
        return true;
    }

    public static boolean clearAll(String service) {
        SharedPreferences prefs = getPreferences();
        if (prefs == null) {
            return false;
        }
        prefs.edit().clear().apply();
        return true;
    }
    
    private static SecretKey getOrCreateKey(String alias) throws Exception {
        KeyStore keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER);
        keyStore.load(null);
        
        if (!keyStore.containsAlias(alias)) {
            KeyGenerator keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER);
            
            keyGenerator.init(new KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build());
            
            return keyGenerator.generateKey();
        }
        
        return (SecretKey) keyStore.getKey(alias, null);
    }
    
    private static SharedPreferences getPreferences() {
        if (sContext == null) {
            android.util.Log.e("SecureStorage", "Context not initialized. Call initialize() first.");
            return null;
        }
        try {
            return sContext.getSharedPreferences("JinGoSecureStorage", Context.MODE_PRIVATE);
        } catch (Exception e) {
            android.util.Log.e("SecureStorage", "Error getting SharedPreferences", e);
            return null;
        }
    }
}
