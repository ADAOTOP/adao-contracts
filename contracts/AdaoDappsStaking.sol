//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/DappsStaking.sol";
import "./interfaces/AdaoDappsStakingInterface.sol";

//ibASTR
contract AdaoDappsStaking is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, AdaoDappsStakingInterface {
    struct WithdrawRecord{
        uint era;   //the era started unbonding.
        address payable account;
        uint amount;
        uint index;
    }

    DappsStaking public constant DAPPS_STAKING = DappsStaking(0x0000000000000000000000000000000000005001);
    uint public constant RATIO_PRECISION = 100000000; //precision: 0.00000001
    uint public constant MAX_TRANSFERS = 50;
    uint public constant MINIMUM_WITHDRAW = 1000000000000000000;
    uint public constant MINIMUM_REMAINING = 1000000000000000000;

    address public contractAddress;
    uint public unbondingPeriod;
    uint public lastClaimedEra;
    uint public ratio;

    WithdrawRecord[] public records;
    uint public recordsIndex;
    uint public toWithdrawed;
    mapping(address => uint[]) public userRecordsIndexes;

    bool public isWithdrawDone;

    mapping(address => bool) public whiteList; //allow whiteListed contracts to withdraw to.

    event PoolUpdate(uint _recordsIndex, uint _ibASTR, uint _ratio);
    event ClaimFailed(uint era);

    uint public queuedAmount;


    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC20_init_unchained(name, symbol);
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        lastClaimedEra = DAPPS_STAKING.read_current_era() - 1;
        unbondingPeriod = DAPPS_STAKING.read_unbonding_period();
        ratio = RATIO_PRECISION;
        isWithdrawDone = true;
    }

     /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    function getWithdrawRecords(uint _startIndex, uint _capacity) external view returns(WithdrawRecord[] memory){
        uint _recordsLength = records.length;
        uint _endIndex;
        if(_startIndex + _capacity > _recordsLength){
            _endIndex = _recordsLength;
        }else{
            _endIndex = _startIndex + _capacity;
        }

        WithdrawRecord[] memory result = new WithdrawRecord[](_endIndex - _startIndex);
        uint j;
        for(uint i = _startIndex; i < _endIndex; i++){
            result[j] = records[i];
            j++;
        }
        return result;
    }

    function getUserWithdrawRecords(address account, uint _startIndex, uint _capacity) external view returns(WithdrawRecord[] memory){
        uint[] storage _recordsIndexes = userRecordsIndexes[account];
        uint _recordsLength = _recordsIndexes.length;
        uint _endIndex;
        if(_startIndex + _capacity > _recordsLength){
            _endIndex = _recordsLength;
        }else{
            _endIndex = _startIndex + _capacity;
        }

        WithdrawRecord[] memory result = new WithdrawRecord[](_endIndex - _startIndex);
        uint j;
        for(uint i = _startIndex; i < _endIndex; i++){
            result[j] = records[_recordsIndexes[i]];
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

    function claimAndTransfer(uint _deposited) internal nonReentrant returns (uint){
        //claim and update lastClaimedEra
        uint[] memory gapEras = erasToClaim();
        uint currentEra = gapEras[gapEras.length - 1];
        if(gapEras.length > 1){
            for(uint j = 0; j < gapEras.length - 1; j++){
                uint128 toClaimEra = uint128(gapEras[j]);
                //todo verify if try/catch work.
                //in case rewards has claimed by others.
                try DAPPS_STAKING.claim_staker(contractAddress){}
                catch {
                    emit ClaimFailed(toClaimEra);
                }
            }

            //in case no unbonded tokens.
            try DAPPS_STAKING.withdraw_unbonded(){}
            catch {}

            lastClaimedEra = currentEra - 1;
        }

        //calc ratio
        uint _totalSupply = totalSupply();
        if(_totalSupply > 0){
            uint _balance = address(this).balance - _deposited;
            uint _NStakedAmount = DAPPS_STAKING.read_staked_amount(abi.encodePacked(address(this)));
            ratio = (_balance + _NStakedAmount - toWithdrawed) * RATIO_PRECISION / _totalSupply;
        }


        //proceeding maturing records
        uint _recordsLength = records.length;
        uint _recordsIndex = recordsIndex;
        uint i = _recordsIndex;
        uint withdrawedAmount;
        uint maxTransferIndex = _recordsIndex + MAX_TRANSFERS;
        for(; i < _recordsLength && i < maxTransferIndex; i++){
            WithdrawRecord storage _record = records[i];
            if(currentEra - _record.era >= unbondingPeriod){
                //transfer
                _record.account.call{value: _record.amount}("");
                withdrawedAmount += _record.amount;
            }else{
                break;
            }
        }
        if(i > _recordsIndex){
            toWithdrawed -= withdrawedAmount;
            recordsIndex =  i;
            if(i >= maxTransferIndex && i < _recordsLength){
                isWithdrawDone = false;
            }else{
                isWithdrawDone = true;
            }
        }

        return currentEra;
    }

    function stakeRemaining() internal{
        uint128 _balance = uint128(address(this).balance);
        if(_balance > MINIMUM_REMAINING && isWithdrawDone){
            DAPPS_STAKING.bond_and_stake(contractAddress, _balance);
        }

        emit PoolUpdate(recordsIndex, totalSupply(), ratio);
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address payable account)
        external
        payable
        override
    {
        claimAndTransfer(msg.value);
        if(msg.value > 0){
            _mint(account, msg.value * RATIO_PRECISION / ratio);
        }
        unbondAndUnstake(DAPPS_STAKING.read_current_era(), 0);
        stakeRemaining();
    }

    function _withdraw(address payable account, uint ibASTRAmount) internal{
        uint currentEra = claimAndTransfer(0);
        _burn(_msgSender(), ibASTRAmount);
        uint astrAmount = ibASTRAmount * ratio  / RATIO_PRECISION;
        require(astrAmount <= type(uint128).max, "too large amount");
        require(astrAmount >= MINIMUM_WITHDRAW, "< MINIMUM_WITHDRAW");

        //save new record
        uint index = records.length;
        records.push(WithdrawRecord(formatEra(currentEra), account, astrAmount, index));
        userRecordsIndexes[account].push(index);
        toWithdrawed += astrAmount;
        
        unbondAndUnstake(currentEra, astrAmount);

        stakeRemaining();
    }

    function withdraw(uint ibASTRAmount)
        external
        override
    {
        require(msg.sender == tx.origin, "only EOA");
        _withdraw(payable(msg.sender), ibASTRAmount);
    }

    /**
     * @dev Allow a contract to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address payable account, uint ibASTRAmount)
        external
        override
    {
        require(whiteList[account], "not in white list");
        _withdraw(account, ibASTRAmount);
    }


    function updateUnbondingPeriod() external{
        unbondingPeriod = DAPPS_STAKING.read_unbonding_period();
    }

    function setWhiteList(address payable _contract, bool isTrue) external onlyOwner{
        whiteList[_contract] = isTrue;
    }

    function setContractAddress(address _contract) external onlyOwner{
        contractAddress = _contract;
    }


    function calcDailyApr() external view returns(uint){
        uint32 era = uint32(DAPPS_STAKING.read_current_era() - 1);
        return DAPPS_STAKING.read_era_reward(era) * RATIO_PRECISION / DAPPS_STAKING.read_era_staked(era);
    }

    function getBalance() external view returns(uint128 _balance){
        _balance = uint128(address(this).balance);
    }

    function getStaked() external view returns(uint _NStakedAmount){
        _NStakedAmount = DAPPS_STAKING.read_staked_amount(abi.encodePacked(address(this)));
    }

    function getRecordsLength() external view returns(uint _length){
        return records.length;
    }

    function getUserRecordsLength(address account) external view returns(uint _length){
        return userRecordsIndexes[account].length;
    }

    function unbondAndUnstake(uint _currentEra, uint _astrAmount) private {
        uint _eraMod = _currentEra % 10;
        if(_eraMod == 2 || _eraMod == 4 || _eraMod == 7 || _eraMod == 9){
            uint _unbindAmount = queuedAmount + _astrAmount;
            if(_unbindAmount > 0){
                DAPPS_STAKING.unbond_and_unstake(contractAddress, uint128(_unbindAmount));
                queuedAmount = 0;
            }
        }else if(_astrAmount > 0){
            queuedAmount += _astrAmount;
        }
    }

    function formatEra(uint _era) public pure returns (uint _formatedEra){
        uint _eraMod;
        for(uint i = 0; i < 3; i++){
            _eraMod = (_era + i) % 10;
            if(_eraMod == 2 || _eraMod == 4 || _eraMod == 7 || _eraMod == 9){
                return _era + i;
            }
        }
        require(false, "formatEra error");
    }

    //only used for bugfixing
    function resetEra(uint _index, uint _era) external onlyOwner {
        records[_index].era = _era;
    }
}
