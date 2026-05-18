"""
Mapping utilities for Dhan broker integration.
Provides exchange code mappings between TradeBoard and Dhan formats.
"""

from typing import Dict

# Exchange code mappings
# TradeBoard exchange code -> Dhan exchange code
TradeBoard_TO_DHAN_EXCHANGE = {
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

# Dhan exchange code -> TradeBoard exchange code
DHAN_TO_TradeBoard_EXCHANGE = {v: k for k, v in TradeBoard_TO_DHAN_EXCHANGE.items()}


def get_dhan_exchange(TradeBoard_exchange: str) -> str:
    """
    Convert TradeBoard exchange code to Dhan exchange code.

    Args:
        TradeBoard_exchange (str): Exchange code in TradeBoard format

    Returns:
        str: Exchange code in Dhan format
    """
    return TradeBoard_TO_DHAN_EXCHANGE.get(TradeBoard_exchange, TradeBoard_exchange)


def get_TradeBoard_exchange(dhan_exchange: str) -> str:
    """
    Convert Dhan exchange code to TradeBoard exchange code.

    Args:
        dhan_exchange (str): Exchange code in Dhan format

    Returns:
        str: Exchange code in TradeBoard format
    """
    return DHAN_TO_TradeBoard_EXCHANGE.get(dhan_exchange, dhan_exchange)
