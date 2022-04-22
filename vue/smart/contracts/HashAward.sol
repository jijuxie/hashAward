// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashAward {
    address public manager;
    uint256 public nowTurn;
    uint256 public maxPlayersOneTurn;
    uint8 public pauseData;
    uint256 public oneBetFee;
    uint8 public loudFee100;
    mapping(uint256 =>  address [] ) public  turnsPlayers;
    mapping(uint256 => address  ) public turnsWinner;
    mapping(uint256 => uint256) public turnsHash;
    mapping(uint256 => uint256) public turnsValues;
    mapping(uint256 => uint8) public turnsActions;
    mapping(uint8 => string)  ActionsMessage;

    constructor (){
        manager = msg.sender;
        nowTurn = 0;
        turnsActions[0]=1;
        pauseData=0;
        maxPlayersOneTurn=10;
        ActionsMessage[0] = 'not start yet';
        ActionsMessage[1] = 'start already';
        ActionsMessage[2] = 'need draw a lottery';
        ActionsMessage[3] = 'over';
        oneBetFee=1e16;
        loudFee100=5;
    }
    //error this
    function getNowturnsPlayers() public view returns( address[]){
        return  turnsPlayers[nowTurn];
    }



    modifier onlyManager(){
        require(msg.sender == manager, 'only manager can call this function');
        _;
    }
    function pause() public   onlyManager{
        pauseData=1;
    }
    function unpause() public  onlyManager{
        pauseData=0;
    }
    modifier checkPause(){
        require(pauseData==0,'pauseing');
        _;
    }
    function stringAdd(string memory a, string memory b) pure public returns(string memory){
        bytes memory _a = bytes(a);
        bytes memory _b = bytes(b);
        bytes memory res = new bytes(_a.length + _b.length);
        for(uint i = 0;i < _a.length;i++)
            res[i] = _a[i];
        for(uint j = 0;j < _b.length;j++)
            res[_a.length+j] = _b[j];
        return string(res);
    }

    function bet() public checkPause payable{

        require(turnsActions[nowTurn]==1,'now turn can not bet');
        require(msg.value==oneBetFee,'bet fee error');
        turnsPlayers[nowTurn].push(msg.sender);
        turnsValues[nowTurn]+=oneBetFee;
        if(turnsPlayers[nowTurn].length>=maxPlayersOneTurn){
            turnsActions[nowTurn]=2;
            openAward ();
        }
    }
    function overBet() onlyManager public {
        require(turnsActions[nowTurn]==1,'now turn can not over bet');
        turnsActions[nowTurn]=2;
    }
    function openAward () public{
        require(turnsActions[nowTurn]==2,'now turn can not open award');
        turnsHash[nowTurn]= uint256( keccak256(abi.encodePacked(turnsPlayers[nowTurn],block.difficulty,block.timestamp)));
        if(turnsPlayers[nowTurn].length>=1){
            if(turnsPlayers[nowTurn].length==1){
                turnsWinner[nowTurn]=turnsPlayers[nowTurn][0];
            }else{
                turnsWinner[nowTurn]=turnsPlayers[nowTurn][turnsHash[nowTurn]%turnsPlayers[nowTurn].length] ;
            }
            payable(turnsWinner[nowTurn]).transfer(uint256(turnsValues[nowTurn]*loudFee100/100));
        }
        turnsActions[nowTurn]=3;
        nowTurn+=1;
    }

}
