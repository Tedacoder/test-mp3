Config = {}

Config.Framework = "QBOX" -- "QBOX", "QB", "ESX", "Standalone"
Config.UseOxTarget = true
Config.UseOxLib = true

Config.Keys = {
    ItemName = "vehicle_key",
    AdminKey = "admin_key"
}

Config.Impound = {
    StolenAutoImpound = true,
    AbandonedTimeHours = 24,
    BaseFee = 500
}

Config.Theft = {
    RequireUnlockedToSteal = true,
    AllowVinTampering = true
}

Config.Dealership = {
    UseCreditScore = true,
    RequireDriversLicense = true,
    DefaultDownPaymentPercent = 20,
    WeeklyPaymentIntervalHours = 168
}
