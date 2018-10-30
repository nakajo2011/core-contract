pragma solidity ^0.4.23;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract DFcore is Ownable {

  struct PJ {
    string purpose;
    uint target;
    uint amount;
    uint limittime;
    address[] supportersArray;
    mapping (address => uint) funds;  //支援者の誰がどれだけ投げてくれたのかを記録しておく
  }

  PJ[] public PJs;
  mapping (uint => address) public PJToOwner;
  mapping (address => uint) public ownerPJCount;

  modifier onlyOwnerOf(uint _PJId) {
    require(msg.sender == PJToOwner[_PJId]);
    _;
  }

  function makePJ(string _purpose, uint _target) public {  // クラウドファンディングのETHを貯める箱を作る関数
    uint _limittime = now + 30 days; //とりあえずデフォルトで期限を30日と設定
    address[] memory _supportersArray;
    uint id = PJs.push(PJ(_purpose,_target, 0, _limittime, _supportersArray)) - 1;
    PJToOwner[id] = msg.sender;
    ownerPJCount[msg.sender]++;
  }

  function deposit(uint _id) public payable { // 箱にETHを投げる関数
    require(PJs[_id].amount < PJs[_id].target);
    require(now <= PJs[_id].limittime);
    PJs[_id].amount = PJs[_id].amount + msg.value;
    PJs[_id].supportersArray.push(msg.sender);
    PJs[_id].funds[msg.sender] = msg.value;
  }

  function success_withdraw(uint _id) public onlyOwnerOf(_id) {  // 箱の中が満額以上の時のみ、PJ製作者がのみが実行してお金を引き出すことができる
    require(PJs[_id].amount >= PJs[_id].target);
    uint nakami = PJs[_id].amount;
    PJs[_id].amount = 0;
    ownerPJCount[PJToOwner[_id]]--;
    PJToOwner[_id] = owner; //ownerはコントラクト作成者
    ownerPJCount[owner]++;
    msg.sender.transfer(nakami);
  }

  function failure_withdraw(uint _id) public {  // 期限を超えて、目標額集まらなかった時に、貯めたお金を支援者に返金する
    require(now > PJs[_id].limittime);
    require(PJs[_id].amount < PJs[_id].target);
    for (uint i = 0; i < PJs[_id].supportersArray.length; i++) {
      address supporteraddress = PJs[_id].supportersArray[i];
      uint siengaku = PJs[_id].funds[supporteraddress];
      PJs[_id].funds[supporteraddress] = 0;
      supporteraddress.transfer(siengaku);
    }
  }

  function getPJByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerPJCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < PJs.length; i++) {
      result[counter] = i;
      counter++;
    }
    return result;
  }

  function getPJInfo(uint _id) public view returns(string, uint256, uint256, uint256, address[]) {
    return (PJs[_id].purpose, PJs[_id].target, PJs[_id].amount, PJs[_id].limittime, PJs[_id].supportersArray);
  }

  function getPJFunds(uint _id, address _address) public view returns(uint256) {
    return (PJs[_id].funds[_address]);
  }

}
