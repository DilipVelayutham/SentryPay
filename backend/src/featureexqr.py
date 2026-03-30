import re
import tldextract
from urllib.parse import urlparse

KEYWORDS = ["login", "verify", "reward", "claim", "refund"]

def has_ip(url):
    return re.search(r"\d+\.\d+\.\d+\.\d+", url) != None

def extract(url):
    parsed = urlparse(url)

    ext = tldextract.extract(url)
    domain = ext.domain + "." + ext.suffix

    return [
        1 if parsed.scheme == "https" else 0,
        1 if has_ip(url) else 0,
        len(url),
        sum(word in url for word in KEYWORDS),
        1 if domain not in ["google.com","amazon.in"] else 0
    ]