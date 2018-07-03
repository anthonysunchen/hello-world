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
    function initSC(uint pI, address next, string loca){
         Proof temp;
         temp.location = loca;
         temp.nextOwner = next;
         temp.owner = msg.sender; //could be modified
         trace[pI].push(temp);
    }

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
  enum Role{
  Buyer,
  Seller,
  Insurer,
  Banker,
  Shipper
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
   function createTrade(string id, Role[] tradePartyRoles){
     trades[id].=tradeParties;
     for(uint i=0; i<tradeParties.length; i++) {
       trades[id].tradePartiesRole[tradeParties[i]]=tradePartyRoles[i];
     }
   }
   function upload(string id, address sender, string docType, string hash, string action) {
   if(actionOnDocUpload(id,sender,docType,action)!=true) {
    return;
   }
   string roleSender=trades[id].tradePartiesRole[sender];
   uint newIndex=(trades[id].typeToDoc[docType].version)+1;
   trades[id].typeToDoc[docType].versionDir[newIndex]=hash;
   trades[id].typeToDoc[docType].stat=Status.UNDER_REVIEW;
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
