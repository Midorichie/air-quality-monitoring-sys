# Air Quality Monitoring System

A decentralized IoT-based air quality monitoring system built on the Stacks blockchain.

## Overview

This system enables real-time monitoring of air quality parameters including:
- PM2.5 levels
- PM10 levels
- Temperature
- Humidity
- Gas levels

The smart contract system provides:
- Secure data submission from authorized IoT sensors
- Immutable storage of air quality readings
- Configurable alert thresholds
- Historical data access

## Project Structure

```
air-quality-monitoring/
├── contracts/
│   └── air-quality-monitor.clar
├── tests/
│   └── air-quality-monitor_test.ts
├── Clarinet.toml
└── README.md
```

## Smart Contract Features

1. **Data Recording**
   - Secure submission of sensor readings
   - Validation of reading values
   - Timestamped data storage

2. **Access Control**
   - Admin-only submission rights
   - Public read access to historical data

3. **Data Validation**
   - Range checking for all parameters
   - Timestamp validation
   - Sensor authentication

## Development Setup

1. Install dependencies:
```bash
npm install -g @stacks/cli
npm install -g clarinet
```

2. Initialize the project:
```bash
clarinet new air-quality-monitoring
cd air-quality-monitoring
```

3. Run tests:
```bash
clarinet test
```

## Testing

The project maintains a minimum of 50% test coverage. Run tests using:
```bash
clarinet test
```

## Security Considerations

- Admin access control for data submission
- Input validation for all sensor readings
- Range checks for environmental parameters
- Timestamp verification
- Gas optimization for storage operations

## License

MIT License
