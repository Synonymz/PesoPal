using CashLedgerAndroid.Models;
using CashLedgerAndroid.Services;
using Microsoft.Maui.Controls.Shapes;

namespace CashLedgerAndroid.Views;

public static class TransactionRow
{
    private static string When(TransactionRecord t)
    {
        var time = t.CreatedAt.ToString("h:mm tt", Fmt.Inv);
        return t.CreatedAt.Date == DateTime.Today ? time : t.CreatedAt.ToString("MMM d", Fmt.Inv) + ", " + time;
    }

    public static View Create(TransactionRecord t, Func<TransactionRecord, Task> onTap)
    {
        var isIn = t.IsCashIn;
        var tint = isIn ? Pal.GreenBg : Pal.BlueBg;
        var ink = isIn ? Pal.Green : Pal.BlueDark;

        var row = new Grid
        {
            ColumnDefinitions =
            {
                new ColumnDefinition(GridLength.Auto),
                new ColumnDefinition(GridLength.Star),
                new ColumnDefinition(GridLength.Auto)
            },
            ColumnSpacing = 12,
            Padding = new Thickness(0, 11)
        };

        var icon = new Border
        {
            WidthRequest = 46,
            HeightRequest = 46,
            StrokeThickness = 0,
            BackgroundColor = tint,
            StrokeShape = new RoundRectangle { CornerRadius = 14 },
            VerticalOptions = LayoutOptions.Center,
            Content = new Label
            {
                Text = isIn ? "↓" : "↑",
                FontSize = 22,
                FontAttributes = FontAttributes.Bold,
                TextColor = ink,
                HorizontalTextAlignment = TextAlignment.Center,
                VerticalTextAlignment = TextAlignment.Center
            }
        };

        var customer = string.IsNullOrWhiteSpace(t.CustomerName) ? "Walk-in" : t.CustomerName;
        var details = new VerticalStackLayout { Spacing = 2, VerticalOptions = LayoutOptions.Center };
        var title = Ui.Text(isIn ? "Cash-in" : "Cash-out", 17, true);
        var sub = Ui.Text(customer + " · " + When(t) + " · TX-" + t.Id.ToString("000000"), 12, false, Pal.Muted);
        sub.LineBreakMode = LineBreakMode.TailTruncation;
        sub.MaxLines = 1;
        details.Add(title);
        details.Add(sub);

        var amounts = new VerticalStackLayout { Spacing = 2, VerticalOptions = LayoutOptions.Center, HorizontalOptions = LayoutOptions.End };
        var amount = Ui.Text(Fmt.MoneyShort(t.Amount), 17, true, Pal.Navy, TextAlignment.End);
        amounts.Add(amount);

        if (t.IsVoided)
        {
            row.Opacity = 0.6;
            amount.TextDecorations = TextDecorations.Strikethrough;
            title.TextDecorations = TextDecorations.Strikethrough;
            var reason = string.IsNullOrWhiteSpace(t.VoidReason) ? "VOID" : "VOID · " + t.VoidReason;
            var badge = Ui.Text(reason, 10, true, Pal.Red);
            badge.LineBreakMode = LineBreakMode.TailTruncation;
            badge.MaxLines = 1;
            details.Add(badge);
        }
        else
        {
            amounts.Add(Ui.Text("+" + Fmt.MoneyShort(t.Fee), 13, true, Pal.Green, TextAlignment.End));
        }

        row.Add(icon, 0, 0);
        row.Add(details, 1, 0);
        row.Add(amounts, 2, 0);

        var tap = new TapGestureRecognizer();
        tap.Tapped += async (_, _) => await onTap(t);
        row.GestureRecognizers.Add(tap);
        return row;
    }
}
