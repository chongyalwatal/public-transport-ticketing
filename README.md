# Public Transport Ticketing System

## Overview

A blockchain-based public transport ticketing system built on the Stacks blockchain using Clarity smart contracts. This system enables digital ticket purchase, validation, and management for public transportation networks.

## Features

### Core Functionality
- **Digital Ticket Purchase**: Users can buy transport tickets using STX tokens
- **Route Management**: Transport operators can define and manage routes with pricing
- **Ticket Validation**: Automated validation system for ticket usage
- **Balance Tracking**: Real-time tracking of user credit balances
- **Transfer System**: Secure ticket transfers between users

### Smart Contracts
1. **Transport Ticketing Contract**: Core ticketing functionality
2. **Route Manager Contract**: Route and pricing management

## System Architecture

### Transport Ticketing Contract
- Handles ticket purchases and validations
- Manages user balances and credit systems
- Tracks ticket usage and history
- Provides refund mechanisms for unused tickets

### Route Manager Contract  
- Defines transport routes and destinations
- Sets dynamic pricing based on distance and demand
- Manages route availability and schedules
- Tracks route usage statistics

## Getting Started

### Prerequisites
- Clarinet CLI tool
- Node.js and npm
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd public-transport-ticketing
npm install
```

### Testing
```bash
clarinet check
npm test
```

## Usage

### For Passengers
1. Purchase tickets by calling `buy-ticket` with route ID and payment
2. Validate tickets during travel using `use-ticket`
3. Check remaining balance with `get-user-balance`
4. Transfer unused tickets to other users

### For Transport Operators
1. Create new routes using `create-route`
2. Update pricing with `update-route-price`
3. Monitor route usage through read-only functions
4. Manage route availability

## Smart Contract Functions

### Public Functions
- `buy-ticket`: Purchase a ticket for a specific route
- `use-ticket`: Validate and use a purchased ticket
- `transfer-ticket`: Transfer ticket to another user
- `create-route`: Create a new transport route
- `update-route-price`: Update pricing for existing routes

### Read-Only Functions
- `get-user-balance`: Check user's current balance
- `get-route-info`: Get route details and pricing
- `get-ticket-count`: Get number of tickets for user
- `get-route-usage`: Get usage statistics for routes

## Security Features

- Secure balance tracking with overflow protection
- Ticket ownership verification
- Route access control for operators
- Prevention of double-spending tickets

## Testing

The system includes comprehensive tests covering:
- Ticket purchase scenarios
- Route creation and management
- Balance and credit tracking
- Error handling and edge cases

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

## Support

For issues and questions, please create an issue in this repository.
