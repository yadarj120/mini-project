#!/bin/bash

while true; do 

    VERSION="helloversion"
    yarn hardhat run scripts/verifypeer1.js --network localhost
    
    sleep 300
done