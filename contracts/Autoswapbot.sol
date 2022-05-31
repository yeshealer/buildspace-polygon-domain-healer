// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

interface IJavaSwapRoute {
    function sellUSDT(uint256 tokenAmountToSell) external returns (uint256 tokenAmount);
    function getLatestPriceCOPUSD() external returns (int256);
}

contract AutoSwap is Ownable{  

    uint256 public limitSellAmount = 500000;
    event WithdrawEvent(address withdrawToken, uint256 amount);
    IJavaSwapRoute JavaSwapRoute = IJavaSwapRoute(address(0x7e6A8E11866E1a6Dd60d223a4678E5eF6Cb377d9));

    function getUSDTBalance() payable external returns (uint256) {
        address _usdtToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        address _dlyToken = 0x1659fFb2d40DfB1671Ac226A0D9Dcc95A774521A;
        uint256 usdtBlance = IERC20(_usdtToken).balanceOf(address(0x7e6A8E11866E1a6Dd60d223a4678E5eF6Cb377d9));
        if(usdtBlance > 5000000) {
            uint256 dlyPerUsdt = uint256(JavaSwapRoute.getLatestPriceCOPUSD())*10**12;
            uint256 dlyTokenAmountForUsdt = SafeMath.mul(dlyPerUsdt, usdtBlance);
            Account newContract = new Account();            
            require(
                IERC20(_dlyToken).transfer(address(newContract), dlyTokenAmountForUsdt),
                "Failed to transfer DLYCOP to new Account."            
            );
        }
        return usdtBlance;
    }

    function withdraw(uint withdrawAmount, address withdrawToken) onlyOwner external {
        require(withdrawAmount <= IERC20(withdrawToken).balanceOf(address(this)), "WithdrawAmount cann't bigger than balance");                
        IERC20(withdrawToken).transfer(msg.sender, withdrawAmount);
        emit WithdrawEvent(withdrawToken, withdrawAmount);
    }

}

contract Account is Ownable {

    event BuyUSDT(
        address buyer,
        uint256 amountSell
    );

    IJavaSwapRoute JavaSwapRoute = IJavaSwapRoute(address(0x7e6A8E11866E1a6Dd60d223a4678E5eF6Cb377d9));
    function autoDLYUSDTSwap(uint256 dlyAmount) public payable {    
        address _usdtToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;                    
        require(dlyAmount <= 0, "Faild action found");
        uint256 dlyTokenAmountToBuy;                
        if(dlyAmount >= 500000) {
            dlyTokenAmountToBuy = 500000;
        }        
        JavaSwapRoute.sellUSDT(dlyTokenAmountToBuy);   
        uint256 _usdtBlance = IERC20(_usdtToken).balanceOf(address(this));
        require(
            IERC20(_usdtToken).transfer(payable(msg.sender), _usdtBlance),
            "Failed to send usdt token to origin account."
        );        
        emit BuyUSDT(address(this), dlyTokenAmountToBuy);
        selfdestruct(payable(msg.sender));
    }
    
}