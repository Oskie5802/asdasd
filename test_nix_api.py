
import requests
import json
import base64

# Config from bundle.js
ES_URL = "https://search.nixos.org/backend"
ES_USER = "aWVSALXpZv"
ES_PASS = "X8gPHnzL52wFEekuxsfQ9cSh"
ES_VERSION = "44" # elasticsearchMappingSchemaVersion

# Construct Auth Header
auth = base64.b64encode(f"{ES_USER}:{ES_PASS}".encode()).decode()
headers = {
    "Authorization": f"Basic {auth}",
    "Content-Type": "application/json"
}

# Queries to try
channels = ["25.11", "unstable", "25.05"]
# Possible index patterns based on "latest-" + channel + "-" + version
patterns = [
    f"latest-{{channel}}-{ES_VERSION}",
    f"latest-nixos-{{channel}}-{ES_VERSION}",
]

def test_search(channel):
    print(f"--- Testing Channel: {channel} ---")
    
    # Try pattern 1: Dots
    index_name = f"latest-{channel}-{ES_VERSION}"
    url = f"{ES_URL}/{index_name}/_search"
    print(f"Trying URL: {url}")
    try:
        resp = requests.get(url, headers=headers, json=query, timeout=5)
        print(f"GET Status: {resp.status_code}")
        if resp.status_code == 200:
            print("Success!")
            print(resp.json()['hits']['hits'][0]['_source']['package_attr_name'])
            return
    except Exception as e:
        print(e)

    # Try pattern 2: Dashes
    index_name = f"latest-{channel.replace('.', '-')}-{ES_VERSION}"
    url = f"{ES_URL}/{index_name}/_search"
    print(f"Trying URL: {url}")
    try:
        resp = requests.get(url, headers=headers, json=query, timeout=5)
        print(f"GET Status: {resp.status_code}")
        if resp.status_code == 200:
            print("Success!")
            print(resp.json()['hits']['hits'][0]['_source']['package_attr_name'])
            return
    except Exception as e:
        print(e)

    # Try Listing Aliases
    print("Trying to list aliases via _cat/aliases")
    url = f"{ES_URL}/_cat/aliases?v"
    try:
        resp = requests.get(url, headers=headers, timeout=5)
        print(f"Cat Status: {resp.status_code}")
        if resp.status_code == 200:
            print(resp.text)
    except Exception as e:
        print(e)

# Run tests
test_search("25.11")
test_search("unstable")
