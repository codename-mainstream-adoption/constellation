forge create --rpc-url $ARB_DEV_RPC_URL \
    --constructor-args 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 \
    --private-key $ARB_DEV_PKEY \
    src/VerimedianSimple.sol:VerimedianSimple