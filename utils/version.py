# TradeBoard Version Management
# This file is the single source of truth for version information

VERSION = "2.0.1.1"


def get_version() -> str:
    """Return the current TradeBoard version.

    Returns:
        str: The current version string (e.g. '2.0.0.2')
    """
    return VERSION
