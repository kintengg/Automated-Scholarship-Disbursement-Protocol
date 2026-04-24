// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScholarshipDisbursement {
    // --- State Variables ---
    address public admin;       
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


    // --- Functions ---

    // Treasury funds the contract
    function depositFunds() external payable onlyTreasury {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Admin registers a scholar
    // Note: Allocations should be inputted in wei. QPI should be scaled by 100 (e.g., 250 for 2.5).
    function addScholar(address _wallet, uint256 _totalAllocation, uint256 _requiredQPI) external onlyAdmin {
        // TO DO

        require(_totalAllocation > 0, "Total allocation must be greater than 0.");
        require(!scholars[_wallet].isActive, "Scholar is already registered.");

        scholars[_wallet] = Scholar({
            totalAllocation: _totalAllocation,
            monthlyTranche: (_totalAllocation / 5),
            requiredQPI: _requiredQPI,
            currentQPI: 0,
            isEnrolled: false,
            monthsDisbursed: 0,
            isActive: true
        });

        emit ScholarAdded(_wallet, _totalAllocation);
        
    }

    // Registrar verifies the student's status off-chain and updates it on-chain
    function verifyAcademicStatus(address _scholar, bool _isEnrolled, uint256 _currentQPI) external onlyRegistrar {
        // TO DO

    }

    // Scholar claims their monthly tranche
    function claimStipend() external onlyScholar whenNotPaused {
        Scholar storage scholar = scholars[msg.sender];

        require(scholar.isEnrolled, "Scholar is not enrolled");
        require(scholar.currentQPI <= scholar.requiredQPI, "QPI requirement not met");
        require(scholar.monthsDisbursed < 5, "All tranches already claimed");

        uint256 amount = scholar.monthlyTranche;

        require(address(this).balance >= amount, "Insufficient contract balance");

        // Effects
        scholar.monthsDisbursed += 1;

        // Interaction
        payable(msg.sender).transfer(amount);

        emit StipendDisbursed(msg.sender, amount, scholar.monthsDisbursed);
    }

    



    // --- Administrative & Failsafe Functions ---
    function togglePause() external onlyAdmin {
        isPaused = !isPaused;
    }

    function emergencyWithdraw() external onlyTreasury {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(treasury).transfer(balance);
        emit EmergencyWithdrawal(treasury, balance);
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
