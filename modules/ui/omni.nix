{ pkgs, config, lib, ... }:

let
  # --- DEPENDENCIES ---
  # We switch to 'lancedb' ecosystem but upgrade the font stack significantly.
  omniPython = pkgs.python3.withPackages (ps: with ps; [ lancedb pandas pyarrow numpy requests ]);
  
  # --- ASSETS: The "Soul" of the UI ---
  # Fraunces: A variable font with "Soft" and "Wonky" axes. Full of character.
  # JetBrains Mono: Technical, legible, code-centric.
  
  # --- THEME: "NOCTURNE" ---
  # A deep, atmospheric gradient theme. No flat colors.
  # Textures: Grainy darks, sharp coral/gold accents.
  omniTheme = pkgs.writeText "nocturne.rasi" ''
    configuration { 
        show-icons: true; 
        display-drun: "COMBINATOR"; 
        drun-display-format: "{name}"; 
        /* The fallback font */
        font: "JetBrains Mono 10"; 
    }

    * {
        /* Palette: Deep Space & Bioluminescence */
        bg-void:      #0d0e15;
        bg-deep:      #13141c;
        bg-gradient:  linear-gradient(to bottom, #1a1b26, #0d0e15);
        
        fg-primary:   #c0caf5;
        fg-muted:     #565f89;
        
        /* Accents */
        accent-gold:  #e0af68;
        accent-coral: #f7768e;
        accent-cyan:  #7dcfff;

        /* Reset */
        background-color: transparent;
        text-color:       @fg-primary;
        border:           0;
        margin:           0;
        padding:          0;
        spacing:          0;
    }

    window {
        width:            800px;
        /* Atmospheric Gradient Background */
        background-image: @bg-gradient;
        border:           1px;
        border-color:     @fg-muted;
        border-radius:    16px;
        transparency:     "real";
        padding:          40px;
    }

    mainbox {
        children: [ inputbar, listview, message ];
    }

    /* --- THE HEADS-UP DISPLAY --- */
    inputbar {
        padding:          0 0 30px 0;
        children:         [ textbox-prompt, entry ];
        orientation:      vertical;
    }

    textbox-prompt {
        expand:           false;
        str:              "OMNI :: SYSTEM READY";
        font:             "JetBrains Mono Bold 9";
        text-color:       @accent-cyan;
        margin:           0 0 10px 0;
    }

    entry {
        /* The "Human" Input - High contrast Serif */
        font:             "Fraunces 36"; 
        text-color:       #ffffff;
        placeholder:      "Initiate sequence...";
        placeholder-color: @fg-muted;
        cursor:            text;
        blink:             true;
    }

    /* --- THE DATA STREAM --- */
    listview {
        columns:          1;
        lines:            7;
        scrollbar:        false;
        spacing:          8px;
        margin:           10px 0 0 0;
    }

    element {
        orientation:      horizontal;
        children:         [ element-icon, element-text ];
        padding:          12px 16px;
        border-radius:    8px;
        background-color: transparent;
        spacing:          16px;
    }

    element normal.normal {
        text-color:       @fg-muted;
    }

    element selected.normal {
        /* The Selection: A subtle glow, not a block */
        background-color: rgba(255, 255, 255, 0.05);
        text-color:       @accent-gold;
        border:           0 0 0 2px;
        border-color:     @accent-gold;
    }

    element-icon {
        size:             32px;
        vertical-align:   0.5;
    }

    element-text {
        vertical-align:   0.5;
        font:             "Fraunces 14";
    }

    /* --- THE RESPONSE CARD --- */
    message {
        margin:           20px 0 0 0;
        padding:          20px;
        background-color: rgba(0,0,0,0.3);
        border-radius:    8px;
        border:           1px;
        border-color:     rgba(255,255,255,0.05);
    }
    
    textbox {
        font:             "JetBrains Mono 11";
        text-color:       @fg-primary;
    }
  '';

  # --- FEEDER: High-Fidelity Data ---
  # We construct rich Pango markup. 
  # Titles are Serif (Fraunces), Metadata is Monospace (JetBrains).
  feederScript = pkgs.writeScriptBin "omni-feeder" ''
    #!${omniPython}/bin/python
    import sys, os, lancedb, glob, html
    import pandas as pd
    
    HOME = os.path.expanduser("~")
    DB_PATH = os.path.join(HOME, ".local/share/ai-memory-db")
    
    def clean(t): return html.escape(str(t)) if t else ""
    
    # 1. APPLICATION SCANNER
    seen = set()
    apps = []
    paths = ["/run/current-system/sw/share/applications", os.path.join(HOME, ".nix-profile/share/applications")]
    
    for d in paths:
        if os.path.exists(d):
            for f in glob.glob(os.path.join(d, "*.desktop")):
                base = os.path.basename(f)
                n = base.replace(".desktop","").replace("-"," ").title()
                if n not in seen:
                    seen.add(n)
                    # AESTHETIC: 
                    # Main Text: Serif, White.
                    # Subtext: Monospace, Cyan/Dim.
                    label = (
                        f"<span font_family='Fraunces' weight='bold' size='large'>{clean(n)}</span>  "
                        f"<span font_family='JetBrains Mono' size='small' alpha='50%'>:: BINARY</span>"
                    )
                    apps.append((n, f"{label}\0icon\x1fsystem-run\x1fAPP:{f}"))

    apps.sort(key=lambda x: len(x[0]))
    for _, line in apps[:40]:
        print(line)

    # 2. MEMORY RECALL (Lancedb)
    try:
        if os.path.exists(DB_PATH):
            db = lancedb.connect(DB_PATH)
            # Use PyArrow to ensure speed
            df = db.open_table("files").search().limit(150).to_pandas()
            if not df.empty:
                df = df.sort_values(by='last_mod', ascending=False)
                for _, r in df.iterrows():
                    fn = clean(r['filename'])
                    path = clean(r['path'])
                    # Context snippet
                    txt = clean(r['text'][:60].replace("\n"," ")) + "..."
                    
                    icon = "text-x-generic"
                    if fn.endswith(".pdf"): icon = "application-pdf"
                    if fn.endswith(".nix"): icon = "text-x-script"
                    
                    # AESTHETIC: 
                    # File: Serif Italic (Elegant).
                    # Snippet: Monospace (Data).
                    label = (
                        f"<span font_family='Fraunces' style='italic' size='large'>{fn}</span>  "
                        f"<span font_family='JetBrains Mono' color='#565f89' size='small'>{txt}</span>"
                    )
                    print(f"{label}\0icon\x1f{icon}\x1fFILE:{path}")
    except Exception as e:
        pass
  '';

  # --- ORCHESTRATOR ---
  openOmniScript = pkgs.writeShellScriptBin "open-omni" ''
    ROFI="${pkgs.rofi}/bin/rofi"
    FEEDER="${feederScript}/bin/omni-feeder"
    THEME="${omniTheme}"
    JQ="${pkgs.jq}/bin/jq"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    
    # 1. THE SELECTION
    # We use -markup-rows to render our Pango HTML
    SELECTION=$($FEEDER | $ROFI -dmenu \
        -theme $THEME \
        -markup-rows \
        -i \
        -p "" \
        -display-columns 1 \
        -kb-accept-alt "" \
        -kb-accept-custom "Shift+Return,Control+Return")
    
    if [ -z "$SELECTION" ]; then exit 0; fi

    # 2. ROUTING
    if echo "$SELECTION" | grep -q "APP:"; then
        ${pkgs.kdePackages.kservice}/bin/kstart6 "$(echo "$SELECTION" | sed 's/.*APP://')"
    
    elif echo "$SELECTION" | grep -q "FILE:"; then
        xdg-open "$(echo "$SELECTION" | sed 's/.*FILE://')"
    
    else
        # 3. THE ORACLE (AI)
        # We don't just pop a notification; we transition to a "Thinking" state if possible,
        # but for Rofi, we'll notify and then reopen the window with the result.
        
        $NOTIFY "Omni" "Communing with the machine..." -t 1000
        
        RES="/tmp/ai_response.json"
        JSON_PAYLOAD=$($JQ -n --arg q "$SELECTION" '{query: $q}')
        
        # Call Local LLM (Simulated endpoint)
        CODE=$(curl -s -w "%{http_code}" -o "$RES" -X POST -H "Content-Type: application/json" -d "$JSON_PAYLOAD" http://127.0.0.1:5500/ask)

        if [ "$CODE" -eq 200 ]; then
            ANSWER=$($JQ -r '.answer' $RES)
            
            # Format answer for "The Card"
            # We use distinct fonts for the header vs the body
            
            echo -e "Copy Result\0icon\x1fedit-copy\nDismiss" | \
            $ROFI -dmenu \
                -theme $THEME \
                -markup-rows \
                -p "AI" \
                -mesg "<span font_family='JetBrains Mono' size='small' color='#7dcfff'>:: INTELLIGENCE LOG</span>
<span font_family='Fraunces' size='16pt' color='#c0caf5'>$ANSWER</span>" \
            | grep "Copy" && echo "$ANSWER" | xclip -selection clipboard
        else
            $NOTIFY "Omni Error" "Uplink failed." -u critical
        fi
    fi
  '';

  omniDesktopItem = pkgs.makeDesktopItem {
    name = "omni-bar";
    desktopName = "Omni";
    exec = "${openOmniScript}/bin/open-omni";
    icon = "utilities-terminal";
    categories = [ "Utility" ];
  };

in
{
  # --- SYSTEM CONFIGURATION ---
  
  environment.systemPackages = with pkgs; [ 
    rofi 
    omniDesktopItem 
    xclip 
    libnotify 
    kdePackages.kservice 
    jq 
    curl 
    papirus-icon-theme
  ];
  
  # --- TYPOGRAPHY IS KEY ---
  # We install specific, character-rich fonts to support the aesthetic.
  fonts.packages = with pkgs; [ 
    fraunces       # The "Human" serif element (Unexpected, beautiful)
    jetbrains-mono # The "Machine" element (Clean, technical)
  ];
}