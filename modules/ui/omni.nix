{ pkgs, config, lib, ... }:

let
  omniPython = pkgs.python3.withPackages (ps: with ps; [ requests pandas numpy ]);

  # --- 1. THEME (Clean, Apple-like, Corrected UI) ---
  themeContent = ''
    * {
        bg-base:      #ffffff;
        bg-selected:  #007aff;
        fg-text:      #1d1d1f;
        fg-sel-text:  #ffffff;
        fg-subtle:    #86868b;
        border-col:   #e5e5ea;
        
        font: "Manrope Medium 13"; 
        background-color: @bg-base;
        text-color:       @fg-text;
        
        margin: 0; padding: 0; spacing: 0;
    }
    
    window { 
        width: 640px; 
        border: 1px; 
        border-color: @border-col; 
        border-radius: 16px; 
        location: center; 
        anchor: center;
        transparency: "real";
    }

    mainbox { 
        children: [ inputbar, message, listview ]; 
        spacing: 0px; 
    }

    inputbar { 
        background-color: #f5f5f7; 
        padding: 18px; 
        /* Corrected: prompt and entry are children of inputbar */
        children: [ prompt, entry ]; 
        spacing: 12px;
        border: 0px 0px 1px 0px;
        border-color: @border-col;
    }

    prompt { 
        /* The 'omni' text goes here */
        text: "omni"; 
        font: "Manrope ExtraBold 16"; 
        text-color: #007aff; 
        vertical-align: 0.5; 
        background-color: transparent; 
        padding: 0 8px 0 0; /* Add a little space after 'omni' */
    }

    entry { 
        /* Placeholder text for the search/input field */
        placeholder: "Search Apps or Shift+Enter to Ask AI..."; 
        font: "Manrope Medium 16"; 
        placeholder-color: #aeaeb2; 
        cursor: text; 
        vertical-align: 0.5; 
        background-color: transparent; 
        padding: 0; /* Ensure no extra padding */
    }

    /* THE ANSWER BOX */
    message {
        border: 0px;
        padding: 0px;
        background-color: @bg-base;
    }
    
    textbox {
        padding: 24px;
        font: "Manrope Medium 14";
        text-color: @fg-text;
        background-color: transparent;
    }

    /* RESULTS LIST */
    listview { 
        lines: 7; 
        columns: 1; 
        scrollbar: false; 
        fixed-height: false; 
        padding: 8px;
        background-color: @bg-base;
        spacing: 4px;
        border: 0px;
    }

    element { 
        padding: 10px 14px; 
        border-radius: 10px; 
        spacing: 12px; 
        background-color: transparent; 
        children: [ element-icon, element-text ];
        cursor: pointer;
    }
    
    element selected.normal { 
        background-color: #f2f2f7; 
        text-color: @fg-text;
    }

    element-text { 
        font: "Manrope SemiBold 13";
        text-color: inherit; 
        vertical-align: 0.5;
        background-color: transparent;
    }
    
    element-icon { 
        size: 28px; 
        vertical-align: 0.5; 
        background-color: transparent;
    }
  '';
  omniTheme = pkgs.writeText "aeriform.rasi" themeContent;

  # --- 2. THE LOGIC SCRIPT (With Connection Retries) ---
  omniLogic = pkgs.writeScriptBin "omni-smart-mode" ''
    #!${omniPython}/bin/python
    import sys, os, glob, json, requests, subprocess, time

    # --- CONFIG ---
    BRAIN_URL = "http://127.0.0.1:5500/ask"
    MAX_RETRIES = 5
    RETRY_DELAY = 2 # Seconds

    # Rofi environment variables
    retv = int(os.environ.get('ROFI_RETV', 0))
    info = os.environ.get('ROFI_INFO', ' '.strip())
    argument = sys.argv[1] if len(sys.argv) > 1 else ""

    def scan_apps():
        apps = []
        seen = set()
        paths = ["/run/current-system/sw/share/applications", os.path.expanduser("~/.nix-profile/share/applications")]
        
        for p in paths:
            if not os.path.exists(p): continue
            for f in glob.glob(os.path.join(p, "*.desktop")):
                name = os.path.basename(f).replace(".desktop", "").replace("-", " ").title()
                if name not in seen:
                    seen.add(name)
                    apps.append(f"{name}\0icon\x1fsystem-run\x1finfo\x1fAPP:{f}")
        return sorted(apps)

    def call_brain(query):
        for attempt in range(MAX_RETRIES):
            try:
                payload = {"query": query}
                r = requests.post(BRAIN_URL, json=payload, timeout=60)
                if r.status_code == 200:
                    return r.json().get("answer", "No answer received.")
                else:
                    # Server responded, but with an error status
                    return f"Error: Server returned {r.status_code}"
            except requests.exceptions.ConnectionError as e:
                # Connection refused or similar - server might be starting
                if attempt < MAX_RETRIES - 1:
                    time.sleep(RETRY_DELAY)
                else:
                    return f"Error: Could not connect to Brain. (Connection refused)"
            except Exception as e:
                # Other errors
                return f"Error: {str(e)}"
        return "Error: Max retries exceeded." # Should not be reached if MAX_RETRIES > 0

    def main():
        # --- CASE 1: INITIAL LOAD ---
        if retv == 0:
            print("\n".join(scan_apps()))

        # --- CASE 2: USER SELECTED AN APP (Return) ---
        elif retv == 1:
            if info.startswith("APP:"):
                app_path = info.split(":", 1)[1]
                subprocess.Popen(["kstart6", app_path])
                sys.exit(0)
            elif info.startswith("COPY:"):
                text = info.split(":", 1)[1]
                subprocess.run(["xclip", "-selection", "clipboard"], input=text.encode())
                sys.exit(0)

        # --- CASE 3: ASK AI (Shift+Return) ---
        elif retv == 2: 
            answer = call_brain(argument)
            safe_answer = answer.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            
            # Update UI: Show answer in message box
            print(f"\0message\x1f{safe_answer}")
            
            # Show "Copy" button in list
            print(f"Copy to Clipboard\0icon\x1fedit-copy\0info\x1fCOPY:{answer}")

    if __name__ == "__main__":
        main()
  '';

  # --- 3. WRAPPER ---
  openOmniScript = pkgs.writeShellScriptBin "open-omni" ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.xclip}/bin:${pkgs.kdePackages.kservice}/bin:$PATH"
    
    rofi \
        -show omni \
        -modi "omni:${omniLogic}/bin/omni-smart-mode" \
        -theme ${omniTheme} \
        -p "●" \
        -kb-accept-entry "Return" \
        -kb-cancel "Escape"
  '';

  omniDesktopItem = pkgs.makeDesktopItem {
    name = "omni-bar";
    desktopName = "Omni";
    exec = "${openOmniScript}/bin/open-omni";
    icon = "system-search";
    categories = [ "Utility" ];
  };

in
{
  environment.systemPackages = with pkgs; [ 
    rofi omniDesktopItem xclip libnotify kdePackages.kservice jq curl papirus-icon-theme
  ];
  
  fonts.packages = with pkgs; [ manrope ];
}