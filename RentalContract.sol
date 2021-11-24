//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";

contract RentalContract is ERC721 {//openzeppelin ERC721을 상속한 렌탈 계약

 struct Rental {//대여 내용을 저장할 구조체
     address proprietary; //물품주인
     string agreement; //계약 내용
     uint256 endtime; //렌탈 종료 시간
     uint16 period; //렌탈 기간(일)
     uint16 debt; //담보 가치
     uint16 pay; //일일대여료
 }
 Rental[] public rental;
 uint256 public toOwnercheck;
 mapping(address => uint256) collateral;
 mapping(address => mapping(address => bool)) rentcheck;
 mapping(uint256 => bool) backcheck;
 
 //대여보증서는 토큰으로써 rentalcontract라는 이름을 가지고 심볼은 RENT이다.
 constructor() public ERC721("rentalcontract","RENT") {}

 //대여자가 담보를 스마트컨트랙트에 맡기고 대여보증서를 발급
 function mint(address _from,string memory _agreement, uint16 _period, uint16 _debt, uint16 _pay) public payable{
     require(rentcheck[_from][msg.sender] == true);//"물품 소유자에게 대여를 허락받아야 한다."
     require(msg.value >= _debt * (10 **(18)));//물품 담보이상의 금액을 입금해야 한다.
     
     collateral[msg.sender] = msg.value;
     
     uint256 rentalID = rental.length;
     rental.push(Rental(_from,_agreement,block.timestamp + (_period * 1 minutes),_period,_debt,_pay));
     
     _mint(msg.sender,rentalID);
 }
 //물품 소유자가 대여자에게 대여를 허용
 function rentAllow(address _to) public {
     require(msg.sender != _to);//"자기자신을 허락할 필요없다."
     
     rentcheck[msg.sender][_to] = true;
 }
 //물품 소유자가 대여자에게 대여를 허용했는지 확인
 function rentAllowCheck(address _from) public view returns (bool){
     require(msg.sender != _from);//자기자신은 체크할 필요가 없음
     
     return rentcheck[_from][msg.sender];
 }
 //물품 소유자가 물품을 돌려 받았을때 대여종료 허용
 function ownBack(uint256 tokenID) public {
     require(msg.sender == rental[tokenID].proprietary);
     backcheck[tokenID] = true;
 }
 //남은 담보 대여자에게 돌려줌, rental nft 파기
 function finishDistribution(uint256 tokenID) public {
    require(ownerOf(tokenID) == msg.sender, "Only the NFT owner can call it");//"NFT를 소유한 대여자만 종료 가능"
    require(block.timestamp >= rental[tokenID].endtime, "rental is not finish");//"대여기간이 아직 끝나지 않음"
    require(backcheck[tokenID] == true, "Can't get confirmation from the owner");

    collateral[msg.sender] -= rental[tokenID].pay*rental[tokenID].period * (10 ** (18));
    
    if(block.timestamp - rental[tokenID].endtime > 0){
        collateral[msg.sender] -= rental[tokenID].pay*((block.timestamp - rental[tokenID].endtime)/ 1 minutes) * (10 ** (18));
    }

    payable(msg.sender).transfer(collateral[msg.sender]);
    payable(address(rental[tokenID].proprietary)).transfer((rental[tokenID].debt * (10 ** (18))) - collateral[msg.sender]);
    
    _burn(tokenID);
 }
 //렌탈남은기간체크 함수
 function timecheck(uint256 tokenID) public view returns (bool){
     require(tokenID < rental.length, "token is not exist");
     require(ownerOf(tokenID) != address(0), "token is not exist");
     
     return (rental[tokenID].endtime > block.timestamp);
 }
}










