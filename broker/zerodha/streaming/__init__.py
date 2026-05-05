"""
Zerodha WebSocket streaming module for Tradeboard.

This module provides WebSocket integration with Zerodha's market data streaming API,
following the Tradeboard WebSocket proxy architecture.
"""

from .zerodha_adapter import ZerodhaWebSocketAdapter

__all__ = ["ZerodhaWebSocketAdapter"]
