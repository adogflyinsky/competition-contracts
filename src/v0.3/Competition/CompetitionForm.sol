// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract CompetitionForm {
    
    struct Form {
        uint256 id;
        address owner;
        uint256 prizeAmount;
        uint256[] prizeRatio;
    }

    Form[] internal forms;
    mapping(uint256 => uint256) internal trackingForm;

    function _initialize(uint256 id, uint256 prizeAmount, uint256[] memory prizeRatio) internal  {
        Form memory form;
        form.id = id;
        form.owner = msg.sender;
        form.prizeAmount = prizeAmount;
        form.prizeRatio = prizeRatio;
        forms.push(form);
        trackingForm[id] = forms.length - 1;
    }

    function _remove(uint256 id) internal isInForm(id) {
        uint256 index = trackingForm[id];
        Form memory lastForm = forms[forms.length - 1];
        forms[index] = lastForm;
        trackingForm[lastForm.id] = index;
        trackingForm[id] = 0;
        forms.pop();
    }
    
    function inForm(uint256 id) public view virtual returns(bool) {
        if (forms.length == 0) {
            return false;
        }
        if (trackingForm[id] == 0 && forms[0].id != id) {
            return false;
        }
        return true;
    }

    function getForm(uint256 id) public view isInForm(id) returns (Form memory) {
        uint256 index = trackingForm[id];
        return forms[index];
    }
    
    modifier isInForm(uint256 id) virtual {
        require(inForm(id), "This id is not in Form");
        _;
    }
}