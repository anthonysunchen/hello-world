pragma solidity ^0.4.4;
contract Ownable{
  address public owner;
  constructor() public {
      owner=msg.sender;
  }
  modifier ownerOnly{
      require(owner==msg.sender);
      _;
  }
  function transferOwnership(address newOwner) internal ownerOnly{
      require(newOwner!=address(0));
      owner=newOwner;
  }
}

contract TradeRegulation is Ownable{
    //trace
    //The trace functionality is designed in the way that when a party produces a product
    //it needs to upload the information regarding the product onto the blockchain. The proofstatus of
    //that specific information will be set as pending right after the info is uploaded. By the time the receiver
    //received the product, it can choose either to approve or reject it after careful examination. If it rejects it,
    //further resolving actions will be executed.

    struct Proof {//connect name to address
        string location;
        uint productID;
        address owner;
        proofStatus proof ;
        address nextOwner;
        bytes photo;
        mapping(address => proofRoles) roleOfAddress;
        characteristics infoProduct;
    }

    //the content of characteristics is not comprehensive, but it will serve as a conceptual template
    struct characteristics {
        //enum damageOrNot;
        //enum quality;
        bytes productType;
        uint temperature; //some product need transferring within certain temperature range

    }

    enum proofStatus {
        approved,
        pending,
        rejected
    }

    enum proofRoles {
        supplier,
        distributor,
        retailer,
        consumer
    }

    mapping(uint=>Proof[]) trace;  //for a single product, there is only one supply chain

    ///the functions of uploading info in the characterisitcs are not enough, but they will serve as a conceptual template
    function updateProductType ( bytes productType ){
        //Proof.infoProduct.productType = productType;

    }

    //@param pI = productID
    //@param address of the next Owner
    //@param the location of the checkpoint
    //initialize a supply chain (done by raw materials producers)

    /*function initSC(uint pI, address next, string loca, bytes pho){

        //suppliers will have special address?
         Proof temp;
         temp.location = loca;
         temp.nextOwner = next;
         temp.owner = msg.sender; //could be modified
         temp.proof = proofStatus.pending;
         temp.photo = pho;
         temp.roleOfAddress[msg.sender] = proofRoles.supplier;
         trace[pI].push(temp);
    }
    */

     function checkApproved (uint pI) returns (bool){
            require(trace[pI].length != 0);
                    if (trace[pI][trace[pI].length-1].proof == proofStatus.approved){
                        return true;
                    }
                    return false;
     }

     function approve(uint pI, address next)
        {
            require(trace[pI].length != 0);
            if (msg.sender == trace[pI][trace[pI].length-1].nextOwner){
                trace[pI][trace[pI].length-1].proof = proofStatus.approved ;
            }

        }

     function reject (uint pI, address next)
        {
            require(trace[pI].length != 0);
            if (msg.sender == trace[pI][trace[pI].length-1].nextOwner){
                trace[pI][trace[pI].length-1].proof = proofStatus.rejected ;
            }
        }

    //@param pI = productID
    //@param  status = whether you approve it or not
    //approve that the status of the product is correct

    //upload function can be modified according to real world situation; ex. if IoT can upload location by itself, there is no need to upload it manually.
    //a separate function can be written

    function uploadInfo (uint pI, proofStatus status, address next, string location, bytes photo, proofRoles)
    {
            if (checkApproved(pI)){
            Proof temp;
            temp.location = location;
            temp.nextOwner = next;
            temp.owner = msg.sender;
            temp.photo=photo;
            trace[pI].push(temp);

        }
    }

    function checkNodes (uint pI, uint stage) returns (string, address, proofStatus, address){
        Proof storage temp = trace[pI][stage];
        return(temp.location, temp.owner, temp.proof, temp.nextOwner );//could be changed
    }

    //trace
  enum Status{
      NOT_UPLOADED,
      UNDER_REVIEW,
      APPROVED,
      REJECTED,
      PARTIALLY_APPROVED
  }
  struct doc{
      mapping(uint=>bytes) versionDir;
      Status stat;
      uint version;
  }
  struct LetterOfCredit{
      uint numDays;
      uint creditAmt;
      Status stat;
  }
  /*
  Struct that has characteristics of number of days before payment,
  the owed money amount, and the status of the invoice.
  */
  struct Invoice{
      uint numDays;
      uint owedAmt;
      Status stat;
  }
  /*
  Struct with characteristics of a transaction between parties in supply chain.
  */
  struct Tx{
       address[] tradeParties;
       mapping(address=>bytes32) tradePartiesRole;
       mapping(bytes32=>doc) typeToDoc;
       mapping(bytes32 => address) ethAddressByRole;
       LetterOfCredit loc;
       Invoice inv;
       uint insuranceAmt;
       uint shippingDate;
       uint locIssueDate;
       uint version;
       uint objCount;
       bytes32 tradeId;
   }
   mapping(bytes32=>Tx) trades;
   mapping(bytes32=>uint) amountCondition;



   event TradeCreated(bytes32 id);
   event DocumentUploaded(bytes32 id, bytes32 docType);
   event SellerPayed(bytes32 id, bool success);
   event InsurerPayed(bytes32 id);
   event DepositMade(bytes32 id, uint amount);

   function createTrade(bytes32 id, address[] tradeParties, bytes32[] tradePartiesRole, uint objCount, uint insuranceAmt) {
    trades[id].tradeParties = tradeParties;

    for (uint i = 0; i < tradeParties.length; i++) {
      trades[id].tradePartiesRole[tradeParties[i]] = tradePartiesRole[i];
      trades[id].ethAddressByRole[tradePartiesRole[i]] = tradeParties[i];
    }
    trades[id].objCount=objCount;
    trades[id].insuranceAmt=insuranceAmt;
    trades[id].version=0;
    trades[id].tradeId=id;
    TradeCreated(id);
   }


   function upload(bytes32 uid, address sender, bytes32 docType, bytes _hash) {
    bytes32 role = trades[uid].tradePartiesRole[sender];
    if (isUploadAllowed(role, docType)) {
      uint currIndex = trades[uid].typeToDoc[docType].version++;
      trades[uid].typeToDoc[docType].versionDir[currIndex] = _hash;
      trades[uid].typeToDoc[docType].stat = Status.UNDER_REVIEW;
      DocumentUploaded(uid,docType);
    } else return;
  }

    function isRightParties (bytes32 id ) returns (bool){
       for (uint i = 0; i < trades[id].tradeParties.length; i++){
            if ( trades[id].tradeParties[i]  == msg.sender){
                return true;
            }
       }
       return false;
    }

  function isUploadAllowed(bytes32 role, bytes32 docType) internal returns(bool success) {
     bool isAllowed = false;
     if ((role == "buyer" && (docType == "PurchaseOrder")) ||
       ((role == "seller") && (docType == "Invoice")) ||
       (role == "shipper" && docType == "BillOfLading") || (role == "insurer" && docType == "InuranceQuotation")) {
       isAllowed = true;
     }
     return isAllowed;
   }


   function payToSeller(bytes32 id) {
   if(!isAmtMet) {
    revert("Incorrect Amount Received!");
   }
     if(now>trades[id].shippingDate+trades[id].loc.numDays && trades[id].shippingDate<(trades[id].locIssueDate+trades[id].loc.numDays) && isRightParties(id)) {
       trades[id].ethAddressByRole["seller"].transfer(trades[id].loc.creditAmt);
       SellerPayed(id, true);
     }
     SellerPayed(id, false);
   }


   function payToInsurer(bytes32 id) {
     trades[id].ethAddressByRole["insurer"].transfer(trades[id].insuranceAmt);
     InsurerPayed(id);
   }

   bool isAmtMet=false;

   function isAmountMet(uint amountReceived, bytes32 id) returns (bool) {
    if(trades[id].objCount==amountReceived) {
      isAmtMet=true;
      return true;
    }
    isAmtMet=false;
    return false;
   }


   function depositFunds(bytes32 id) payable{

    DepositMade(id, msg.value);
   }
}
