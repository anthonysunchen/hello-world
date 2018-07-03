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
      mapping(uint=>string) versionDir;
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
       mapping(address=>Role) tradePartiesRole;
       mapping(string=>doc) typeToDoc;
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
   mapping(string=>Tx) trades;
   function createTrade(uint id, address next, string loca){
   Tx temp;
   temp.location = loca;
   temp.nextOwner = next;
   temp.owner = msg.sender; //could be modified
   trace[id].push(temp);
   }

   function upload(bytes32 uid, address sender, bytes32 docType, bytes _hash) {
    bytes32 role = trades[uid].tradePartiesRole[sender];
    if (isUploadAllowed(role, docType)) {
      var currIndex = trades[uid].docByType[docType].version++;
      trades[uid].docByType[docType].versiondir[currIndex] = _hash;
      trades[uid].docByType[docType].status = docStatus.UNDER_REVIEW;
    } else return;
  }
  function isUploadAllowed(bytes32 role, bytes32 docType) internal returns(bool success) {
     bool isAllowed = false;
     if ((role == "buyer" && (docType == "PurchaseOrder")) ||
       ((role == "seller") && (docType == "Quotation")) ||
       (role == "shipper" && docType == "BillOfLading") || (role == "insurer" && docType == "InuranceQuotation")) {
       isAllowed = true;
     }
     return isAllowed;
   }
   function payToSeller(string id) {
     if(now>trades[id].shippingDate+trades[id].loc.numDays && trades[id].shippingDate<(trades[id].issueDate+trades[id].loc.numDays)) {
       trades[id].ethAddressByRole["seller"].transfer(trades[id].loc.creditAmount);
     }
   }
   function payToInsurer(string id) {
     trades[id].ethAddressByRole["insurer"].transfer(trades[id].insuranceAmt);
   }
}
