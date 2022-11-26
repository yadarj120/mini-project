// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error Main__NotOwner();
error Main__owner();
error Main__verficationPending();
error Main__NoPendingVerification();
error Main__UnauthorisedNode();

contract Main {
    enum statusOfNode {
        AUTH_RSGIVEN, // authorised node and result given
        AUTH_RSNOTGIVEN, // authorised node and result not given
        UNAUTH // unauthorised node
    }

    // file info
    string private version;
    string private t_version;
    string private metadata;
    string private t_metadata;
    string private dphash; // download point hash
    string private t_dphash;
    string private fileAddress;
    string private downloadPoint;
    uint256 private pass;
    uint256 private reject;
    bool private pendingVerification;

    address[] private verficationNodes;
    mapping(address => uint) private nodeToresult;

    // owner can't be changed
    address public immutable i_owner;
    uint256 public immutable peercount;

    constructor(address[] memory _verficationNodes) {
        i_owner = msg.sender;
        peercount = _verficationNodes.length;
        pendingVerification = false;
        for (uint256 i = 0; i < _verficationNodes.length; i++) {
            verficationNodes.push(_verficationNodes[i]);
        }
        for (uint256 i = 0; i < verficationNodes.length; i++) {
            nodeToresult[verficationNodes[i]] = uint256(
                statusOfNode.AUTH_RSNOTGIVEN
            );
        }
    }

    // phase-2 file uploading
    function fileUploading(
        string memory _version,
        string memory _metadata,
        string memory fileAdd,
        string memory _dphash
    ) public onlyOwner {
        // can do swarm upload here
        if (pendingVerification) revert Main__verficationPending();
        t_version = _version;
        t_metadata = _metadata;
        fileAddress = fileAdd;
        t_dphash = _dphash;
        pendingVerification = true;
        pass = reject = 0;
    }

    function checkVersion() public view noOwner returns (string memory) {
        return t_version;
    }

    function verify(bool passed, address peerNode) public noOwner {
        if (!pendingVerification) revert Main__NoPendingVerification();

        // check in the mapping if the result form this node has already been stored
        require(
            nodeToresult[peerNode] != uint256(statusOfNode.AUTH_RSGIVEN),
            "You can verfify only once"
        );
        require(
            nodeToresult[peerNode] != uint256(statusOfNode.UNAUTH),
            "You are not authorized to verify"
        );

        if (passed) pass++;
        else reject++;

        // result for this node is recorded
        // change mapping of peernode address to result given
        nodeToresult[peerNode] = uint256(statusOfNode.AUTH_RSGIVEN);

        // create a event(checkVerifed) : when we get 90% of responses of the all pears
        // if event triggers: call checkverified
        uint256 resultsArrived = pass + reject;
        uint256 threshold = (peercount * 90) / 100;
        if (resultsArrived > threshold) {
            checkVerifed(pass, resultsArrived);
        }
    }

    function checkVerifed(uint256 passed, uint256 responses) private {
        uint256 threshold1 = (responses * 50) / 100;
        if ((passed) / (responses) > threshold1) {
            downloadPoint = fileAddress;
            version = t_version;
            metadata = t_metadata;
            dphash = t_dphash;
        }
        pendingVerification = false;
        pass = reject = 0;

        for (uint i = 0; i < verficationNodes.length; i++) {
            nodeToresult[verficationNodes[i]] = uint256(
                statusOfNode.AUTH_RSNOTGIVEN
            );
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Main__NotOwner();
        _;
    }

    modifier noOwner() {
        bool isValidNode = false;
        for (uint256 i = 0; i < verficationNodes.length; i++) {
            if (msg.sender == verficationNodes[i]) {
                isValidNode = true;
                break;
            }
        }
        if (!isValidNode) revert Main__UnauthorisedNode();
        _;
    }
}
