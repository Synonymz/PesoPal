using System.Threading.Tasks;

namespace CashLedgerAndroid.Services;

public record UpdateInfo(int VersionCode, string VersionName, string ApkUrl, string? Sha256);

public interface IUpdateService
{
    // Checks a JSON metadata URL for update info. Returns UpdateInfo if update available, otherwise null.
    Task<UpdateInfo?> CheckForUpdateAsync(string metadataUrl);

    // Starts the update download & install flow for the provided UpdateInfo.
    Task StartUpdateAsync(UpdateInfo info);

    // Cancel any ongoing download/update in progress.
    Task CancelCurrentUpdateAsync();
}
