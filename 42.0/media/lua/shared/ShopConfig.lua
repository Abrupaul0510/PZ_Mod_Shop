ProjectShopee = ProjectShopee or {}
ProjectShopee.Shared = {}

-- A list of valid shop items, defaults, and current shop tiles.
-- The server will push this config to clients.
ProjectShopee.Config = {
    Shops = {},
    Checkouts = {},
    ATMs = {},
    MoneyRatios = {
        ["Base.Money"] = 1,
        ["Base.MoneyBundle"] = 100
    },
    PersonalShopWhitelist = {},
    PersonalShops = {},
    Catalog = {
        Buy = {},
        Sell = {},
        Limits = {}
    },
    BankBalances = {},
    TransactionLogs = {}
}

-- Network command registry
ProjectShopee.Commands = {
    SyncConfig = "ProjectShopee_SyncConfig",
    SyncLogs = "ProjectShopee_SyncLogs",
    UpdateCatalog = "ProjectShopee_UpdateCatalog",
    AddShop = "ProjectShopee_AddShop",
    RemoveShop = "ProjectShopee_RemoveShop",
    RenameShop = "ProjectShopee_RenameShop",
    AddCheckout = "ProjectShopee_AddCheckout",
    RemoveCheckout = "ProjectShopee_RemoveCheckout",
    AddATM = "ProjectShopee_AddATM",
    RemoveATM = "ProjectShopee_RemoveATM",
    UpdateMoneyRatios = "ProjectShopee_UpdateMoneyRatios",
    DepositMoney = "ProjectShopee_DepositMoney",
    TransferMoney = "ProjectShopee_TransferMoney",
    UpdateTileStock = "ProjectShopee_UpdateTileStock",
    CheckoutCart = "ProjectShopee_CheckoutCart",
    SellItem = "ProjectShopee_SellItem",
    RequestConfig = "ProjectShopee_RequestConfig",
    AdminRequestLogs = "ProjectShopee_AdminRequestLogs",
    AdminSetMoney = "ProjectShopee_AdminSetMoney",
    RequestOpenCheckout = "ProjectShopee_RequestOpenCheckout",
    CloseCheckout = "ProjectShopee_CloseCheckout",
    
    -- Personal Shop Commands
    AdminSetPSWhitelist = "ProjectShopee_AdminSetPSWhitelist",
    CreatePersonalShop = "ProjectShopee_CreatePersonalShop",
    RemovePersonalShop = "ProjectShopee_RemovePersonalShop",
    AddItemToPersonalShop = "ProjectShopee_AddItemToPersonalShop",
    BuyFromPersonalShop = "ProjectShopee_BuyFromPersonalShop",
    CollectPSEarnings = "ProjectShopee_CollectPSEarnings",
    RenamePersonalShop = "ProjectShopee_RenamePersonalShop",
    RemoveItemFromPersonalShop = "ProjectShopee_RemoveItemFromPersonalShop",
    RelocatePersonalShop = "ProjectShopee_RelocatePersonalShop",
    TogglePersonalShopStatus = "ProjectShopee_TogglePersonalShopStatus"
}

function ProjectShopee.Shared.GetPosString(square)
    if not square then return "" end
    return square:getX() .. "," .. square:getY() .. "," .. square:getZ()
end

function ProjectShopee.Shared.IsShop(square)
    if not square then return false end
    local pos = ProjectShopee.Shared.GetPosString(square)
    return type(ProjectShopee.Config.Shops[pos]) == "table"
end

function ProjectShopee.Shared.IsATM(square)
    if not square then return false end
    local pos = ProjectShopee.Shared.GetPosString(square)
    return ProjectShopee.Config.ATMs[pos] == true
end
