#!/usr/bin/env python3
"""
RDP Honeypot Main Entry Point
Executable wrapper for Windows deployment
"""

import sys
import os
import logging
import signal

# Add the current directory to Python path for imports
if hasattr(sys, '_MEIPASS'):
    # Running as PyInstaller bundle
    sys.path.insert(0, sys._MEIPASS)
else:
    # Running as script
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    # Also add the server directory to path
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'server'))

def main():
    """Main entry point for the RDP honeypot"""
    try:
        # Import the honeypot class
        from rdp_honeypot_freerdp import RDPHoneypotFreeRDP
        
        # Default configuration
        host = '0.0.0.0'
        port = 3101  # Changed from 3389 to avoid permission issues
        
        # Parse command line arguments
        if len(sys.argv) > 1:
            if sys.argv[1] in ['-h', '--help']:
                print("RDP Honeypot - Username Logging Version")
                print("Usage: rdp_honeypot.exe [port]")
                print("Default port: 3101 (changed from 3389 to avoid permission issues)")
                print("Logs stored in: logs/")
                print("Press Ctrl+C to stop")
                return 0
            try:
                port = int(sys.argv[1])
            except ValueError:
                print(f"Invalid port: {sys.argv[1]}")
                return 1
        
        # Create honeypot instance
        honeypot = RDPHoneypotFreeRDP(host=host, port=port)
        
        # Setup signal handler for graceful shutdown
        def signal_handler(signum, frame):
            print("\nShutting down honeypot...")
            honeypot.stop()
            sys.exit(0)
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        # Start the honeypot
        print(f"Starting RDP Honeypot on {host}:{port}")
        print("Press Ctrl+C to stop")
        honeypot.start()
        
    except KeyboardInterrupt:
        print("\nShutdown requested by user")
        return 0
    except ImportError as e:
        print(f"Import error: {e}")
        print("Make sure all required modules are available")
        return 1
    except Exception as e:
        print(f"Error starting honeypot: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())