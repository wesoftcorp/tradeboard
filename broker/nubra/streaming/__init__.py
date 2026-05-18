"""
Nubra WebSocket streaming module for TradeBoard.

This module provides WebSocket integration with Nubra's market data streaming API,
following the TradeBoard WebSocket proxy architecture.
"""

from .nubra_adapter import NubraWebSocketAdapter

__all__ = ["NubraWebSocketAdapter"]
