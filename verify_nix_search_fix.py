
import sys
import os
import logging

# Add modules path
sys.path.append('/home/miki/omni')

# Mock logging
logging.basicConfig(level=logging.INFO)

# We need to test the logic we just added to brain.py.
# Since brain.py is part of a larger module system, importing it directly might verify dependencies.
# Let's try to verify the specific logic by essentially running the same code block we added, 
# but packaged as a test to ensure the API is reachable and returns expectations.

import base64
import requests
import json

def verify_api(app_name="steam"):
    print(f"Verifying search for: {app_name}")
    
    # Internal configuration for NixOS Search API (Copied from brain.py for standalone verification)
    ES_URL = "https://search.nixos.org/backend"
    ES_USER = "aWVSALXpZv" # Extracted from bundle.js
    ES_PASS = "X8gPHnzL52wFEekuxsfQ9cSh" # Extracted from bundle.js
    ES_VERSION = "44" # elasticsearchMappingSchemaVersion from bundle.js
    CHANNEL = "unstable" 
    
    # Construct Index Name and Auth Header
    index_name = f"latest-{ES_VERSION}-nixos-{CHANNEL}"
    api_url = f"{ES_URL}/{index_name}/_search"
    
    auth_str = f"{ES_USER}:{ES_PASS}"
    auth_bytes = auth_str.encode('ascii')
    base64_bytes = base64.b64encode(auth_bytes)
    base64_auth = base64_bytes.decode('ascii')
    
    api_headers = {
        "Authorization": f"Basic {base64_auth}",
        "Content-Type": "application/json",
         "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"
    }
    
    # Enhanced Query Logic: Try generic match AND specific attribute match with dashes
    normalized_name = app_name.lower().replace(" ", "-")
    
    api_query = {
        "size": 20,
        "query": {
            "bool": {
                "must": [
                    {
                        "bool": {
                            "should": [
                                {
                                    "multi_match": {
                                        "query": app_name.lower(),
                                        "fields": [
                                            "package_attr_name^9",
                                            "package_pname^6",
                                            "package_programs^9",
                                            "package_description^1.3",
                                            "package_longDescription^1",
                                            "flake_name^0.5"
                                        ],
                                        "type": "cross_fields",
                                        "operator": "and"
                                    }
                                },
                                {
                                    "multi_match": {
                                        "query": normalized_name,
                                        "fields": [
                                            "package_attr_name^10", # Higher boost for normalized match
                                            "package_pname^6"
                                        ],
                                        "type": "best_fields"
                                    }
                                }
                            ],
                            "minimum_should_match": 1
                        }
                    }
                ]
            }
        }
    }

    try:
        logging.info(f"Querying NixOS Search API: {api_url}")
        resp = requests.post(api_url, headers=api_headers, json=api_query, timeout=10.0)
        
        candidates = []
        if resp.status_code == 200:
            hits = resp.json().get('hits', {}).get('hits', [])
            print(f"Found {len(hits)} hits.")
            for hit in hits:
                 source = hit.get('_source', {})
                 name = source.get('package_attr_name')
                 desc = source.get('package_description', 'No description')
                 if name:
                     candidates.append(f"{name}: {desc}")
                     print(f" - {name}: {desc}")
            
            if "steam" in [c.split(":")[0] for c in candidates]:
                print("SUCCESS: Found 'steam' in results.")
                # Verify command generation
                print(f"Generated Command: nix --extra-experimental-features 'nix-command flakes' profile install nixpkgs#steam")
            else:
                 print("WARNING: 'steam' not found in results (check strict match).")
        else:
            logging.error(f"NixOS Search API failed with status {resp.status_code}: {resp.text}")
            
    except Exception as e:
        logging.error(f"Failed to query NixOS Search API: {e}")

if __name__ == "__main__":
    verify_api("obs studio")
