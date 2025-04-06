// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

contract Medileger {
    struct InventoryCommitment {
        bytes32 inventoryHash;
        uint256 timestamp;
        bool exists;
    }
    struct Order {
        bytes32 orderHash;
        address from;
        address to;
        uint256 timestamp;
        string status; // "Pending", "Completed", "Cancelled"
    }

    // map of hospital -> inventory hash
    mapping(address => InventoryCommitment) public inventoryCommitments;
    Order[] public orders;

    // these are notifs for frontend, like printing to console
    // but for blockchain
    // they are not stored on the blockchain, just emitted
    // so they are not part of the state
    event InventoryCommitted(
        address indexed hospital,
        bytes32 inventoryHash,
        uint256 timestamp
    );
    event OrderPlaced(
        bytes32 indexed orderHash,
        address indexed from,
        address indexed to,
        uint256 timestamp
    );
    event OrderStatusUpdated(bytes32 indexed orderHash, string newStatus);

    // hospitals "commit" inventory by storing hash (fingerprint of their stock).
    function commitInventory(bytes32 _inventoryHash) public {
        inventoryCommitments[msg.sender] = InventoryCommitment({
            inventoryHash: _inventoryHash,
            timestamp: block.timestamp,
            exists: true
        });
        emit InventoryCommitted(msg.sender, _inventoryHash, block.timestamp);
    }

    // buyers can only place orders if seller has committed inventory,
    //which is added to our orders arraylist.
    function placeOrder(bytes32 _orderHash, address _from) public {
        require( // verifying
            inventoryCommitments[_from].exists,
            "seller hospital has not committed inventory"
        );

        Order memory newOrder = Order({
            orderHash: _orderHash,
            from: _from,
            to: msg.sender,
            timestamp: block.timestamp,
            status: "Pending"
        });

        orders.push(newOrder);

        emit OrderPlaced(_orderHash, _from, msg.sender, block.timestamp);
    }

    function getOrderByIndex(
        uint256 _index
    )
        public
        view
        returns (
            bytes32 orderHash,
            address from,
            address to,
            uint256 timestamp,
            string memory status
        )
    {
        require(_index < orders.length, "order idx outside bounds");
        Order memory order = orders[_index];
        return (
            order.orderHash,
            order.from,
            order.to,
            order.timestamp,
            order.status
        );
    }

    function updateOrderStatus(
        uint256 _index,
        string memory _newStatus
    ) public {
        require(_index < orders.length, "Order index out of bounds");
        Order storage order = orders[_index];

        // ensure only the involved hospitals can update the status
        require(
            msg.sender == order.from || msg.sender == order.to,
            "only involved hospitals can update order status"
        );

        order.status = _newStatus;

        emit OrderStatusUpdated(order.orderHash, _newStatus);
    }

    function getOrderCount() public view returns (uint256) {
        return orders.length;
    }

    function hasCommittedInventory(
        address _hospital
    ) public view returns (bool) {
        return inventoryCommitments[_hospital].exists;
    }

    function getInventoryCommitment(
        address _hospital
    ) public view returns (bytes32, uint256) {
        require(
            inventoryCommitments[_hospital].exists,
            "no inventory committed by this hospital"
        );
        return (
            inventoryCommitments[_hospital].inventoryHash,
            inventoryCommitments[_hospital].timestamp
        );
    }
}
