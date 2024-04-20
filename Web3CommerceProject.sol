// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// REQUIREMENT 

// Feature List
// 1. User Credential
// 2. Storage System
// 3. CRUD (Create, Read, Update, Delete) Product
// 4. CRUD (Create, Read, Update, Delete) Store
// 5. Transaction

// Database
// 1. User : Wallet Address, User ID,  Username, Password, Email, Birth Date, Registration Timestamp
// 2. Store : Wallet Address, Store ID, Store Name, Store Description, Store Picture, Store Location, Store Timestamp
// 3. Prodcut Category : Category ID, Category Name
// 4. Product : Store ID, Product ID, Product Name, Product Description, Product Picture, Product Category, Product Price, Product Stock, Product Timestamp
// 5. Transaction : Transaction ID, Buyer Address, Seller Address, Store ID, Product ID, Product Name, Product Price, Transaction Status, Transaction Confirmation, Transaction Timestamp


contract web3Commerce {

    //User Data List
    struct User {
        address walletAddress;
        string username;
        string password;
        string name;
        string email;
        uint birthDate;
        uint registrationTimestamp;
        uint storeCounter;
    }
    //User data mapping base on user address
    mapping (address => User) public userDB;
    //Registered user list
    address [] public userList;

    //Store Data List
    struct Store {
        address walletAddress;
        address payable paymentAddress;
        uint256 storeID;
        string storeName;
        string storeDescription;
        bytes32 storePicture;
        string storeLocation;
        uint256 storeTimestamp;
        uint productCounter;
    }
    //Store data mapping base on user address
    mapping (address => Store []) public storeDB;

    //Category Data List
    struct Category {
        uint256 categoryID;
        string categoryName;
    }
    //Category data array base on index
    Category [] public categoryDB;

    //Product Data List
    struct Product {
        uint256 storeID;
        uint256 productID;
        string productName;
        string productDescription;
        bytes32 productPicture;
        uint categoryIndex;
        uint256 productPrice;
        uint256 productStock;
        uint256 productTimestamp;
        uint256 amountOfSoldCounter;
    }
    //Product data mapping base on storeID
    mapping (uint256 => Product []) public productDB;

    struct Transaction {
        uint256 transactionID;
        address buyer;
        address seller;
        address paymentWallet;
        uint256 storeID;
        uint256 productID;
        string productName;
        uint amountToBuy;
        uint256 productPrice;
        bool transactionStatus;
        bool transactionConfirmation;
        uint256 transactionTimestamp;
    }
    mapping (address => Transaction []) transactionDB;

    address owner;
    address devOps;
    address backupAddress;
    address payable feeAddress;
    
    constructor(){
        owner = msg.sender;
        feeAddress = payable (0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    }


    event CredentialValidation (bytes32 _usernameHash, bytes32 _passwordHash, bytes32 _usernameDB, bytes32 _passwordDB);
    event StoreRegistration (address walletAddress, uint256 storeID, string storeName, string storeDescription, bytes32 storePicture, string storeLocation, uint256 storeTimestamp);
    event ProductRegistration (uint256 _storeID, uint256 _productID, string _productName, string _productDescription, bytes32 _productPicture, uint _categoryIndex,uint256  _productPrice, uint _productStock, uint256 _productTimestamp);
    event input(address walletAddress, address sender);
    event Test(address addressCrawl);
    event TransactionReport(address _buyer, address _seller, uint256 _storeID, uint256 _productID, uint256 _amountAfterFee, uint256 _amountFee);

    function userRegistration (string memory _username, string memory _password, string memory _name, string memory _email, uint _birthDate) external returns (bool){
        emit input(userDB[msg.sender].walletAddress, msg.sender);
        require(isUserRegistered(msg.sender) == false, "User already exist");
        userDB[msg.sender].walletAddress = msg.sender;
        userDB[msg.sender].username = _username;
        userDB[msg.sender].password = _password;
        userDB[msg.sender].name = _name;
        userDB[msg.sender].email = _email;
        userDB[msg.sender].birthDate = _birthDate;
        userDB[msg.sender].registrationTimestamp = block.timestamp;
        userDB[msg.sender].storeCounter = 0;
        userList.push(msg.sender);
        return true;
    }

    function isUserRegistered (address _user) internal view returns (bool){
        return (userDB[_user].walletAddress == _user);
    }

    function credentialValidation (address _guest, string memory _username, string memory _password) internal returns (bool, uint256 _accessKey){
        bytes32 _usernameHash = keccak256(abi.encodePacked(_username));
        bytes32 _passwordHash = keccak256(abi.encodePacked(_password));
        bytes32 _usernameDB = keccak256(abi.encodePacked(userDB[_guest].username));
        bytes32 _passwordDB = keccak256(abi.encodePacked(userDB[_guest].password));
        require( _usernameDB == _usernameHash && _passwordDB == _passwordHash, "Username or Password didnt match");
        emit CredentialValidation(_usernameHash, _passwordHash, _usernameDB, _passwordDB);
        return (true, uint256 (keccak256(abi.encodePacked(_usernameHash, _passwordHash, block.timestamp))));
    }

    function storeRegistration (address payable _paymentAddress, string memory _storeName, string memory _storeDescription, bytes32 _storePicture, string memory _storeLocation) external returns (bool){
        require(isUserRegistered(msg.sender) == true, "User not registered");
        storeDB[msg.sender].push(Store(msg.sender, _paymentAddress, uint256 (keccak256(abi.encodePacked(_storeName,block.timestamp))), _storeName, _storeDescription, _storePicture, _storeLocation, block.timestamp, 0));
        userDB[msg.sender].storeCounter ++;
        emit StoreRegistration (msg.sender, uint256 (keccak256(abi.encodePacked(_storeName,block.timestamp))), _storeName, _storeDescription, _storePicture, _storeLocation, block.timestamp);
        return true;
    }

    function getOwnedStoreList () external view returns (Store [] memory _storeList) {
        return (storeDB[msg.sender]);
    }

    function updateOwnedStore(uint _storeIndex, string memory _storeName, string memory _storeDescription, bytes32 _storePicture, string memory _storeLocation) external returns (bool){
        require(isStoreRegistered(storeDB[msg.sender][_storeIndex].storeID));
        storeDB[msg.sender][_storeIndex].storeName = _storeName;
        storeDB[msg.sender][_storeIndex].storeDescription = _storeDescription;
        storeDB[msg.sender][_storeIndex].storePicture = _storePicture;
        storeDB[msg.sender][_storeIndex].storeLocation = _storeLocation;
        return true;
    }

    function deleteOwnedStore (uint16 _removedIndex) external returns (bool) {
        require(storeDB[msg.sender].length > 0, "No element in Array.");
        uint256 storeID = storeDB[msg.sender][_removedIndex].storeID;
        storeDB[msg.sender][_removedIndex] = storeDB[msg.sender][storeDB[msg.sender].length-1];
        storeDB[msg.sender].pop();
        delete productDB[storeID];
        return true;
    }
    
    function isStoreRegistered (uint256 _storeID) internal view returns (bool) {
        uint i = userDB[msg.sender].storeCounter;
        while (i >= 0){
            i --;
            if(storeDB[msg.sender][i].storeID == _storeID){
                return true;
            }
        }
        return false;
    }

    function productRegistration (uint256 _storeID, string memory _productName, string memory _productDescription, bytes32 _productPicture, uint _categoryIndex, uint256 _productPrice, uint _productStock) external returns (bool) {
        require (isStoreRegistered(_storeID) == true, "Store not registered");
        require(isCategoryAvailable(_categoryIndex), "Category dont exist");
        productDB[_storeID].push(Product(_storeID, uint256 (keccak256(abi.encodePacked(_productName,block.timestamp))), _productName, _productDescription, _productPicture, _categoryIndex, _productPrice, _productStock, block.timestamp, 0));
        emit ProductRegistration(_storeID, uint256 (keccak256(abi.encodePacked(_productName,block.timestamp))), _productName, _productDescription, _productPicture, _categoryIndex, _productPrice, _productStock, block.timestamp);
        uint i = userDB[msg.sender].storeCounter;
        while (i >= 0){
            i --;
            if(storeDB[msg.sender][i].storeID == _storeID){
                storeDB[msg.sender][i].productCounter ++;
                break;
            }
        }
        return true;

    }

    function getProductListFromStore (uint256 _storeID) external view returns (Product [] memory _productList) {
        return (productDB[_storeID]);
    }

    function updateOwnedProduct(uint _productIndex, uint256 _storeID, string memory _productName, string memory _productDescription, bytes32 _productPicture, uint _categoryIndex, uint _productPrice, uint _productStock) external returns (bool){
        require(isProductRegistered(msg.sender, productDB[_storeID][_productIndex].productID, _storeID));
        productDB[_storeID][_productIndex].productName = _productName;
        productDB[_storeID][_productIndex].productDescription = _productDescription;
        productDB[_storeID][_productIndex].productPicture = _productPicture;
        productDB[_storeID][_productIndex].categoryIndex = _categoryIndex;
        productDB[_storeID][_productIndex].productPrice = _productPrice;
        productDB[_storeID][_productIndex].productStock = _productStock;
        return true;
    }

    function isProductRegistered (address _storeAddress, uint256 _productID, uint256 _storeID) internal view returns (bool) {
        uint i = userDB[_storeAddress].storeCounter;
        while (i >= 0){
            i --;
            if(storeDB[_storeAddress][i].storeID == _storeID){
                uint j = storeDB[_storeAddress][i].productCounter;
                while (j >= 0){
                    j --;
                    if(productDB[_storeID][j].productID == _productID){
                        return true;
                    }  
                }
            }
        }
        return false;
    }

    function deleteOwnedProduct (uint16 _removedIndex,uint256 _storeID) external returns (bool) {
        require(productDB[_storeID].length > 0, "No element in Array.");
        productDB[_storeID][_removedIndex] = productDB[_storeID][productDB[_storeID].length-1];
        productDB[_storeID].pop();
        return true;
    }

    function isContractOwner () internal view returns (bool){
        return (msg.sender == owner || msg.sender == devOps || msg.sender == backupAddress);
    }

    function categoryRegistration (string memory _categoryName) external returns (bool) {
        require(isContractOwner(), "Only owner and devOps can access");
        categoryDB.push(Category({categoryID : uint256 (keccak256(abi.encodePacked(_categoryName,block.timestamp))), categoryName : _categoryName}));
        return true;
    }

    function isCategoryAvailable (uint _categoryIndex) internal view returns (bool){
        return (categoryDB[_categoryIndex].categoryID != 0);
    }

    function transaction(uint256 _storeID, uint256 _productIndex, uint256 _amountToBuy) external payable returns (bool) {
        uint256 _value = msg.value;
        require(isUserRegistered(msg.sender), "Buyer address not registered to permit transaction");
        (address _storeAddress, uint _index) = getStoreAddress(_storeID);
        require(isProductRegistered(_storeAddress, productDB[_storeID][_productIndex].productID, _storeID), "Product not registered");
        require(checkStockAvalability(_storeID, _productIndex, _amountToBuy));
        require(valueToPriceValidation(_storeID, _productIndex, _value, _amountToBuy));
        address _storeWalletAddress = storeDB[_storeAddress][_index].walletAddress;
        address payable _storePaymentAddress = storeDB[_storeAddress][_index].paymentAddress;
        require(isUserRegistered(_storeWalletAddress), "Seller address not match or registered");
        uint256 _amountAfterFee = (msg.value) * 900 / 1000;
        uint256 _amountFee = (msg.value) - _amountAfterFee;
        require(transferPayment(_storePaymentAddress, _amountAfterFee) && transferPayment(feeAddress, _amountFee), "Payment failed");
        uint256 __amountToBuy = _amountToBuy; 
        productDB[_storeID][_productIndex].productStock -= __amountToBuy;
        productDB[_storeID][_productIndex].amountOfSoldCounter += __amountToBuy;
        uint256 _productID = productDB[_storeID][_productIndex].productID;
        string memory _productName = productDB[_storeID][_productIndex].productName;
        uint256 __storeID = _storeID;
        uint256 _productPrice = productDB[__storeID][_productIndex].productPrice;
        transactionRecord(msg.sender, _storeWalletAddress, _storePaymentAddress, __storeID, _productID, _productName, __amountToBuy, _productPrice);
        emit TransactionReport(msg.sender, _storePaymentAddress, __storeID, _productID, _amountAfterFee, _amountFee);
        return true;

    }

    function transactionRecord(address _buyer, address _seller, address _paymentWallet, uint256 _storeID, uint256 _productID, string memory _productName, uint _amountToBuy, uint256 _productPrice) internal returns(bool){
        uint256 _timeStamp = block.timestamp;
        uint256 _transactionID = uint256 (keccak256(abi.encodePacked(_buyer,_seller,_timeStamp)));
        transactionDB[_buyer].push(Transaction(_transactionID, _buyer, _seller, _paymentWallet, _storeID, _productID, _productName, _amountToBuy, _productPrice, true, false, _timeStamp));
        transactionDB[_seller].push(Transaction(_transactionID, _buyer, _seller, _paymentWallet, _storeID, _productID, _productName, _amountToBuy, _productPrice, true, false, _timeStamp));
        return true;
    }

    function getStoreAddress(uint256 _storeID) internal view returns (address _walletAddress, uint _index){
        uint i = userList.length;
        uint j = 0;
        while (i >= 0) 
        {   
            i--;
            address _addr = userList[i];
            j = storeDB[_addr].length;
            if(j != 0){
                while (j >= 0){
                    j--;
                    if(storeDB[userList[i]][j].storeID == _storeID){
                        return (storeDB[userList[i]][j].walletAddress, j);
                    }
                }
            }
        }
        // return false;
    }

    function transferPayment(address payable _paymentAddress, uint256 _amount) public payable returns (bool) {
        _paymentAddress.transfer(_amount);
        return true;
    }

    function checkStockAvalability(uint256 _storeID, uint256 _productIndex, uint _amountToBuy) internal view returns (bool) {
        require(productDB[_storeID][_productIndex].productStock >= _amountToBuy, "Not enough stock to buy");
        return true;
    }

    function valueToPriceValidation (uint256 _storeID, uint _productIndex, uint256 _value, uint _amountToBuy) internal view returns (bool) {
        require((productDB[_storeID][_productIndex].productPrice * _amountToBuy) == _value, "Insuficient balance or send correct amout of ether to buy product");
        return true;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    

}
