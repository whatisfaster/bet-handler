import {BN} from 'bn.js';
import Web3 from 'web3';
import type {Unit} from "web3-utils";


function interval(min=0, max=1, units:Unit='wei') {
    let rnd = Math.round(min + (max-min)*Math.random());
    return new BN(Web3.utils.toWei(String(rnd), units));
}

function intervalBN(min:number, max:number) {
    let minBN = new BN(min);
    let maxBN = new BN(max);
    const MP = 100000000;
    let rnd = Math.round(MP * Math.random());
    return minBN.add(maxBN.sub(minBN).mul(new BN(rnd)).div(new BN(MP)));
}

function bn(bytes:number=32){
    return new BN(Web3.utils.randomHex(bytes).substr(2), 16);
}

export default {
    interval,
    intervalBN,
    bn
};
