using CashLedgerAndroid.Pages;
using CashLedgerAndroid.Services;
using CashLedgerAndroid.Views;

namespace CashLedgerAndroid;

public class AppShell : Shell
{
    public AppShell(LedgerDatabase db)
    {
        FlyoutBehavior = FlyoutBehavior.Disabled;
        SetBackgroundColor(this, Pal.BlueDark);
        SetForegroundColor(this, Colors.White);
        SetTitleColor(this, Colors.White);
        SetTabBarBackgroundColor(this, Colors.White);
        SetTabBarForegroundColor(this, Pal.Blue);
        SetTabBarTitleColor(this, Pal.Blue);
        SetTabBarUnselectedColor(this, Pal.Muted);

        var bar = new TabBar();
        // Use custom images in Resources/Images for tab icons. New assets added with _new suffix.
        bar.Items.Add(new ShellContent { Title = "Home", Icon = "home_new.svg", Content = new HomePage(db) });
        bar.Items.Add(new ShellContent { Title = "History", Icon = "history_new.svg", Content = new HistoryPage(db) });
        var updater = MauiProgram.Services?.GetService(typeof(CashLedgerAndroid.Services.IUpdateService)) as CashLedgerAndroid.Services.IUpdateService;
        bar.Items.Add(new ShellContent { Title = "Settings", Icon = "settings_new.svg", Content = new SettingsPage(db, updater) });
        Items.Add(bar);
    }

    public static void ShowTab(int index)
    {
        try
        {
            if (Current is Shell shell && shell.Items.Count > 0)
            {
                var tabs = shell.Items[0];
                if (index >= 0 && index < tabs.Items.Count)
                    shell.CurrentItem = tabs.Items[index];
            }
        }
        catch
        {
            // Switching tabs is a convenience; ignore if the shell is not ready.
        }
    }
}
