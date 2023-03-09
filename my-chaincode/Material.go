package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

//定义原料结构体
type Component struct {
	ID    string `json:"ID"`
	Class string `json:"class"`
	Maker string `json:"maker"`
	Price int    `json:"price"`
	Owner string `json:"owner"`
}

//初始化账本，定义几个已有原料
func (s *SmartContract) InitLedger(contextInterface contractapi.TransactionContextInterface) error {
	components := []Component{
		{ID: "component1", Class: "steel", Maker: "John", Price: 10, Owner: "John"},
		{ID: "component2", Class: "rubber", Maker: "Alex", Price: 5, Owner: "Alex"},
		{ID: "component3", Class: "platic", Maker: "Mike", Price: 10, Owner: "Mike"},
	}

	for _, component := range components {
		bytes, err := json.Marshal(component)
		if err != nil {
			return err
		}
		err = contextInterface.GetStub().PutState(component.ID, bytes)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %s", err.Error())
		}
	}
	return nil
}

//查询原料是否存在
func (s *SmartContract) IsExists(contextInterface contractapi.TransactionContextInterface, id string) (bool, error) {
	_, err := contextInterface.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("id %s does not exist. %s", id, err.Error())
	}
	return true, nil
}

//增加新原料
func (s *SmartContract) Create(contextInterface contractapi.TransactionContextInterface, id string, class string, maker string, price int, owner string) error {
	isExists, _ := s.IsExists(contextInterface, id)
	if isExists {
		return fmt.Errorf("failed to create because id %s already exists", id)
	}
	component := Component{
		ID:    id,
		Class: class,
		Maker: maker,
		Price: price,
		Owner: owner,
	}

	bytes, err := json.Marshal(component)
	if err != nil {
		return err
	}

	return contextInterface.GetStub().PutState(id, bytes)
}

//删除某一原料信息
func (s *SmartContract) Delete(contextInterface contractapi.TransactionContextInterface, id string) error {
	isExists, _ := s.IsExists(contextInterface, id)
	if !isExists {
		return fmt.Errorf("failed to delete because id %s does not exist", id)
	}

	return contextInterface.GetStub().DelState(id)
}

//查询某一原料信息
func (s *SmartContract) Query(contextInterface contractapi.TransactionContextInterface, id string) (*Component, error) {
	isExists, err := s.IsExists(contextInterface, id)
	if !isExists {
		return nil, fmt.Errorf("failed to query because id %s does not exist. %s", id, err)
	}
	bytes, err := contextInterface.GetStub().GetState(id)
	if err != nil {
		return nil, err
	}
	component := new(Component)
	err = json.Unmarshal(bytes, component)
	return component, err
}

//查询所有信息
func (s *SmartContract) QueryAll(contextInterface contractapi.TransactionContextInterface) ([]*Component, error) {
	byRange, err := contextInterface.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer byRange.Close()

	var result []*Component
	for byRange.HasNext() {
		queryRes, err := byRange.Next()
		if err != nil {
			return nil, err
		}

		component := new(Component)
		_ = json.Unmarshal(queryRes.Value, component)
		result = append(result, component)
	}
	return result, nil
}

//更改所有者
func (s *SmartContract) Transfer(contextInterface contractapi.TransactionContextInterface, id string, newOwner string) error {
	isExists, err := s.IsExists(contextInterface, id)
	if !isExists {
		return fmt.Errorf("failed to transfer because id %s does not exist. %s", id, err)
	}
	bytes, _ := contextInterface.GetStub().GetState(id)

	component := new(Component)
	err = json.Unmarshal(bytes, component)
	if err != nil {
		return err
	}
	component.Owner = newOwner

	marshal, err := json.Marshal(component)
	if err != nil {
		return err
	}
	err = contextInterface.GetStub().PutState(id, marshal)
	if err != nil {
		return err
	}
	return nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(SmartContract))
	if err != nil {
		fmt.Printf("Failed to create a new chaincode. %s", err.Error())
		return
	}

	err = chaincode.Start()
	if err != nil {
		fmt.Printf("Error starting the chaincode")
		return
	}
}
