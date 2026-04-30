"""
Shoonya-specific mapping utilities for the WebSocket adapter
"""

class ShoonyaExchangeMapper:
    """Maps between Tradeboard exchange names and Shoonya exchange codes"""

    # Tradeboard to Shoonya exchange mapping
    EXCHANGE_MAP = {
        "NSE": "NSE",
        "BSE": "BSE",
        "NFO": "NFO",
        "BFO": "BFO",
        "MCX": "MCX",
        "CDS": "CDS",
        "NSE_INDEX": "NSE",  # Indices use base exchange
        "BSE_INDEX": "BSE",
    }

    # SM-R6-1 fix: Explicit reverse mapping to avoid lossy dict comprehension
    # (NSE_INDEX and BSE_INDEX both map to NSE/BSE in forward map, making
    # the auto-generated reverse map overwrite NSE→NSE with NSE→NSE_INDEX)
    SHOONYA_TO_Tradeboard = {
        "NSE": "NSE",
        "BSE": "BSE",
        "NFO": "NFO",
        "BFO": "BFO",
        "MCX": "MCX",
        "CDS": "CDS",
    }

    @classmethod
    def to_shoonya_exchange(cls, oa_exchange: str) -> str | None:
        """Convert Tradeboard exchange to Shoonya exchange format"""
        return cls.EXCHANGE_MAP.get(oa_exchange.upper())

    @classmethod
    def to_oa_exchange(cls, shoonya_exchange: str) -> str | None:
        """Convert Shoonya exchange to Tradeboard exchange format"""
        return cls.SHOONYA_TO_Tradeboard.get(shoonya_exchange.upper())
