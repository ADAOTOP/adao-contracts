// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AdaoDappsStakingInterface.sol";

contract DistributeRewards is Ownable
{
    AdaoDappsStakingInterface constant public adao = AdaoDappsStakingInterface(0x3BFcAE71e7d5ebC1e18313CeCEbCaD8239aA386c);
    uint constant public adaoPercent = 60;
    uint constant public treasuryPercent = 30;

    address payable public treasury;
    address payable public team;

    constructor(address payable _treasury, address payable _team){
        treasury = _treasury;
        team = _team;
    }
    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable {
        distributeRewards();
    }

    function distributeRewards() public payable
    {
        uint _balance = address(this).balance;
        if(_balance > 100){
            uint adaoAmount = _balance * adaoPercent / 100;
            uint treasuryAmount = _balance * treasuryPercent / 100;
            uint teamAmount = _balance - adaoAmount - treasuryAmount;

            (bool success1,) = team.call{value: teamAmount}("");
            require(success1, "failed to team");
            (bool success2,) = treasury.call{value: treasuryAmount}("");
            require(success2, "failed to treasury");
            (bool success3,) = address(adao).call{value: adaoAmount}("");
            require(success3, "failed to adao");

            if(msg.sender != address(adao)){
                adao.depositFor(team);
            }
        }
    }

    function setTreasury(address payable _treasury) external onlyOwner{
        treasury = _treasury;
    }

    function setTeam(address payable _team) external onlyOwner{
        team = _team;
    }
}
