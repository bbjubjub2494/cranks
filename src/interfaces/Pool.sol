pragma solidity ^0.8.10;

interface Pool {
    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint8 interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        uint8 interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );
    event MintUnbacked(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);
    event Repay(
        address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useATokens
    );
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );
    event SwapBorrowRateMode(address indexed reserve, address indexed user, uint8 interestRateMode);
    event UserEModeSet(address indexed user, uint8 categoryId);
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    struct EModeCategory {
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        address priceSource;
        string label;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        uint16 id;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    function ADDRESSES_PROVIDER() external view returns (address);
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);
    function MAX_NUMBER_RESERVES() external view returns (uint16);
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);
    function POOL_REVISION() external view returns (uint256);
    function backUnbacked(address asset, uint256 amount, uint256 fee) external returns (uint256);
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;
    function borrow(bytes32 args) external;
    function configureEModeCategory(uint8 id, EModeCategory memory category) external;
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function dropReserve(address asset) external;
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;
    function flashLoan(
        address receiverAddress,
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory interestRateModes,
        address onBehalfOf,
        bytes memory params,
        uint16 referralCode
    ) external;
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes memory params,
        uint16 referralCode
    ) external;
    function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);
    function getEModeCategoryData(uint8 id) external view returns (EModeCategory memory);
    function getReserveAddressById(uint16 id) external view returns (address);
    function getReserveData(address asset) external view returns (ReserveData memory);
    function getReserveNormalizedIncome(address asset) external view returns (uint256);
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);
    function getReservesList() external view returns (address[] memory);
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
    function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);
    function getUserEMode(address user) external view returns (uint256);
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;
    function initialize(address provider) external;
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;
    function liquidationCall(bytes32 args1, bytes32 args2) external;
    function mintToTreasury(address[] memory assets) external;
    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function rebalanceStableBorrowRate(bytes32 args) external;
    function rebalanceStableBorrowRate(address asset, address user) external;
    function repay(bytes32 args) external returns (uint256);
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256);
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);
    function repayWithATokens(bytes32 args) external returns (uint256);
    function repayWithPermit(bytes32 args, bytes32 r, bytes32 s) external returns (uint256);
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);
    function rescueTokens(address token, address to, uint256 amount) external;
    function resetIsolationModeTotalDebt(address asset) external;
    function setConfiguration(address asset, ReserveConfigurationMap memory configuration) external;
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;
    function setUserEMode(uint8 categoryId) external;
    function setUserUseReserveAsCollateral(bytes32 args) external;
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function supply(bytes32 args) external;
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;
    function supplyWithPermit(bytes32 args, bytes32 r, bytes32 s) external;
    function swapBorrowRateMode(bytes32 args) external;
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;
    function updateBridgeProtocolFee(uint256 protocolFee) external;
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function withdraw(bytes32 args) external returns (uint256);
}

library ReserveConfiguration {
    uint256 internal constant LTV_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant STABLE_BORROWING_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SILOED_BORROWING_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FLASHLOAN_ENABLED_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROW_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant EMODE_CATEGORY_MASK = 0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant UNBACKED_MINT_CAP_MASK =
        0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant DEBT_CEILING_MASK = 0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
    uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
    uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
    uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
    uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
    uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
    uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
    uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
    uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
    uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCap The supply cap
     */
    function setSupplyCap(Pool.ReserveConfigurationMap memory self, uint256 supplyCap) internal pure {
        self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     */
    function getSupplyCap(Pool.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }
}
