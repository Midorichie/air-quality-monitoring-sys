// tests/air-quality-monitor.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { Client, Provider, ProviderRegistry, Result } from '@stacks/transactions';
import { ClarityType } from '@stacks/transactions/dist/clarity/clarityTypes';

// Mock contract deployment details
const CONTRACT_NAME = 'air-quality-monitor';
const CONTRACT_ADDRESS = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';

describe('Air Quality Monitor Contract', () => {
    let client: Client;
    let provider: Provider;

    beforeEach(() => {
        provider = new Provider({
            node: 'http://localhost:20443'
        });
        client = new Client(provider);
    });

    describe('Sensor Registration', () => {
        it('should successfully register a new sensor', async () => {
            const sensorId = 1;
            const location = "Building A";

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'register-sensor',
                functionArgs: [sensorId, location],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(true);
        });

        it('should reject registration with invalid location', async () => {
            const sensorId = 1;
            const location = "";  // Invalid empty location

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'register-sensor',
                functionArgs: [sensorId, location],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(false);
            expect(result.error).toContain('ERR_INVALID_LOCATION');
        });
    });

    describe('Reading Submission', () => {
        it('should accept valid readings from registered sensor', async () => {
            const sensorId = 1;
            const pm25 = 50;
            const pm10 = 75;
            const temp = 25;
            const humidity = 60;
            const gas = 100;

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'submit-reading',
                functionArgs: [sensorId, pm25, pm10, temp, humidity, gas],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(true);
        });

        it('should reject readings from unregistered sensor', async () => {
            const sensorId = 999;  // Unregistered sensor
            const pm25 = 50;
            const pm10 = 75;
            const temp = 25;
            const humidity = 60;
            const gas = 100;

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'submit-reading',
                functionArgs: [sensorId, pm25, pm10, temp, humidity, gas],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(false);
            expect(result.error).toContain('ERR_SENSOR_NOT_REGISTERED');
        });
    });

    describe('Threshold Management', () => {
        it('should set valid thresholds', async () => {
            const parameter = "pm25";
            const warning = 50;
            const critical = 100;

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'set-threshold',
                functionArgs: [parameter, warning, critical],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(true);
        });

        it('should reject invalid parameters', async () => {
            const parameter = "invalid";
            const warning = 50;
            const critical = 100;

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'set-threshold',
                functionArgs: [parameter, warning, critical],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(false);
            expect(result.error).toContain('ERR_INVALID_PARAMETER');
        });
    });

    describe('Emergency Contact Management', () => {
        it('should update emergency contact', async () => {
            const newContact = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'update-emergency-contact',
                functionArgs: [newContact],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(true);
        });

        it('should reject invalid contacts', async () => {
            const newContact = 'invalid-address';

            const result = await client.callContract({
                contractAddress: CONTRACT_ADDRESS,
                contractName: CONTRACT_NAME,
                functionName: 'update-emergency-contact',
                functionArgs: [newContact],
                senderKey: 'your-private-key'
            });

            expect(result.success).toBe(false);
        });
    });
});
