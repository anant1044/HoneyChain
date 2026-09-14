# HoneyChain — Blockchain Architecture, Missing Roles & Implementation Roadmap

---

## 1. Executive Summary: What Caused the Blockchain Failure?

During integration testing of HoneyChain, **Batch Creation** by the beekeeper succeeded on Polygon Amoy, but **Lab Verification** failed with `502 Bad Gateway / Transaction Reverted`.

### The Root Cause: Missing `LAB_ROLE` On-Chain
The smart contract [`HoneyChain.sol`](file:///C:/Users/ANANT/OneDrive/Desktop/HoneyChain/blockchain/contracts/HoneyChain.sol) inherits OpenZeppelin's `AccessControl` and defines strict role-based access control (RBAC):

```solidity
bytes32 public constant BEEKEEPER_ROLE = keccak256("BEEKEEPER_ROLE");
bytes32 public constant LAB_ROLE       = keccak256("LAB_ROLE");

function createBatch(...) external onlyRole(BEEKEEPER_ROLE) whenNotPaused { ... }
function verifyLab(...)   external onlyRole(LAB_ROLE)       whenNotPaused { ... }
```

1. **Deployer Constructor:** When the contract was deployed to Polygon Amoy (`0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB`), only `DEFAULT_ADMIN_ROLE` was assigned to `msg.sender` (the deployer wallet).
2. **Partial Role Grant:** The backend developer created and ran `backend/_legacy/grant_role.py`, which **only granted `BEEKEEPER_ROLE`** to the server's private key / relayer wallet address:
   ```python
   BEEKEEPER_ROLE = w3.keccak(text="BEEKEEPER_ROLE")
   contract.functions.grantRole(BEEKEEPER_ROLE, account.address)
   ```
3. **The Failure Point:** When the FastAPI backend (`/lab-verification`) attempted to sign and broadcast `contract.functions.verifyLab(...)` using that server relayer account, the Polygon EVM threw an `AccessControlUnauthorizedAccount` revert error:
   ```text
   AccessControlUnauthorizedAccount(account: 0x..., neededRole: 0xbd3070c6... [LAB_ROLE])
   ```
   Because the wallet executing the transaction does **not** possess `LAB_ROLE`, the transaction was rejected by the smart contract on-chain.

---

## 2. Immediate Fix: Granting `LAB_ROLE` to the Relayer

To unblock the lab verification feature on Polygon Amoy, the contract admin wallet must execute a transaction granting `LAB_ROLE` to the relayer wallet address.

### The Fix Script (`backend/grant_lab_role.py`):
```python
import os
import json
from web3 import Web3
from dotenv import load_dotenv
from eth_account import Account

load_dotenv()

RPC_URL = os.getenv("AMOY_RPC_URL", "https://rpc-amoy.polygon.technology")
PRIVATE_KEY = os.getenv("PRIVATE_KEY")  # Must be DEFAULT_ADMIN_ROLE holder
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS", "0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB")

w3 = Web3(Web3.HTTPProvider(RPC_URL))
admin_account = Account.from_key(PRIVATE_KEY)

# Load ABI from compiled contract
abi_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../blockchain/ignition/deployments/chain-80002/artifacts/HoneyChainModule#HoneyChain.json"))
with open(abi_path, "r") as f:
    contract_abi = json.load(f)["abi"]

contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=contract_abi)

LAB_ROLE = w3.keccak(text="LAB_ROLE")
relayer_address = admin_account.address  # Or specific Lab wallet address

print(f"Checking if {relayer_address} has LAB_ROLE...")
has_role = contract.functions.hasRole(LAB_ROLE, relayer_address).call()

if has_role:
    print("Wallet already possesses LAB_ROLE!")
else:
    print(f"Granting LAB_ROLE to {relayer_address} as Admin...")
    tx = contract.functions.grantRole(LAB_ROLE, relayer_address).build_transaction({
        'from': admin_account.address,
        'nonce': w3.eth.get_transaction_count(admin_account.address),
        'gas': 120000,
        'gasPrice': w3.eth.gas_price
    })
    signed_tx = w3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    print("Transaction submitted! Hash:", tx_hash.hex())
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print("Confirmed in block:", receipt.blockNumber)
    print("LAB_ROLE successfully granted on Polygon Amoy!")
```

---

## 3. What Needs to Be Implemented in the Blockchain Component

To make HoneyChain a complete, verifiable, judge-ready blockchain system, the following tasks must be completed by the blockchain / backend developer:

### Task 1: Complete Supply-Chain Role Distribution
The smart contract defines 5 distinct ecosystem roles:
- `BEEKEEPER_ROLE` (keccak256("BEEKEEPER_ROLE"))
- `LAB_ROLE` (keccak256("LAB_ROLE"))
- `PROCESSOR_ROLE` (keccak256("PROCESSOR_ROLE"))
- `DISTRIBUTOR_ROLE` (keccak256("DISTRIBUTOR_ROLE"))
- `RETAILER_ROLE` (keccak256("RETAILER_ROLE"))

**What needs to be implemented:**
- Create an automated role provisioning endpoint or setup script that grants these roles to actor wallets or to the server custodial relayer on deployment.

---

### Task 2: Supply-Chain Custody Transfer Endpoints
The contract defines:
```solidity
function transferCustody(bytes32 _batchIdHash, address _to, uint8 _nextStatus) external whenNotPaused
```
**What needs to be implemented in backend:**
- Add `POST /batches/{id}/transfer-custody` in the FastAPI backend:
  - Takes `recipient_address` and `next_status` (Processed, Packaged, InDistribution, AtRetail, Sold).
  - Verifies that `msg.sender` is the current custodian.
  - Broadcasts the `transferCustody` transaction to Polygon Amoy.

---

### Task 3: Lab Report Cryptographic Hashing & IPFS Pinning
Currently, `verifyLab()` takes:
```solidity
verifyLab(bytes32 _batchIdHash, bytes32 _labReportHash, string memory _metadataCID, bytes32 _metadataHash)
```
**What needs to be implemented:**
1. When a lab technician uploads a Certificate of Analysis (CoA PDF or JSON):
   - Compute `labReportHash = sha256(fileBytes)` (or `keccak256`).
   - Pin the certificate to IPFS via Pinata to obtain `certificateCID`.
2. Commit `_labReportHash` and `_metadataCID` to the blockchain.
3. This guarantees zero tampering: if anyone modifies even a single number on the lab test report, the hash mismatch is immediately detectable on-chain.

---

### Task 4: Public Verifier Direct RPC Query (Consumer Trust)
Currently, consumers query the centralized PostgreSQL backend. For a true decentralized demonstration to judges:
- Implement a direct RPC read call in the app / backend:
  ```typescript
  const batch = await honeyChainContract.getBatch(batchIdHash);
  ```
- Compare the database values with the on-chain `batches(bytes32)` mapping to prove:
  - `status == 3 (LabVerified)`
  - `labVerified == true`
  - `recalled == false`
  - `beekeeper == <registered_address>`

---

### Task 5: Batch Recall Mechanism
The contract contains:
```solidity
function recallBatch(bytes32 _batchIdHash, string memory _reasonCID) external onlyRole(DEFAULT_ADMIN_ROLE)
```
**What needs to be implemented:**
- An administrative endpoint `POST /admin/recall-batch` allowing KVIC Quality Admins to instantly flag adulterated or contaminated batches. Once flagged, `transferCustody` and `verifyLab` are permanently locked for that batch.

---

## 4. Polygon Amoy Network Deployment Details

| Parameter | Value |
| :--- | :--- |
| **Network** | Polygon Amoy Testnet |
| **Chain ID** | `80002` |
| **RPC URL** | `https://rpc-amoy.polygon.technology` |
| **Contract Address** | `0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB` |
| **Block Explorer** | [amoy.polygonscan.com/address/0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB](https://amoy.polygonscan.com/address/0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB) |
| **Solidity Version** | `^0.8.28` (OpenZeppelin AccessControl, Pausable) |
