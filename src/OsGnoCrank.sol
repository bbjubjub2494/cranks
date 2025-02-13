// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/ERC20.sol";
import "@solady-0.0.228/src/utils/UUPSUpgradeable.sol";

import "stakewise-v3-core-v3.0.0/contracts/interfaces/IOsTokenFlashLoans.sol";
import "stakewise-v3-core-v3.0.0/contracts/interfaces/IOsTokenFlashLoanRecipient.sol";

import "balancer-v2-1.0.0/pkg/interfaces/contracts/vault/IVault.sol";

import "src/ERC20Container.sol";

interface StakewiseVault {
  /**
   * @notice Deposit GNO to the Vault
   * @param assets The amount of GNO to deposit
   * @param receiver The address that will receive Vault's shares
   * @param referrer The address of the referrer. Set to zero address if not used.
   * @return shares The number of shares minted
   */
  function deposit(
    uint256 assets,
    address receiver,
    address referrer
  ) external returns (uint256 shares);

  /**
   * @notice Mints OsToken shares
   * @param receiver The address that will receive the minted OsToken shares
   * @param osTokenShares The number of OsToken shares to mint to the receiver. To mint the maximum amount of shares, use 2^256 - 1.
   * @param referrer The address of the referrer
   * @return assets The number of assets minted to the receiver
   */
  function mintOsToken(
    address receiver,
    uint256 osTokenShares,
    address referrer
  ) external returns (uint256 assets);

  /**
   * @notice Burns osToken shares
   * @param osTokenShares The number of shares to burn
   * @return assets The number of assets burned
   */
  function burnOsToken(uint128 osTokenShares) external returns (uint256 assets);
}

ERC20 constant gno = ERC20(0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb);
ERC20 constant osgno = ERC20(0xF490c80aAE5f2616d3e3BDa2483E30C4CB21d1A0);
IOsTokenFlashLoans constant flashloans = IOsTokenFlashLoans(0xe84183EfFbcc76D022Cccc31b95EAa332bB5Bb11);
IVault constant balancer_vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
// For now this is a random public vault with own mev, https://app.stakewise.io/vault/gnosis/0x0686f6bbb28fd0642aebf5b89654aeba9cc73dea
StakewiseVault constant stakewiseVault = StakewiseVault(0x0686f6BbB28fd0642aeBF5B89654aeBa9cC73Dea);

contract OsGnoCrank is Ownable, ERC20Container, UUPSUpgradeable, IOsTokenFlashLoanRecipient {
    uint private constant MAX_FLASHLOAN = 100_000 ether;

    bytes32 private constant OSGNO_GNO_POOL_ID = 0x3220c83e953186f2b9ddfc0b5dd69483354edca20000000000000000000000b0;

    function initialize(address owner) external {
        // will revert if already initialized
        _initializeOwner(owner);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function wind(uint osGnoAmount) external onlyOwner {
	    flashloans.flashLoan(MAX_FLASHLOAN, msg.data);
    }

    function unwind(uint osGnoAmount) external onlyOwner {
	    flashloans.flashLoan(MAX_FLASHLOAN, msg.data);
    }

    function receiveFlashLoan(uint256 osTokenShares, bytes calldata userData) override external {
	    require(msg.sender == address(flashloans));
	    bytes4 sig = bytes4(userData);
	    if (sig == OsGnoCrank.wind.selector) {
		    _wind(userData[4:]);
	    }else if (sig == OsGnoCrank.unwind.selector){
			    _unwind(userData[4:]);
	    }
    }
    function _wind(bytes calldata data) internal {
	    uint osGnoAmount = abi.decode(data, (uint));
	    IVault.SingleSwap memory swap = IVault.SingleSwap ({
        poolId: OSGNO_GNO_POOL_ID,
        kind: IVault.SwapKind.GIVEN_IN,
        assetIn: IAsset(address(osgno)),
        assetOut: IAsset(address(gno)),
        amount: osGnoAmount,
        userData: ""
    });
    IVault.FundManagement memory fm = IVault.FundManagement({
        sender: address(this),
        fromInternalBalance: false,
        recipient: payable(address(this)),
        toInternalBalance: false
    });
    osgno.approve(address(balancer_vault), osGnoAmount);
    uint gnoAmount = balancer_vault.swap(swap, fm, 0, block.timestamp);

    gno.approve(address(stakewiseVault), gnoAmount);
    stakewiseVault.deposit(gnoAmount, address(this), address(0));
    stakewiseVault.mintOsToken(address(this),osGnoAmount, address(0));
    }
    function _unwind(bytes calldata data) internal {
	    uint osGnoAmount = abi.decode(data, (uint));
    }
}
