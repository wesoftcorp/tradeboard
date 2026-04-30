"""
Mapping utilities for Dhan broker integration.
Provides exchange code mappings between Tradeboard and Dhan formats.
"""

from typing import Dict

# Exchange code mappings
# Tradeboard exchange code -> Dhan exchange code
Tradeboard_TO_DHAN_EXCHANGE = {
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
DHAN_TO_Tradeboard_EXCHANGE = {v: k for k, v in Tradeboard_TO_DHAN_EXCHANGE.items()}


def get_dhan_exchange(Tradeboard_exchange: str) -> str:
    """
    Convert Tradeboard exchange code to Dhan exchange code.

    Args:
        Tradeboard_exchange (str): Exchange code in Tradeboard format

    Returns:
        str: Exchange code in Dhan format
    """
    return Tradeboard_TO_DHAN_EXCHANGE.get(Tradeboard_exchange, Tradeboard_exchange)


def get_Tradeboard_exchange(dhan_exchange: str) -> str:
    """
    Convert Dhan exchange code to Tradeboard exchange code.

    Args:
        dhan_exchange (str): Exchange code in Dhan format

    Returns:
        str: Exchange code in Tradeboard format
    """
    return DHAN_TO_Tradeboard_EXCHANGE.get(dhan_exchange, dhan_exchange)
