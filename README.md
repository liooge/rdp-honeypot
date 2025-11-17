# RDP Honeypot

A complete RDP (Remote Desktop Protocol) honeypot implementation based on FreeRDP specifications, designed to capture credentials from RDP connection attempts.

## Features

- **Complete RDP Protocol Stack**: Implements full RDP protocol negotiation including X.224, MCS, and RDP layers
- **MSTSC Client Support**: Compatible with Windows Remote Desktop Connection (mstsc.exe) 
- **Credential Capture**: Logs username and password attempts from connecting clients
- **Protocol Compliant**: Based on ITU-T T.125 and MS-RDPBCGR specifications
- **Detailed Logging**: Comprehensive protocol-level debug information

## Architecture

The honeypot implements a 5-phase RDP connection sequence:

1. **X.224 Connection Negotiation** - Initial transport layer establishment
2. **MCS Connection Sequence** - Multi-Channel Service layer setup  
3. **MCS Channel Establishment** - Channel binding and user attachment
4. **RDP Session Establishment** - Security and capability negotiation
5. **Authentication Capture** - Username/password interception

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

## File Structure

```
rdp-server/
├── server/
│   └── rdp_honeypot_freerdp.py    # Main RDP protocol implementation
├── scripts/
│   └── test_run.sh                # Service management script
├── config.py                      # Configuration settings
├── requirements.txt               # Python dependencies
├── server.crt                     # SSL certificate
├── server.key                     # SSL private key
└── README.md                      # This file
```

## Protocol Implementation

The honeypot implements the RDP protocol according to:

- **ITU-T T.125**: MCS (Multipoint Communication Service) specification
- **ITU-T T.124**: GCC (Generic Conference Control) specification  
- **MS-RDPBCGR**: Microsoft RDP Basic Connectivity and Graphics Remoting specification

## Security Notes

- This is a honeypot for research and monitoring purposes
- All captured credentials are logged for security analysis
- Do not deploy in production environments without proper isolation
- Ensure compliance with applicable laws and regulations

## Troubleshooting

- Check logs: `tail -f server.log`
- Verify service status: `bash scripts/test_run.sh status`
- Test connectivity: Connect using Windows Remote Desktop to port 3101

## License

For research and educational purposes only.
