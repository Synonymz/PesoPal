using Microsoft.Maui.Controls.Shapes;

namespace CashLedgerAndroid.Views;

// Colour palette used across all screens.
public static class Pal
{
    public static readonly Color Blue = Color.FromArgb("#0066F0");
    public static readonly Color BlueDark = Color.FromArgb("#0A47BE");
    public static readonly Color Navy = Color.FromArgb("#0B2A5B");
    public static readonly Color Muted = Color.FromArgb("#5B6B84");
    public static readonly Color Bg = Color.FromArgb("#EEF3FA");
    public static readonly Color Line = Color.FromArgb("#E1E8F2");
    public static readonly Color Green = Color.FromArgb("#087F49");
    public static readonly Color GreenBg = Color.FromArgb("#E3F5EC");
    public static readonly Color BlueBg = Color.FromArgb("#E3EFFF");
    public static readonly Color Red = Color.FromArgb("#C62828");
    public static readonly Color RedBg = Color.FromArgb("#FDECEC");
    public static readonly Color Amber = Color.FromArgb("#8A5200");
    public static readonly Color AmberBg = Color.FromArgb("#FFF1D6");
    public static readonly Color FieldLine = Color.FromArgb("#CCD9EC");
}

// Small helpers that keep the page code short.
public static class Ui
{
    public static Label Text(string text, double size = 14, bool bold = false, Color? color = null, TextAlignment align = TextAlignment.Start)
    {
        return new Label
        {
            Text = text,
            FontSize = size,
            FontAttributes = bold ? FontAttributes.Bold : FontAttributes.None,
            TextColor = color ?? Pal.Navy,
            HorizontalTextAlignment = align
        };
    }

    public static Border Card(View content, double radius = 20, Thickness? padding = null, Color? background = null)
    {
        return new Border
        {
            Content = content,
            StrokeThickness = 0,
            Padding = padding ?? new Thickness(16),
            BackgroundColor = background ?? Colors.White,
            StrokeShape = new RoundRectangle { CornerRadius = radius }
        };
    }

    public static BoxView Divider()
    {
        return new BoxView { HeightRequest = 1, Color = Pal.Line, HorizontalOptions = LayoutOptions.Fill };
    }

    public static Button Primary(string text, Color color, Func<Task> onClick)
    {
        var button = new Button
        {
            Text = text,
            BackgroundColor = color,
            TextColor = Colors.White,
            FontAttributes = FontAttributes.Bold,
            FontSize = 15,
            CornerRadius = 26,
            HeightRequest = 52
        };
        button.Clicked += async (_, _) => await onClick();
        try { button.Behaviors.Add(new CashLedgerAndroid.Controls.ButtonPressBehavior()); } catch { }
        try { AutomationProperties.SetIsInAccessibleTree(button, true); } catch { }
        return button;
    }

    public static Button Outline(string text, Func<Task> onClick)
    {
        var button = new Button
        {
            Text = text,
            BackgroundColor = Colors.White,
            TextColor = Pal.Navy,
            BorderColor = Pal.FieldLine,
            BorderWidth = 1.5,
            FontAttributes = FontAttributes.Bold,
            FontSize = 15,
            CornerRadius = 26,
            HeightRequest = 52
        };
        button.Clicked += async (_, _) => await onClick();
        try { button.Behaviors.Add(new CashLedgerAndroid.Controls.ButtonPressBehavior()); } catch { }
        try { AutomationProperties.SetIsInAccessibleTree(button, true); } catch { }
        return button;
    }

    public static Border Chip(string text, bool selected, Func<Task> onTap)
    {
        var chip = new Border
        {
            StrokeThickness = 1.5,
            Stroke = new SolidColorBrush(selected ? Pal.Blue : Color.FromArgb("#BFD6F8")),
            BackgroundColor = selected ? Pal.Blue : Color.FromArgb("#F2F8FF"),
            Padding = new Thickness(14, 8),
            StrokeShape = new RoundRectangle { CornerRadius = 20 },
            Content = new Label
            {
                Text = text,
                FontSize = 13,
                FontAttributes = FontAttributes.Bold,
                TextColor = selected ? Colors.White : Pal.Blue,
                VerticalTextAlignment = TextAlignment.Center
            }
        };
        var tap = new TapGestureRecognizer();
        tap.Tapped += async (_, _) => await onTap();
        chip.GestureRecognizers.Add(tap);
        return chip;
    }

    // A tappable settings row: title on the left, current value on the right.
    public static View SettingRow(string title, string value, Func<Task> onTap)
    {
        var row = new Grid
        {
            ColumnDefinitions = { new ColumnDefinition(GridLength.Star), new ColumnDefinition(GridLength.Auto) },
            Padding = new Thickness(0, 14),
            ColumnSpacing = 10,
            MinimumHeightRequest = 48
        };
        var left = Text(title, 14, true);
        left.VerticalOptions = LayoutOptions.Center;
        var right = Text(value + "  ›", 14, false, Pal.Muted, TextAlignment.End);
        right.VerticalOptions = LayoutOptions.Center;
        row.Add(left, 0, 0);
        row.Add(right, 1, 0);
        var tap = new TapGestureRecognizer();
        tap.Tapped += async (_, _) => await onTap();
        row.GestureRecognizers.Add(tap);
        return row;
    }

    public static Border Field(string caption, View input)
    {
        var stack = new VerticalStackLayout { Spacing = 0 };
        stack.Add(Text(caption, 11, true, Pal.Muted));
        stack.Add(input);
        return new Border
        {
            StrokeThickness = 1.5,
            Stroke = new SolidColorBrush(Pal.FieldLine),
            BackgroundColor = Colors.White,
            Padding = new Thickness(14, 6, 14, 2),
            StrokeShape = new RoundRectangle { CornerRadius = 14 },
            Content = stack
        };
    }

    public static Entry PlainEntry(string placeholder = "", Keyboard? keyboard = null, int maxLength = -1)
    {
        var entry = new Entry
        {
            Placeholder = placeholder,
            PlaceholderColor = Color.FromArgb("#8896AD"),
            TextColor = Pal.Navy,
            FontSize = 16,
            BackgroundColor = Colors.Transparent,
            Keyboard = keyboard ?? Keyboard.Default
        };
        if (maxLength > 0) entry.MaxLength = maxLength;
        return entry;
    }

    // Status banner: kind is "ok", "warn", "info" or "bad".
    public static void StyleNote(Border note, Label label, string kind, string text)
    {
        label.Text = text;
        switch (kind)
        {
            case "ok":
                note.BackgroundColor = Pal.GreenBg; label.TextColor = Pal.Green; break;
            case "bad":
                note.BackgroundColor = Pal.RedBg; label.TextColor = Pal.Red; break;
            case "info":
                note.BackgroundColor = Pal.BlueBg; label.TextColor = Pal.BlueDark; break;
            default:
                note.BackgroundColor = Pal.AmberBg; label.TextColor = Pal.Amber; break;
        }
    }

    public static (Border, Label) Note(string kind, string text)
    {
        var label = new Label { FontSize = 13, FontAttributes = FontAttributes.Bold };
        var border = new Border
        {
            StrokeThickness = 0,
            Padding = new Thickness(14, 12),
            StrokeShape = new RoundRectangle { CornerRadius = 14 },
            Content = label
        };
        StyleNote(border, label, kind, text);
        return (border, label);
    }
}
