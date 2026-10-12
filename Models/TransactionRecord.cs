using SQLite;

namespace CashLedgerAndroid.Models;

public class TransactionRecord
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }
    public string CustomerName { get; set; } = "";
    public string Type { get; set; } = "Cash-In";
    public decimal Amount { get; set; }
    public decimal Fee { get; set; }
    public string ReferenceNumber { get; set; } = "";
    public string Notes { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Voided transactions stay in history for the audit trail but are left out of totals.
    public bool IsVoided { get; set; }
    public DateTime? VoidedAt { get; set; }
    public string VoidReason { get; set; } = "";
    public DateTime? EditedAt { get; set; }

    [Ignore]
    public bool IsCashIn => Type == "Cash-In";
}
