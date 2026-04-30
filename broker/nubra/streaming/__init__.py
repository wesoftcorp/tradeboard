"""
Nubra WebSocket streaming module for Tradeboard.

This module provides WebSocket integration with Nubra's market data streaming API,
following the Tradeboard WebSocket proxy architecture.
"""

from .nubra_adapter import NubraWebSocketAdapter

__all__ = ["NubraWebSocketAdapter"]
