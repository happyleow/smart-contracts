//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ChainportMiddleware.sol";

/**
 * ChainportFundManager contract.
 * @author Marko Lazic
 * Date created: 17.8.21.
 * Github: markolazic01
 */

contract ChainportFundManager is ChainportMiddleware {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Global state variables
    bool isContractFrozen;
    address public rebalancer;
    address public chainportBridge;
    address _safeAddress;
    mapping(address => uint256) tokenAddressToThreshold;

    // Events
    event RebalancerChanged(address newRebalancer);
    event SafeAddressChanged(address newSafeAddress);
    event ChainportBridgeChanged(address newChainportBridge);
    event FundsRebalancedToHotBridge(address token, uint256 amount);
    event FundsRebalancedToSafeAddress(address token, uint256 amount);
    event TokenThresholdSet(address token, uint256 threshold);

    // Modifiers
    modifier onlyRebalancer {
        require(
            msg.sender == rebalancer,
            "Error: Function restricted only to rebalancer."
        );
        _;
    }

    constructor(
        address _chainportCongress,
        address _maintainersRegistry,
        address _rebalancer,
        address _chainportBridge,
        address safeAddress_
    )
    public{
        setCongressAndMaintainers(_chainportCongress, _maintainersRegistry);
        rebalancer = _rebalancer;
        chainportBridge = _chainportBridge;
        _safeAddress = safeAddress_;
    }

    // Functions
    // Function to get safeAddress by rebalancer
    function getSafeAddress() external onlyRebalancer view returns (address) {
        return _safeAddress;
    }

    // Function to set rebalancer by congress
    function setRebalancer(
        address _rebalancer
    )
    external
    onlyChainportCongress
    {
        // Require that address is not malformed
        require(
            _rebalancer != address(0),
            "Error: Cannot set zero address as rebalancer."
        );

        // Set new rebalancer address
        rebalancer = _rebalancer;
        emit RebalancerChanged(_rebalancer);
    }

    // Function to set chainportBridge address by congress
    function setChainportBridge(
        address _chainportBridge
    )
    external
    onlyChainportCongress
    {
        // Require that address is not malformed
        require(
            _chainportBridge != address(0),
            "Error: Cannot set zero address as bridge contract."
        );

        // Set new rebalancer address
        chainportBridge = _chainportBridge;
        emit ChainportBridgeChanged(_chainportBridge);
    }

    // Function to set safe address by congress
    function setSafeAddress(
        address safeAddress_
    )
    external
    onlyChainportCongress
    {
        // Require that address is not malformed
        require(
            safeAddress_ != address(0),
            "Error: Cannot set zero address as safe address."
        );

        // Set new safe address
        _safeAddress = safeAddress_;
        emit SafeAddressChanged(safeAddress_);
    }

    // Function to set token threshold by rebalancer
    function setTokenThresholdByRebalancer(
        address token,
        uint256 threshold
    )
    external
    onlyRebalancer
    {
        // Require that threshold has not been set
        require(tokenAddressToThreshold[token] == 0, "Error: Token threshold already set.");
        require(threshold > 0, "Error: Threshold cannot be set as zero value.");
        // Set threshold for token
        tokenAddressToThreshold[token] = threshold;
        // Emit an event
        emit TokenThresholdSet(token, threshold);
    }

    // Function to set thresholds for tokens
    function setTokenThresholdsByCongress(
        address [] calldata tokens,
        uint256 [] calldata thresholds
    )
    external
    onlyChainportCongress
    {
        for(uint8 i; i < tokens.length; i++) {
            // Require that array arguments are valid
            require(tokens[i] != address(0), "Error: Token address is malformed.");
            require(thresholds[i] != 0, "Error: Zero value cannot be set as threshold.");
            // Set threshold for token
            tokenAddressToThreshold[tokens[i]] = thresholds[i];
            // Emit an event
            emit TokenThresholdSet(tokens[i], thresholds[i]);
        }
    }

    // Function to transfer funds to bridge contract
    function fundBridgeByRebalancer(
        address [] calldata tokens,
        uint256 [] calldata amounts
    )
    external
    onlyRebalancer
    {
        for(uint8 i; i < tokens.length; i++) {
            // Require that valid amount is given
            require(
                amounts[i] > 0 && amounts[i] <= tokenAddressToThreshold[tokens[i]],
                "Error: Amount is not valid."
            );
            // Perform safe transfer
            IERC20(tokens[i]).safeTransfer(chainportBridge, amounts[i]);
            emit FundsRebalancedToHotBridge(tokens[i], amounts[i]);
        }
    }

    // Function to transfer funds to the safe address
    function fundSafeByRebalancer(
        address [] calldata tokens,
        uint256 [] calldata amounts
    )
    external
    onlyRebalancer
    {
        for(uint8 i; i < tokens.length; i++) {
            // Require that valid amount is given
            require(amounts[i] > 0, "Error: Amount is not greater than zero.");
            // Perform safe transfer
            IERC20(tokens[i]).safeTransfer(_safeAddress, amounts[i]);
            emit FundsRebalancedToSafeAddress(tokens[i], amounts[i]);
        }
    }
}