package work.opine.jingo;

import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.WindowInsetsController;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import org.qtproject.qt.android.bindings.QtActivity;

public class JinGoActivity extends QtActivity {

    @SuppressWarnings("deprecation")
    private void applyStatusBarSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = getWindow();
            if (window == null) {
                android.util.Log.e("JinGoActivity", "Window is null, cannot set status bar");
                return;
            }

            // 启用绘制系统栏背景
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);

            // 设置状态栏和导航栏为完全透明
            window.setStatusBarColor(0x00000000);  // 完全透明
            window.setNavigationBarColor(0x00000000);  // 完全透明

            // 使用 WindowCompat 设置布局延伸到系统栏下方
            WindowCompat.setDecorFitsSystemWindows(window, false);

            // 使用 WindowInsetsControllerCompat 设置图标颜色
            WindowInsetsControllerCompat insetsController = WindowCompat.getInsetsController(window, window.getDecorView());
            if (insetsController != null) {
                // 设置深色图标（适配浅色背景）
                insetsController.setAppearanceLightStatusBars(true);
                insetsController.setAppearanceLightNavigationBars(true);
                android.util.Log.d("JinGoActivity", "Transparent bars applied using WindowInsetsControllerCompat");
            }
        }
    }

    public void setupStatusBar() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                applyStatusBarSettings();
            }
        });
    }

    // 设置状态栏图标颜色（供QML调用）
    public void setStatusBarIconsLight(boolean useLightIcons) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Window window = getWindow();
                    if (window != null) {
                        WindowInsetsControllerCompat insetsController = WindowCompat.getInsetsController(window, window.getDecorView());
                        if (insetsController != null) {
                            // useLightIcons = true 表示使用浅色图标（深色模式）
                            // useLightIcons = false 表示使用深色图标（浅色模式）
                            insetsController.setAppearanceLightStatusBars(!useLightIcons);
                            insetsController.setAppearanceLightNavigationBars(!useLightIcons);
                            android.util.Log.d("JinGoActivity", "Status bar icons set to " + (useLightIcons ? "light" : "dark"));
                        }
                    }
                }
            });
        }
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 初始化时设置一次透明状态栏
        forceTransparentBars();
    }

    @SuppressWarnings("deprecation")
    private void forceTransparentBars() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = getWindow();
            if (window == null) return;

            // 启用绘制系统栏背景
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);

            // 强制设置透明
            window.setStatusBarColor(0x00000000);
            window.setNavigationBarColor(0x00000000);

            // 使用 WindowCompat 设置布局延伸到系统栏下方
            WindowCompat.setDecorFitsSystemWindows(window, false);

            // 使用 WindowInsetsControllerCompat 设置图标颜色
            WindowInsetsControllerCompat insetsController = WindowCompat.getInsetsController(window, window.getDecorView());
            if (insetsController != null) {
                // 设置深色图标（适合浅色背景）
                insetsController.setAppearanceLightStatusBars(true);
                insetsController.setAppearanceLightNavigationBars(true);
                android.util.Log.d("JinGoActivity", "forceTransparentBars: Using WindowInsetsControllerCompat");
            }
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        android.util.Log.d("JinGoActivity", "onResume: Applying status bar settings");
        applyStatusBarSettings();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            android.util.Log.d("JinGoActivity", "onWindowFocusChanged: Applying status bar settings");
            applyStatusBarSettings();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }
}
