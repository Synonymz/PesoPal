using System.Globalization;

namespace CashLedgerAndroid.Services;

public static class Fmt
{
    public static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

    // Example: ₱1,500.00
    public static string Money(decimal value) => "₱" + value.ToString("#,##0.00", Inv);

    // Example: ₱1,500 (whole pesos) or ₱1,500.50
    public static string MoneyShort(decimal value) =>
        value == decimal.Truncate(value) ? "₱" + value.ToString("#,##0", Inv) : Money(value);

    // Plain number for text boxes, example: 1500 or 1500.5
    public static string Num(decimal value) => value.ToString("0.##", Inv);

    public static bool TryParse(string? text, out decimal value)
    {
        value = 0;
        if (string.IsNullOrWhiteSpace(text)) return false;
        var cleaned = text.Trim().Replace("₱", "").Replace(",", "").Replace(" ", "");
        return decimal.TryParse(cleaned, NumberStyles.Number, Inv, out value);
    }
}
