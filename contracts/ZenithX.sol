// SPDX-License-Identifier: MIT

pragma  solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol" ;
import "@openzeppelin/contracts/access/Ownable.sol" ;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol" ;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol" ;
interface IFactoryV2  {
    event PairCreated (
        address indexed  token0,
        address indexed  token1,
        address lpPair ,
        uint
    );

    function getPair (
        address tokenA ,
        address tokenB
    )  external view returns (address lpPair);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract ZenithX is ERC20, ERC20Burnable, Ownable, ERC20Permit {

    string private constant _name = "ZenithX";
    string private constant _symbol = "ZNX";
    uint256 public constant _totalSupply = 1_000_000_000 * 10 ** 18;


    bool public burning = false;
    uint256 public burnFee = 10;
    uint256 public constant fee_denominator = 1_000;

    uint256 private constant LOCK_DURATION = 365 days;
    uint256 private lastMintTimestamp;

    IRouter02 public swapRouter;
    address public lpPair;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event ChangePair(address newLpPair);
    event ChangeBurnAmount(uint256 burningPercentage);

    constructor(address initialOwner, address swap_router)
        ERC20(_name, _symbol)
        Ownable(initialOwner)
        ERC20Permit(_name)
    {
        swapRouter = IRouter02(swap_router);

        // Mint 350 million tokens with 18 decimal places
        _mint(msg.sender, 350_000_000 * (10 ** 18));

        lastMintTimestamp = block.timestamp;

        lpPair = IFactoryV2(swapRouter.factory()).createPair(
            swapRouter.WETH(),
            address(this)
        );

        _approve(initialOwner, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= _totalSupply, "Minting exceeds total supply");

        // Check if one year has passed since the last mint
        if (block.timestamp >= lastMintTimestamp + LOCK_DURATION) {
            _mint(to, amount);
            lastMintTimestamp = block.timestamp;
            emit Mint(to, amount);
        } else {
           revert("Minting is locked for one year");
        }
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (!burning) {
            return super.transfer(to, amount);
        }

        uint256 burnAmount = (amount * burnFee) / fee_denominator;
        uint256 transferAmount = amount - burnAmount;

        _burn(msg.sender, burnAmount);
        super.transfer(to, transferAmount);

        emit Burn(msg.sender, burnAmount);
        return true;
    }

    function enableBurning(bool enable) external onlyOwner {
        burning = enable;
    }

    function changeLpPair(address newPair) external onlyOwner {
        require(newPair != address(0), "Zero adress detected");
        require(newPair != address(0xdead), "Dead address detected");
        lpPair = newPair;
        emit ChangePair(newPair);
    }

    function changeBurnPercentage(uint256 burningFee) external onlyOwner {
        require(burningFee <= 50, "you can't burn more than 5% of fees.");
        burnFee = burningFee;

        emit ChangeBurnAmount(burnFee);
    }
}


