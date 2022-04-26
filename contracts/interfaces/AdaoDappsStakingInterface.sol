//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface AdaoDappsStakingInterface {
    function depositFor(address payable account) external payable;
    function withdraw(uint ibASTRAmount) external;
    function withdrawTo(address payable account, uint ibASTRAmount) external;
}