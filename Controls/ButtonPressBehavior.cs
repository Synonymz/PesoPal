using System;
using System.Threading.Tasks;
using Microsoft.Maui.Controls;
// Haptics APIs may not be available on all targets; keep behavior lightweight and optional.

namespace CashLedgerAndroid.Controls;

public class ButtonPressBehavior : Behavior<Button>
{
    private Button? _button;

    protected override void OnAttachedTo(Button bindable)
    {
        base.OnAttachedTo(bindable);
        _button = bindable;
        _button.Pressed += OnPressed;
        _button.Released += OnReleased;
    }

    protected override void OnDetachingFrom(Button bindable)
    {
        base.OnDetachingFrom(bindable);
        if (_button is null) return;
        _button.Pressed -= OnPressed;
        _button.Released -= OnReleased;
        _button = null;
    }

    private void OnPressed(object? sender, EventArgs e)
    {
        _ = PressAnimateAsync(_button);
    }

    private void OnReleased(object? sender, EventArgs e)
    {
        _ = ReleaseAnimateAsync(_button);
    }

    private async Task PressAnimateAsync(Button? btn)
    {
        if (btn is null) return;
        try { await btn.ScaleToAsync(0.98, 50, Easing.CubicIn); } catch { }
    }

    private async Task ReleaseAnimateAsync(Button? btn)
    {
        if (btn is null) return;
        try { await btn.ScaleToAsync(1.0, 80, Easing.CubicOut); } catch { }
    }
}
