module my_project::basic_coin {
    use std::signer;
    use std::option::{Self, Option};
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};
    use aptos_framework::account;
    use aptos_framework::timestamp;

    /// Errors
    const EINSUFFICIENT_BALANCE: u64 = 1;
    const EALREADY_HAS_BALANCE: u64 = 2;

    /// The holder of an account stores the balance of each coin type they own.
    struct CoinStore<phantom CoinType> has key {
        coin: coin::Coin<CoinType>,
        frozen: bool,
        deposit_events: coin::DepositEvents,
        withdraw_events: coin::WithdrawEvents,
    }

    /// Capability resource that allows the holder to burn coins
    struct BurnCapability<phantom CoinType> has key, store {
        burn_cap: coin::BurnCapability<CoinType>,
    }

    /// Capability resource that allows the holder to freeze coins
    struct FreezeCapability<phantom CoinType> has key, store {
        freeze_cap: coin::FreezeCapability<CoinType>,
    }

    /// Capability resource that allows the holder to mint coins
    struct MintCapability<phantom CoinType> has key, store {
        mint_cap: coin::MintCapability<CoinType>,
    }

    /// Initialize a new coin with the given name, symbol, decimals, and monitor.
    /// The caller will become the treasury compliance account and can perform
    /// mint, burn, and freeze operations on the coin.
    fun init_module(
        account: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
        monitor_supply: bool,
    ) {
        let account_addr = signer::address_of(account);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<BasicCoin>(
            account,
            name,
            symbol,
            decimals,
            monitor_supply,
        );

        // Give the account the capabilities
        move_to(account, BurnCapability { burn_cap });
        move_to(account, FreezeCapability { freeze_cap });
        move_to(account, MintCapability { mint_cap });
    }

    /// Register the `CoinType` as a coin in the system.
    /// The caller must have a `CoinStore<CoinType>` resource published under their account.
    public entry fun register<CoinType>(account: &signer) {
        let coin_store = coin::register<CoinType>(account);
        move_to(account, coin_store);
    }

    /// Mint `amount` tokens to `mint_addr`.
    /// The caller must have a `MintCapability<CoinType>` resource published under their account.
    public entry fun mint<CoinType>(
        account: &signer,
        mint_addr: address,
        amount: u64,
    ) acquires MintCapability {
        let mint_cap = &borrow_global<MintCapability<CoinType>>(signer::address_of(account)).mint_cap;
        let coins = coin::mint<CoinType>(amount, mint_cap);
        coin::deposit(mint_addr, coins);
    }

    /// Burn `amount` tokens from `burn_addr`.
    /// The caller must have a `BurnCapability<CoinType>` resource published under their account.
    public entry fun burn<CoinType>(
        account: &signer,
        burn_addr: address,
        amount: u64,
    ) acquires BurnCapability {
        let burn_cap = &borrow_global<BurnCapability<CoinType>>(signer::address_of(account)).burn_cap;
        let coins = coin::withdraw<CoinType>(burn_addr, amount);
        coin::burn(coins, burn_cap);
    }

    /// Freeze the coins in `freeze_addr`.
    /// The caller must have a `FreezeCapability<CoinType>` resource published under their account.
    public entry fun freeze_coin_store<CoinType>(
        account: &signer,
        freeze_addr: address,
    ) acquires FreezeCapability {
        let freeze_cap = &borrow_global<FreezeCapability<CoinType>>(signer::address_of(account)).freeze_cap;
        coin::freeze_coin_store<CoinType>(freeze_addr, freeze_cap);
    }

    /// Unfreeze the coins in `freeze_addr`.
    /// The caller must have a `FreezeCapability<CoinType>` resource published under their account.
    public entry fun unfreeze_coin_store<CoinType>(
        account: &signer,
        freeze_addr: address,
    ) acquires FreezeCapability {
        let freeze_cap = &borrow_global<FreezeCapability<CoinType>>(signer::address_of(account)).freeze_cap;
        coin::unfreeze_coin_store<CoinType>(freeze_addr, freeze_cap);
    }

    /// Transfer `amount` tokens from `from` to `to`.
    public entry fun transfer<CoinType>(
        from: &signer,
        to: address,
        amount: u64,
    ) acquires CoinStore {
        let coins = coin::withdraw<CoinType>(signer::address_of(from), amount);
        coin::deposit(to, coins);
    }

    /// Get the balance of `owner`.
    public fun balance_of<CoinType>(owner: address): u64 acquires CoinStore {
        coin::value<CoinType>(owner)
    }

    /// Get the total supply of the coin.
    public fun total_supply<CoinType>(): u64 {
        coin::supply<CoinType>()
    }

    /// Get the name of the coin.
    public fun name<CoinType>(): vector<u8> {
        coin::name<CoinType>()
    }

    /// Get the symbol of the coin.
    public fun symbol<CoinType>(): vector<u8> {
        coin::symbol<CoinType>()
    }

    /// Get the decimals of the coin.
    public fun decimals<CoinType>(): u8 {
        coin::decimals<CoinType>()
    }

    /// Check if the coin is frozen for `owner`.
    public fun is_frozen<CoinType>(owner: address): bool acquires CoinStore {
        coin::is_account_frozen<CoinType>(owner)
    }

    /// Check if the coin store exists for `owner`.
    public fun coin_store_exists<CoinType>(owner: address): bool {
        exists<CoinStore<CoinType>>(owner)
    }

    #[test_only]
    struct BasicCoin has key {}

    #[test(account = @0x1)]
    public entry fun test_basic_coin_flow(account: &signer) {
        // Initialize the coin
        init_module(account, b"BasicCoin", b"BC", 8, true);
        
        // Register the coin for the account
        register<BasicCoin>(account);
        
        // Mint some coins
        mint<BasicCoin>(account, @0x1, 1000);
        
        // Check the balance
        assert!(balance_of<BasicCoin>(@0x1) == 1000, EINSUFFICIENT_BALANCE);
        
        // Transfer some coins
        transfer<BasicCoin>(account, @0x2, 500);
        
        // Check the new balance
        assert!(balance_of<BasicCoin>(@0x1) == 500, EINSUFFICIENT_BALANCE);
        assert!(balance_of<BasicCoin>(@0x2) == 500, EINSUFFICIENT_BALANCE);
    }
} 