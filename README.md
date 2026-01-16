# Transaction Flow with Risk Interceptor

A Flutter demonstration of robust financial transaction handling focusing on system correctness and recovery.

## Core Features
- Risk Interception: Dio interceptor handles 403 challenges (SMS OTP) and automatically retries the original request.
- Idempotency: Prevents double-spending using client-side generated UUIDs.
- Self-Recovery: Detects and resolves pending transactions on app restart.
- Precision: Uses integer cents for all monetary calculations.

## Preventing Duplicate Debits
- Client-Side ID: A unique client_transaction_id (UUID) is generated at the source.
- Persist-Before-Send: The ID and amount are saved to local storage before the network call.
- Idempotent API: The server (mocked) ensures that repeated requests with the same ID return the original result instead of re-processing the debit.

## Self-Recovery Mechanism
- Startup Audit: The system scans local storage on boot for transactions in non-final states (PENDING, AWAITING_OTP, TIMEOUT).
- State Resolution: Users are prompted to either complete the verification (for OTP) or retry the request, ensuring the ledger remains consistent across crashes and network failures.

## Getting Started
1. flutter pub get
2. flutter run
- Valid OTP: 123456
- API Simulation: Mock responses include 200 (Success), 403 (OTP Required), and 504 (Timeout).
