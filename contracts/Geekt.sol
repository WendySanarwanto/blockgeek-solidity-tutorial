pragma solidity ^0.4.17;

contract Geekt {
  address GeektAdmin;

  mapping (bytes32 => NotarisedImage) notarisedImages; // this allows to look up notarizedImages by their SHA256notaryHash
  bytes32[] imagesByNotaryHash; // this is like a whitepages of all images, by SHA256notaryHash

  struct NotarisedImage {
    string imageUrl;
    uint timeStamp;
  }

  mapping ( address => User) users; // this allows to look up Users by their ethereum address
  address[] usersByAddress;  // this is like a whitepages of all users, by ethereum address

  struct User {
    string handle;
    bytes32 city;
    bytes32 state;
    bytes32 country;
    bytes32[] myImages;
  }

  function Geekt() public payable { // this is the CONSTRUCTOR (same name as contract) it gets called ONCE only when contract is first deployed
    GeektAdmin = msg.sender;  // just set the admin, so they can remove bad users or images if needed, but nobody else can
  }

  modifier onlyAdmin() {
    assert(msg.sender != GeektAdmin);
    // Do not forget the "_;"! It will be replaced by the actual function body when the modifier is used.
    _;
  }

  // function removeUser(address badUser) public onlyAdmin returns(bool success) {
  function removeUser(address badUser) public onlyAdmin returns(bool success) {
    delete users[badUser];
    return true;
  }

  function removeImage(bytes32 badImage) public onlyAdmin returns(bool success) {
    delete notarisedImages[badImage];
    return true;
  }

  function registerNewUser(string handle, bytes32 city, bytes32 state, bytes32 country) public returns(bool success) {
    address senderAddress = msg.sender;

    // don't overwrite existing entries, and make sure handle isn't null
    if (bytes(users[senderAddress].handle).length == 0 && bytes(handle).length != 0) {
      users[senderAddress].handle = handle;
      users[senderAddress].city = city;
      users[senderAddress].state = state;
      users[senderAddress].country = country;
      usersByAddress.push(senderAddress);
      return true;
    } else {
      return false; // either handle was null, or a user with this handle already existed
    }
  }

  function addImageToUser(string imageUrl, bytes32 sha256notaryHash) public returns(bool success) {
    address senderAddress = msg.sender;

    // Make sure this user has created an account first.
    if (bytes(users[senderAddress].handle).length != 0) {
      // Validate params
      if (bytes(imageUrl).length == 0) {
        return false;
      }

      // prevent users from fighting over sha256->image listings in the whitepages, but still allow them to add a personal ref to any sha
      if (bytes(notarisedImages[sha256notaryHash].imageUrl).length == 0) {
        // adds entry for this image to our image whitepages
        imagesByNotaryHash.push(sha256notaryHash);
      }
      notarisedImages[sha256notaryHash].imageUrl = imageUrl;
      notarisedImages[sha256notaryHash].timeStamp = block.timestamp;
      users[senderAddress].myImages.push(sha256notaryHash);
      return true;
    } else {
      // User has no account. Prevent the user from adding the image.
      return false;
    }
  }

  function getUsers() public view returns(address[]) {
    return usersByAddress;
  }

  function getUser(address userAddress) public view returns(string handle,bytes32 city, bytes32 state, bytes32 country,bytes32[] myImages) {
    return (users[userAddress].handle, users[userAddress].city, users[userAddress].state, users[userAddress].country, users[userAddress].myImages);
  }

  function getAllImages() public view returns(bytes32[]) {
    return imagesByNotaryHash;
  }

  function getUserImages(address userAddress) public view returns(bytes32[]) {
    return users[userAddress].myImages;
  }

  function getImage(bytes32 imageNotaryHash) public view returns(string imageUrl, uint timeStamp) {
    return (notarisedImages[imageNotaryHash].imageUrl, notarisedImages[imageNotaryHash].timeStamp);
  }
}