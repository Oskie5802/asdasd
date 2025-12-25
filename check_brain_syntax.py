
import sys
import os

# Add omni root to path so we can import modules
sys.path.append('/home/miki/omni')

print("Attempting to import modules.ai.brain.brain...")
try:
    import modules.ai.brain.brain
    print("Successfully imported brain.py - Syntax is OK.")
except SyntaxError as e:
    print(f"SyntaxError: {e}")
    sys.exit(1)
except Exception as e:
    # Other errors (ImportError etc) might happen due to missing deps in this environment, 
    # but we just want to ensure no SyntaxError.
    print(f"Other Error (expected if deps missing): {e}")
    # If we got past syntax parsing, that's good enough for this check.
    pass
