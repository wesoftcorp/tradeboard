"""
Mapping utilities for Dhan broker integration.
Provides exchange code mappings between Tradeboard and Dhan formats.
"""

from typing import Dict

# Exchange code mappings
# Tradeboard exchange code -> Dhan exchange code
TRADEBOARD_TO_DHAN_EXCHANGE = {
    "NSE": "NSE_EQ",
    "BSE": "BSE_EQ",
    "NFO": "NSE_FNO",
    "BFO": "BSE_FNO",
    "CDS": "NSE_CURRENCY",
    "BCD": "BSE_CURRENCY",
    "MCX": "MCX_COMM",
    "NSE_INDEX": "IDX_I",
    "BSE_INDEX": "IDX_I",
}

# Dhan exchange code -> Tradeboard exchange code
DHAN_TO_TRADEBOARD_EXCHANGE = {v: k for k, v in TRADEBOARD_TO_DHAN_EXCHANGE.items()}


def get_dhan_exchange(tradeboard_exchange: str) -> str:
    """
    Convert Tradeboard exchange code to Dhan exchange code.

    Args:
        tradeboard_exchange (str): Exchange code in Tradeboard format

    Returns:
        str: Exchange code in Dhan format
    """
    return TRADEBOARD_TO_DHAN_EXCHANGE.get(tradeboard_exchange, tradeboard_exchange)


def get_tradeboard_exchange(dhan_exchange: str) -> str:
    """
    Convert Dhan exchange code to Tradeboard exchange code.

    Args:
        dhan_exchange (str): Exchange code in Dhan format

    Returns:
        str: Exchange code in Tradeboard format
    """
    return DHAN_TO_TRADEBOARD_EXCHANGE.get(dhan_exchange, dhan_exchange)
