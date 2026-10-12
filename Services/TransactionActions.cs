using CashLedgerAndroid.Models;
using CashLedgerAndroid.Pages;

namespace CashLedgerAndroid.Services;

// The menu that opens when you tap a transaction: receipt, edit, void/restore, delete.
public static class TransactionActions
{
    public static async Task ShowMenuAsync(Page page, LedgerDatabase db, TransactionRecord t)
    {
        var receipt = "Share receipt";
        var edit = "Edit details";
        var voidOrRestore = t.IsVoided ? "Restore (un-void)" : "Void";
        var delete = "Delete permanently";
        var title = "TX-" + t.Id.ToString("000000") + " · " + t.Type + " · " + Fmt.Money(t.Amount) + (t.IsVoided ? " (VOID)" : "");

        var choice = await page.DisplayActionSheetAsync(title, "Close", delete, receipt, edit, voidOrRestore);
        if (choice == receipt)
        {
            var settings = await db.GetSettingsAsync();
            await ReceiptService.ShareAsync(settings, t);
        }
        else if (choice == edit)
        {
            await page.Navigation.PushModalAsync(new EntryPage(db, t.Type, t));
        }
        else if (choice == voidOrRestore)
        {
            if (t.IsVoided) await RestoreAsync(page, db, t);
            else await VoidAsync(page, db, t);
        }
        else if (choice == delete)
        {
            await DeleteAsync(page, db, t);
        }
    }

    private static async Task VoidAsync(Page page, LedgerDatabase db, TransactionRecord t)
    {
        var other = "Other reason…";
        var skip = "No reason";
        var reason = await page.DisplayActionSheetAsync(
            "Void TX-" + t.Id.ToString("000000") + "? It stays in history but no longer counts in totals. You can restore it later.",
            "Cancel", null, "Wrong amount", "Wrong customer", "Customer cancelled", other, skip);
        if (string.IsNullOrEmpty(reason) || reason == "Cancel") return;

        var text = reason;
        if (reason == skip) text = "";
        if (reason == other)
        {
            var typed = await page.DisplayPromptAsync("Void reason", "Reason (optional):", "Void", "Cancel", maxLength: 200);
            if (typed is null) return;
            text = typed.Trim();
        }

        t.IsVoided = true;
        t.VoidedAt = DateTime.Now;
        t.VoidReason = text;
        await db.UpdateTransactionAsync(t);
    }

    private static async Task RestoreAsync(Page page, LedgerDatabase db, TransactionRecord t)
    {
        var ok = await page.DisplayAlertAsync("Restore transaction",
            "Count TX-" + t.Id.ToString("000000") + " in totals again?", "Restore", "Cancel");
        if (!ok) return;
        t.IsVoided = false;
        t.VoidedAt = null;
        t.VoidReason = "";
        await db.UpdateTransactionAsync(t);
    }

    private static async Task DeleteAsync(Page page, LedgerDatabase db, TransactionRecord t)
    {
        var voidInstead = "Void instead";
        var delete = "Delete permanently";
        var choice = await page.DisplayActionSheetAsync(
            "Delete TX-" + t.Id.ToString("000000") + " permanently? It cannot be recovered. Voiding is safer because it keeps a record.",
            "Cancel", delete, voidInstead);
        if (choice == delete)
        {
            await db.DeleteTransactionAsync(t);
        }
        else if (choice == voidInstead)
        {
            if (!t.IsVoided) await VoidAsync(page, db, t);
        }
    }
}
