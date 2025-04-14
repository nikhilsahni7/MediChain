# MediChain: Connecting Hospitals, Saving Lives

Hospitals sometimes run out of medicines, while others have extra—but there's no easy way to share them quickly. MediChain fixes that. It's a simple but powerful application that lets hospitals see each other's medicine supplies and request what they need in real time.

[Download Here](https://drive.google.com/drive/folders/15X4itFNZyRpd2yJrQuTXFbmyUse49CmH?usp=sharing)

## Key Features

With MediChain, hospitals can:

- **Real-time Inventory Management**: Track their medicine stock in a comprehensive dashboard.
- **AI-Powered Scanning**: Scan medicine labels with AI—no manual typing needed.
- **Geospatial Hospital Network**: See nearby hospitals on a map and check what medicines they have.
- **One-Click Requests**: Request medicines with one click and pay securely through blockchain technology.
- **Transparent Audit Trail**: All transactions are recorded on the blockchain for complete transparency.
- **User-Friendly Interface**: Designed for healthcare professionals with minimal technical training.

## Why MediChain Matters

In emergency situations, access to critical medications can mean the difference between life and death. MediChain bridges the gap between hospitals with surplus medications and those experiencing shortages, creating a more efficient healthcare ecosystem.

We made it lightweight and easy to use, especially for smaller hospitals with limited tech or budgets. No complicated setups—just a fast way to prevent shortages and potentially save lives.

## Technical Implementation

MediChain combines modern web and mobile technologies with blockchain to ensure security, transparency, and ease of use:

- **Mobile Application**: Built with Flutter for cross-platform compatibility
- **Secure Backend**: Robust API infrastructure handling inventory management and hospital networking
- **Blockchain Integration**: Smart contracts on Ethereum for secure, transparent transactions
- **AI-Powered Recognition**: Computer vision algorithms to quickly identify medications

Note: Right now, we don't handle deliveries—just the coordination. But in the future, we could add logistics partners to complete the supply chain.

## Project Structure

- `/mobile` source code for mobile app written in flutter (harsh, nikhil, amit)
- `/backend` contains code for web2 backend that we self hosted on kvm4 16GBRAM on hostinger (nikhil, tabish)
- `/web3` contains a smart contract written in solidity we deployed on sepolia testnet that offers a verifiable audit trail for orders and inventory logs (tabish)
- `landing-page` contains the project website and marketing materials (tabish, ansh)

## Future Roadmap

- Integrated logistics and delivery services
- Advanced analytics for predicting medication shortages
- Expanded network to include pharmaceutical companies
- Mobile notifications for critical shortages in your area
- Integration with hospital inventory management systems

## Get Involved

We welcome contributions from developers, healthcare professionals, and anyone passionate about improving medical resource allocation. Check out our issues page to see where you can help!
