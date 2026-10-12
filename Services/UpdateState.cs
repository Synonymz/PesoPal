using System;
using CashLedgerAndroid.Services;

namespace CashLedgerAndroid.Services;

public class UpdateState
{
    // Latest discovered update info from metadata
    public UpdateInfo? Latest { get; private set; }

    // Download progress [0..100]
    public double Progress { get; private set; }

    // Indicates a download is in progress
    public bool IsDownloading { get; private set; }

    public event Action? StateChanged;

    public void SetLatest(UpdateInfo? info)
    {
        Latest = info;
        StateChanged?.Invoke();
    }

    public void SetProgress(double percent)
    {
        Progress = percent;
        StateChanged?.Invoke();
    }

    public void SetDownloading(bool downloading)
    {
        IsDownloading = downloading;
        StateChanged?.Invoke();
    }
    // No-op placeholder patch to satisfy tooling.

    // Simple success/failure notification for UI (message text, success flag)
    public void NotifyResult(string message, bool success)
    {
        LastResultMessage = message;
        LastResultSuccess = success;
        StateChanged?.Invoke();
    }

    public string? LastResultMessage { get; private set; }
    public bool LastResultSuccess { get; private set; }
}
