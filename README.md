# RDP Honeypot
A simple RDP (Remote Desktop Protocol) honeypot implementation based on FreeRDP specifications, designed to capture credentials from RDP connection attempts.


## Quick Start

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Start the Honeypot**:
   ```bash
   bash scripts/test_run.sh start
   ```

3. **Monitor Logs**:
   ```bash
   bash scripts/test_run.sh logs
   ```

4. **Stop the Service**:
   ```bash
   bash scripts/test_run.sh stop
   ```

## Configuration

- **RDP Port**: 3101 (configurable in `config.py`)
- **HTTP Health Check**: 8080 (for service monitoring)
- **SSL Certificates**: `server.crt` and `server.key` (self-signed)

