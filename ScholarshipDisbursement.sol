// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScholarshipDisbursement {
    // --- State Variables ---
    address public admin;       // OAA 
    address public treasury;    
    address public registrar;   
    bool public isPaused;       

    struct Scholar {
        uint256 totalAllocation; // Total semester stipend (in wei)
        uint256 monthlyTranche;  // Monthly release amount (in wei)
        uint256 requiredQPI;     // Minimum grade (scaled by 100, e.g., 250 = 2.50)
        uint256 currentQPI;      // Latest submitted QPI (scaled by 100)
        bool isEnrolled;         // Enrollment status
        uint8 monthsDisbursed;   // Tranche counter (max 5)
        bool isActive;           // Eligibility flag
    }

    // each address => each scholar
    mapping(address => Scholar) public scholars;

    
    // - Modifiers - 
    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the Admin");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasury, "Caller is not the Treasury");
        _;
    }

    modifier onlyRegistrar() {
        require(msg.sender == registrar, "Caller is not the Registrar");
        _;
    }

    modifier onlyScholar() {
        require(scholars[msg.sender].isActive == true, "Caller is not an active Scholar");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is currently paused");
        _;
    }

    // - Constructor -
    // Sets up the key roles upon deployment
    constructor(address _treasury, address _registrar) {
        admin = msg.sender; 
        treasury = _treasury;
        registrar = _registrar;
        isPaused = false;
    }


    // - Functions -



    // --- Administrative & Failsafe Functions ---
    function togglePause() external onlyAdmin {
        isPaused = !isPaused;
    }




    // - Events - 
    event FundsDeposited(address indexed sender, uint256 amount);
    event ScholarAdded(address indexed scholar, uint256 totalAllocation);
    event StatusVerified(address indexed scholar, bool isEnrolled, uint256 currentQPI);
    event StipendDisbursed(address indexed scholar, uint256 amount, uint8 trancheNumber);
    event EmergencyWithdrawal(address indexed treasury, uint256 amount);



    // Read-only function to check contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
