from urllib.parse import urlparse
import re
import tldextract


def extract_features(url):

    parsed = urlparse(url)

    domain = parsed.netloc

    ext = tldextract.extract(url)

    features = {
        "URLLength": len(url),

        "DomainLength": len(domain),

        "IsDomainIP":
            1 if re.search(
                r"(\d{1,3}\.){3}\d{1,3}",
                domain
            ) else 0,

        "TLDLength":
            len(ext.suffix),

        "NoOfSubDomain":
            len(ext.subdomain.split("."))
            if ext.subdomain else 0,

        "HasObfuscation":
            1 if "%" in url else 0,

        "NoOfLettersInURL":
            sum(c.isalpha() for c in url),

        "NoOfDegitsInURL":
            sum(c.isdigit() for c in url),

        "NoOfEqualsInURL":
            url.count("="),

        "NoOfQMarkInURL":
            url.count("?"),

        "NoOfAmpersandInURL":
            url.count("&"),

        "NoOfOtherSpecialCharsInURL":
            len(re.findall(r'[@#$%^*()+]', url)),

        "IsHTTPS":
            1 if parsed.scheme == "https" else 0
    }

    return list(features.values())