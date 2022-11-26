// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error Main__NotOwner();
error Main__owner();
error Main__verficationPending();
error Main__NoPendingVerification();
error Main__UnauthorisedNode();

contract Advanced {
    enum statusOfNode {
        AUTH_RSGIVEN, // authorised node and result given
        AUTH_RSNOTGIVEN, // authorised node and result not given
        UNAUTH // unauthorised node
    }

    enum deviceID {
        DOORBELL_CAM,
        SMART_LOCK,
        AIR_QUALITY_CONTROLLER
    }

    // file info
    struct deviceFirmwareFile {
        string version;
        string t_version;
        string metadata;
        string t_metadata;
        string dphash; // download point hash
        string t_dphash;
        string fileAddress;
        string downloadPoint;
        uint256 pass;
        uint256 reject;
        bool pendingVerification;
    }

    mapping(uint256 => deviceFirmwareFile) private deviceIdToFirmwareFile;

    function getFirmwareFile(
        deviceID _id
    ) public view noOwner returns (deviceFirmwareFile memory) {
        return deviceIdToFirmwareFile[uint256(_id)];
    }

    address[] private verficationNodes;
    mapping(address => uint) private nodeToresult;

    // owner can't be changed
    address public immutable i_owner;
    uint256 public immutable peercount;
    uint256 private numberOfDevices;

    constructor(address[] memory _verficationNodes, deviceID[] memory _ids) {
        i_owner = msg.sender;
        peercount = _verficationNodes.length;
        numberOfDevices = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            deviceIdToFirmwareFile[uint256(_ids[i])] = deviceFirmwareFile({
                version: "0",
                t_version: "0",
                metadata: "",
                t_metadata: "",
                dphash: "",
                t_dphash: "",
                fileAddress: "",
                downloadPoint: "",
                pass: 0,
                reject: 0,
                pendingVerification: false
            });
        }
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
        deviceID _id,
        string memory _version,
        string memory _metadata,
        string memory fileAdd,
        string memory _dphash
    ) public onlyOwner {
        // can do swarm upload here
        if (deviceIdToFirmwareFile[uint256(_id)].pendingVerification)
            revert Main__verficationPending();
        deviceIdToFirmwareFile[uint256(_id)].t_version = _version;
        deviceIdToFirmwareFile[uint256(_id)].t_metadata = _metadata;
        deviceIdToFirmwareFile[uint256(_id)].fileAddress = fileAdd;
        deviceIdToFirmwareFile[uint256(_id)].t_dphash = _dphash;
        deviceIdToFirmwareFile[uint256(_id)].pendingVerification = true;
        deviceIdToFirmwareFile[uint256(_id)].pass = deviceIdToFirmwareFile[
            uint256(_id)
        ].reject = 0;
    }

    function checkVersion() public view noOwner returns (string[] memory) {
        string[] memory ret = new string[](numberOfDevices);
        for (uint256 _id = 0; _id < numberOfDevices; _id++) {
            ret[_id] = deviceIdToFirmwareFile[_id].t_version;
        }
        return ret;
    }

    function verify(bool passed, address peerNode, uint256 _id) public noOwner {
        if (!deviceIdToFirmwareFile[_id].pendingVerification)
            revert Main__NoPendingVerification();

        // check in the mapping if the result form this node has already been stored
        require(
            nodeToresult[peerNode] != uint256(statusOfNode.AUTH_RSGIVEN),
            "You can verfify only once"
        );
        require(
            nodeToresult[peerNode] != uint256(statusOfNode.UNAUTH),
            "You are not authorized to verify"
        );

        if (passed) deviceIdToFirmwareFile[uint256(_id)].pass++;
        else deviceIdToFirmwareFile[uint256(_id)].reject++;

        // result for this node is recorded
        // change mapping of peernode address to result given
        nodeToresult[peerNode] = uint256(statusOfNode.AUTH_RSGIVEN);

        // create a event(checkVerifed) : when we get 90% of responses of the all pears
        // if event triggers: call checkverified
        uint256 resultsArrived = deviceIdToFirmwareFile[uint256(_id)].pass +
            deviceIdToFirmwareFile[uint256(_id)].reject;
        uint256 threshold = (peercount * 90) / 100;
        if (resultsArrived > threshold) {
            checkVerifed(
                deviceIdToFirmwareFile[uint256(_id)].pass,
                resultsArrived,
                _id
            );
        }
    }

    function checkVerifed(
        uint256 passed,
        uint256 responses,
        uint256 _id
    ) private {
        uint256 threshold1 = (responses * 50) / 100;
        if ((passed) / (responses) > threshold1) {
            deviceIdToFirmwareFile[uint256(_id)]
                .downloadPoint = deviceIdToFirmwareFile[uint256(_id)]
                .fileAddress;
            deviceIdToFirmwareFile[uint256(_id)]
                .version = deviceIdToFirmwareFile[uint256(_id)].t_version;
            deviceIdToFirmwareFile[uint256(_id)]
                .metadata = deviceIdToFirmwareFile[uint256(_id)].t_metadata;
            deviceIdToFirmwareFile[uint256(_id)]
                .dphash = deviceIdToFirmwareFile[uint256(_id)].t_dphash;
        }
        deviceIdToFirmwareFile[uint256(_id)].pendingVerification = false;
        deviceIdToFirmwareFile[uint256(_id)].pass = deviceIdToFirmwareFile[
            uint256(_id)
        ].reject = 0;

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
