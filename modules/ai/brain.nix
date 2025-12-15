{ config, pkgs, lib, ... }:

let
  # --- CONFIGURATION ---
  modelName = "granite-3.1-2b-instruct.Q4_K_M.gguf";
  modelHash = "0yf5zbcnv2q236zjs4xbr17zkizhpcgqj0208w0jpdcmrb1y1a9d";
  modelUrl  = "https://huggingface.co/mradermacher/granite-3.1-2b-instruct-GGUF/resolve/main/granite-3.1-2b-instruct.Q4_K_M.gguf";

  # --- BAKED IN MODEL ---
  builtInModel = pkgs.fetchurl {
    url = modelUrl;
    sha256 = modelHash;
  };

  # --- PYTHON ENVIRONMENT ---
  brainPython = pkgs.python3.withPackages (ps: with ps; [
    lancedb
    sentence-transformers
    numpy
    pandas
    flask
    gunicorn
    llama-cpp-python
  ]);

  # --- SERVER SCRIPT ---
  brainServerScript = pkgs.writeScriptBin "ai-brain-server" ''
    #!${brainPython}/bin/python
    import logging, sys, os, time, threading, json
    from flask import Flask, request, jsonify
    from llama_cpp import Llama
    import lancedb
    from sentence_transformers import SentenceTransformer

    # Silence logs
    logging.getLogger('werkzeug').setLevel(logging.ERROR)
    logging.basicConfig(level=logging.INFO)
    app = Flask(__name__)

    HOME = os.path.expanduser("~")
    MODEL_PATH = os.path.join(HOME, ".local/share/ai-models", "${modelName}")
    DB_PATH = os.path.join(HOME, ".local/share/ai-memory-db")

    llm = None
    embed_model = None
    db_conn = None
    is_ready = False

    def loader_thread():
        global llm, embed_model, db_conn, is_ready
        
        # Wait for model file
        while not os.path.exists(MODEL_PATH):
            time.sleep(1)

        try:
            logging.info("Loading Granite Q4 (Background)...")
            # n_gpu_layers=0 ensures we don't crash graphical session if GPU is busy
            llm = Llama(
                model_path=MODEL_PATH, 
                n_ctx=2048, 
                n_threads=4, 
                n_batch=512, 
                n_gpu_layers=0, 
                verbose=False
            )
            logging.info("LLM Ready.")
        except Exception as e:
            logging.error(f"FATAL: {e}")
            sys.exit(1)

        try: embed_model = SentenceTransformer('all-MiniLM-L6-v2')
        except: pass
        try: 
            if os.path.exists(DB_PATH): db_conn = lancedb.connect(DB_PATH)
        except: pass
        
        is_ready = True

    @app.route('/ask', methods=['POST'])
    def ask():
        if not is_ready:
            return jsonify({"answer": "Brain is warming up (give me 10s)..."})

        try: req = request.get_json(force=True)
        except: return jsonify({"answer": "Error: Bad JSON"}), 400
        
        query = req.get('query', ' '.strip()).strip()
        
        # RAG Logic
        context_text = ""
        if db_conn and embed_model:
            try:
                tbl = db_conn.open_table("files")
                res = tbl.search(embed_model.encode(query)).limit(1).to_pandas()
                if not res.empty:
                    context_text = f"Context: {res.iloc[0]['text'][:300]}\n\n"
            except: pass
        
        # Prompt
        prompt = (
            f"<|start_of_role|>system<|end_of_role|>You are Omni, a helpful OS assistant.<|end_of_text|>\n"
            f"<|start_of_role|>user<|end_of_role|>{context_text}{query}<|end_of_text|>\n"
            f"<|start_of_role|>assistant<|end_of_role|>"
        )

        try:
            output = llm(
                prompt, max_tokens=256, stop=["<|start_of_role|>"], 
                echo=False, temperature=0.3, stream=False
            )
            answer = output['choices'][0]['text'].strip()
        except Exception as e: answer = f"Error: {e}"
        
        return jsonify({"answer": answer})

    if __name__ == '__main__':
        threading.Thread(target=loader_thread, daemon=True).start()
        app.run(host='127.0.0.1', port=5500, threaded=True)
  '';

  # --- STARTUP WRAPPER ---
  brainWrapper = pkgs.writeShellScriptBin "start-brain-safe" ''
    mkdir -p "$HOME/.local/share/ai-models"
    DEST="$HOME/.local/share/ai-models/${modelName}"
    if [ ! -L "$DEST" ]; then
        ln -sf "${builtInModel}" "$DEST"
    fi
    exec ${brainServerScript}/bin/ai-brain-server
  '';

in
{
  environment.systemPackages = with pkgs; [ brainWrapper ];
  services.ollama.enable = false;

  # --- SYSTEMD SERVICE ---
  systemd.user.services.ai-brain = {
    description = "OmniOS Brain Native Server";
    # Start after graphical session is definitely UP
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    
    serviceConfig = {
      Type = "simple";
      
      # FIX FOR BLACK SCREEN: Wait 20 seconds before starting Python
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 20";
      
      ExecStart = "${brainWrapper}/bin/start-brain-safe";
      Restart = "always";
      RestartSec = 10;
      
      # FIX FOR FREEZING: Run as lowest priority background task
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
  };
}