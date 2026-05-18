"""
Zerodha WebSocket streaming module for TradeBoard.

This module provides WebSocket integration with Zerodha's market data streaming API,
following the TradeBoard WebSocket proxy architecture.
"""

from .zerodha_adapter import ZerodhaWebSocketAdapter

__all__ = ["ZerodhaWebSocketAdapter"]
