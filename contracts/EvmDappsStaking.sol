//SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/DappsStaking.sol";

//idSDN
contract EvmDappsStaking is ERC20, Ownable, ReentrancyGuard {
    struct WithdrawRecord{
        uint era;   //the era started unbonding.
        address account;
        uint amount;
    }

    DappsStaking public constant DAPPS_STAKING = DappsStaking(0x0000000000000000000000000000000000005001);
    address public constant CONTRACT_ADDRESS = 0x1CeE94a11eAf390B67Aa346E9Dda3019DfaD4f6A;
    uint public constant RATIO_PRECISION = 100000000; //precision: 0.00000001
    uint public constant FEE_PRECISION = 10000;

    uint public fee; //unit: 0.0001
    address public feeTo;
    uint public unbondingPeriod;

    uint public lastClaimedEra;
    uint public prevUnstakeSDN;
    uint public ratio = RATIO_PRECISION;

    WithdrawRecord[] public records;
    uint public recordsIndex;
    uint public toWithdrawSDN;

    event PoolUpdate(uint _recordsIndex, uint _ksdn, uint _ratio);


    constructor(
        string memory name,
        string memory symbol,
        uint _fee,
        address _feeTo,
        uint _lastClaimedEra,
        uint _unbondingPeriod
    ) ERC20(name, symbol) {
        fee = _fee;
        feeTo = _feeTo;
        lastClaimedEra = _lastClaimedEra;
        unbondingPeriod = _unbondingPeriod;
    }

    function getWithdrawRecords(uint _startIndex, uint _capacity) external view returns(WithdrawRecord[] memory){
        uint _recordsLength = records.length;
        uint _endIndex;
        if(_startIndex + _capacity - 1 > _recordsLength){
            _endIndex = _recordsLength;
        }else{
            _endIndex = _startIndex + _capacity - 1;
        }

        WithdrawRecord[] memory result = new WithdrawRecord[](_endIndex - _startIndex);
        uint j;
        for(uint i = _startIndex; i < _endIndex; i++){
            result[j] = records[i];
            j++;
        }
        return result;
    }

    //return: the last is current era;
    function erasToClaim() public view returns (uint[] memory){
        uint currentEra = DAPPS_STAKING.read_current_era();
        uint toClaimEra = lastClaimedEra + 1;
        uint gap = currentEra - toClaimEra + 1;
        uint[] memory gapEras = new uint[](gap);
        for(uint i = 0; i < gap; i++){
            gapEras[i] = toClaimEra;
            toClaimEra++;
        }
        return gapEras;
    }

    function claimAndTransfer(uint depositSDN) internal nonReentrant returns (uint){
        //claim and update lastClaimedEra
        uint[] memory gapEras = erasToClaim();
        uint currentEra = gapEras[gapEras.length - 1];
        if(gapEras.length > 1){
            for(uint j = 0; j < gapEras.length - 1; j++){
                uint128 toClaimEra = uint128(gapEras[j]);
                //todo verify if try/catch work.
                try DAPPS_STAKING.claim(CONTRACT_ADDRESS, toClaimEra){}
                catch {}
            }
            lastClaimedEra = currentEra - 1;
        }

        //calc unstakeAmount
        DAPPS_STAKING.withdraw_unbonded();
        uint _balance = address(this).balance;
        uint _unbondingAmount = DAPPS_STAKING.read_unbonding_period();
        uint _nowUnstakeSDN = _balance + _unbondingAmount - depositSDN;

        //calc dAppsStaking reward
        uint rewardAmount = (_nowUnstakeSDN - prevUnstakeSDN);

        if(rewardAmount > 0){
            //update ratio
            //todo veirfy param and return of read_staked_amount
            uint _stakedAmount = DAPPS_STAKING.read_staked_amount(address(this));
            ratio = (_stakedAmount + _nowUnstakeSDN - toWithdrawSDN) * RATIO_PRECISION / totalSupply();

            //mint fee
            _mint(feeTo, (rewardAmount * fee / FEE_PRECISION ) * RATIO_PRECISION / ratio);
        }

        //proceeding maturing records
        uint _recordsLength = records.length;
        uint _recordsIndex = recordsIndex;
        uint i = _recordsIndex;
        uint withdrawedAmount;
        for(; i < _recordsLength; i++){
            WithdrawRecord storage _record = records[i];
            if(currentEra - _record.era >= unbondingPeriod){
                //transfer
                (bool success,) = _record.account.call{value: _record.amount}("");
                require(success, "trans fail");
                withdrawedAmount += _record.amount;
            }else{
                break;
            }
        }
        if(i > _recordsIndex){
            toWithdrawSDN -= withdrawedAmount;
            recordsIndex =  i;
        }

        return currentEra;
    }

    function stakeRemaining() internal{
        uint128 _balance = uint128(address(this).balance);
        if(_balance > 0){
            DAPPS_STAKING.bond_and_stake(CONTRACT_ADDRESS, _balance);
        }
        prevUnstakeSDN = DAPPS_STAKING.read_unbonding_period();

        emit PoolUpdate(recordsIndex, totalSupply(), ratio);
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account)
        external
        payable
    {
        claimAndTransfer(msg.value);
        if(msg.value > 0){
            _mint(account, msg.value * RATIO_PRECISION / ratio);
        }
        stakeRemaining();
    }

    /**
     * @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address payable account, uint ksdnAmount)
        external
    {
        require(ksdnAmount > 0, "ksdnAmount 0");
        uint currentEra = claimAndTransfer(0);
        _burn(_msgSender(), ksdnAmount);
        uint sdnAmount = ksdnAmount * ratio  / RATIO_PRECISION;
        require(sdnAmount <= type(uint128).max, "too large amount");

        //save new record
        WithdrawRecord storage _newRecord = records.push();
        _newRecord.account = account;
        _newRecord.amount = sdnAmount;
        _newRecord.era = currentEra;
        toWithdrawSDN += sdnAmount;
        
        DAPPS_STAKING.unbond_and_unstake(CONTRACT_ADDRESS, uint128(sdnAmount));

        stakeRemaining();
    }

    function setFee(uint _fee, address _feeTo) external onlyOwner{
        fee = _fee;
        feeTo = _feeTo;
    }

    function updateUnbondingPeriod(uint _unbondingPeriod) external onlyOwner{
        unbondingPeriod = _unbondingPeriod;
    }

    function calcDailyApr() external view returns(uint){
        uint32 era = uint32(DAPPS_STAKING.read_current_era() - 1);
        return DAPPS_STAKING.read_era_reward(era) * RATIO_PRECISION / DAPPS_STAKING.read_era_staked(era);
    }
}
