"""
Mapping utilities for Kotak broker integration.
Provides exchange, product, and order type mappings between Tradeboard and Kotak formats.
"""

# Exchange code mappings
Tradeboard_TO_KOTAK_EXCHANGE = {
    "NSE": "nse_cm",
    "nse": "nse_cm",
    "BSE": "bse_cm",
    "bse": "bse_cm",
    "NFO": "nse_fo",
    "nfo": "nse_fo",
    "BFO": "bse_fo",
    "bfo": "bse_fo",
    "CDS": "cde_fo",
    "cds": "cde_fo",
    "BCD": "bcs-fo",
    "bcd": "bcs-fo",
    "MCX": "mcx_fo",
    "mcx": "mcx_fo",
    "NSE_INDEX": "nse_cm",
    "BSE_INDEX": "bse_cm",
}

KOTAK_TO_Tradeboard_EXCHANGE = {v: k for k, v in Tradeboard_TO_KOTAK_EXCHANGE.items()}

# Product type mappings
Tradeboard_TO_KOTAK_PRODUCT = {
    "Normal": "NRML",
    "NRML": "NRML",
    "CNC": "CNC",
    "cnc": "CNC",
    "Cash and Carry": "CNC",
    "MIS": "MIS",
    "mis": "MIS",
    "INTRADAY": "INTRADAY",
    "intraday": "INTRADAY",
    "Cover Order": "CO",
    "co": "CO",
    "CO": "CO",
    "BO": "Bracket Order",
    "Bracket Order": "Bracket Order",
    "bo": "Bracket Order",
}

KOTAK_TO_Tradeboard_PRODUCT = {v: k for k, v in Tradeboard_TO_KOTAK_PRODUCT.items()}

# Order type mappings
Tradeboard_TO_KOTAK_ORDER_TYPE = {
    "Limit": "L",
    "L": "L",
    "l": "L",
    "MKT": "MKT",
    "mkt": "MKT",
    "Market": "MKT",
    "sl": "SL",
    "SL": "SL",
    "Stop loss limit": "SL",
    "Stop loss market": "SL-M",
    "SL-M": "SL-M",
    "sl-m": "SL-M",
    "Spread": "SP",
    "SP": "SP",
    "sp": "SP",
    "2L": "2L",
    "2l": "2L",
    "Two Leg": "2L",
    "3L": "3L",
    "3l": "3L",
    "Three leg": "3L",
}

KOTAK_TO_Tradeboard_ORDER_TYPE = {v: k for k, v in Tradeboard_TO_KOTAK_ORDER_TYPE.items()}


def get_kotak_exchange(Tradeboard_exchange: str) -> str:
    """
    Convert Tradeboard exchange code to Kotak exchange code.
    """
    return Tradeboard_TO_KOTAK_EXCHANGE.get(Tradeboard_exchange, Tradeboard_exchange)


def get_Tradeboard_exchange(kotak_exchange: str) -> str:
    """
    Convert Kotak exchange code to Tradeboard exchange code.
    """
    return KOTAK_TO_Tradeboard_EXCHANGE.get(kotak_exchange, kotak_exchange)


def get_kotak_product(Tradeboard_product: str) -> str:
    """
    Convert Tradeboard product type to Kotak product type.
    """
    return Tradeboard_TO_KOTAK_PRODUCT.get(Tradeboard_product, Tradeboard_product)


def get_Tradeboard_product(kotak_product: str) -> str:
    """
    Convert Kotak product type to Tradeboard product type.
    """
    return KOTAK_TO_Tradeboard_PRODUCT.get(kotak_product, kotak_product)


def get_kotak_order_type(Tradeboard_order_type: str) -> str:
    """
    Convert Tradeboard order type to Kotak order type.
    """
    return Tradeboard_TO_KOTAK_ORDER_TYPE.get(Tradeboard_order_type, Tradeboard_order_type)


def get_Tradeboard_order_type(kotak_order_type: str) -> str:
    """
    Convert Kotak order type to Tradeboard order type.
    """
    return KOTAK_TO_Tradeboard_ORDER_TYPE.get(kotak_order_type, kotak_order_type)
