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
    struct Proof {//connect name to address
        string location;
        uint productID;
        address owner;
        proofStatus proof ;
        address nextOwner;
    }

    enum proofStatus {
        approved,
        pending,
        rejected
    }

    mapping(uint=>Proof[]) trace;

    //@param pI = productID
    //@param address of the next Owner
    //@param the location of the checkpoint
    //initialize a supply chain (done by raw material producer)
    /*function initSC(uint pI, address next, string loca){
         Proof temp;
         temp.location = loca;
         temp.nextOwner = next;
         temp.owner = msg.sender; //could be modified
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

     function approve (uint pI, address next)
        {
            require(trace[pI].length != 0);
            if (msg.sender == trace[pI][trace[pI].length-1].owner){
                trace[pI][trace[pI].length-1].proof = proofStatus.approved ;
            }
        }

     function reject (uint pI, address next)
        {
            require(trace[pI].length != 0);
            if (msg.sender == trace[pI][trace[pI].length-1].owner){
                trace[pI][trace[pI].length-1].proof = proofStatus.rejected ;
            }
        }

    //@param pI = productID
    //@param  status = whether you approve it or not
    //approve that the status of the product is correct

    function uploadInfo (uint pI, proofStatus status, address next, string location)
    {
            if (checkApproved(pI)){
            Proof temp;
            temp.location = location;
            temp.nextOwner = next;
            temp.owner = msg.sender;
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
  struct Invoice{
      uint numDays;
      uint owedAmt;
      Status stat;
  }

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
       string location;
       uint productID;
       address owner;
       proofStatus proof ;
       address nextOwner;
   }
   mapping(bytes32=>Tx) trades;
   mapping(bytes32=>uint) amountCondition;

   function createTrade(bytes32 uid, address[] tradeParties, bytes32[] tradePartiesRole) {
    trades[uid].tradeParties = tradeParties;
    for (uint i = 0; i < tradeParties.length; i++) {
      trades[uid].tradePartiesRole[tradeParties[i]] = tradePartiesRole[i];
    }
   }

   function upload(bytes32 uid, address sender, bytes32 docType, bytes _hash) {
    bytes32 role = trades[uid].tradePartiesRole[sender];
    if (isUploadAllowed(role, docType)) {
      uint currIndex = trades[uid].typeToDoc[docType].version++;
      trades[uid].typeToDoc[docType].versionDir[currIndex] = _hash;
      trades[uid].typeToDoc[docType].stat = Status.UNDER_REVIEW;
    } else return;
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
   if(!isAmountMet) {
    return;
   }
     if(now>trades[id].shippingDate+trades[id].loc.numDays && trades[id].shippingDate<(trades[id].locIssueDate+trades[id].loc.numDays)) {
       trades[id].ethAddressByRole["seller"].transfer(trades[id].loc.creditAmt);
     }
   }
   function payToInsurer(bytes32 id) {
     trades[id].ethAddressByRole["insurer"].transfer(trades[id].insuranceAmt);
   }
   function createConditions(uint amount, bytes32 id) {
    amountCondition[id]=amount;
   }
   function isAmountMet(uint amountReceived, bytes32 id) returns (bool) {
    if(amountCondition[id]==amountReceived) {
      return true;
    }
    return false;
   }
}
