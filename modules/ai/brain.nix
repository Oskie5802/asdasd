{ config, pkgs, lib, ... }:

let
  modelUrl = "https://huggingface.co/mradermacher/granite-3.1-2b-instruct-GGUF/resolve/main/granite-3.1-2b-instruct.Q6_K.gguf";
  modelName = "granite-3.1-2b-instruct.Q6_K.gguf";

  brainPython = pkgs.python3.withPackages (ps: with ps; [
    lancedb
    sentence-transformers
    numpy
    pandas
    flask
    gunicorn
    llama-cpp-python
  ]);

  brainServer = pkgs.writeScriptBin "ai-brain-server" ''
    #!${brainPython}/bin/python
    import logging
    import sys
    import os
    import threading
    import time
    from flask import Flask, request, jsonify
    from llama_cpp import Llama
    import lancedb
    from sentence_transformers import SentenceTransformer

    HOME = os.path.expanduser("~")
    LOG_FILE = os.path.join(HOME, ".local/share/ai-brain.log")
    
    logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format='%(asctime)s %(levelname)s: %(message)s')
    logging.getLogger("werkzeug").setLevel(logging.ERROR)

    app = Flask(__name__)

    llm = None
    embed_model = None
    db_conn = None

    MODEL_PATH = os.path.join(HOME, ".local/share/ai-models", "${modelName}")
    DB_PATH = os.path.join(HOME, ".local/share/ai-memory-db")

    def init_brain():
        global llm, embed_model, db_conn
        if os.path.exists(MODEL_PATH):
            try:
                llm = Llama(model_path=MODEL_PATH, n_ctx=2048, n_threads=6, n_batch=512, verbose=False)
            except Exception as e: logging.error(f"LLM Error: {e}")
        
        try: embed_model = SentenceTransformer('all-MiniLM-L6-v2')
        except: pass

        if os.path.exists(DB_PATH):
            try: db_conn = lancedb.connect(DB_PATH)
            except: pass

    threading.Thread(target=init_brain).start()

    @app.route('/ask', methods=['POST'])
    def ask():
        try: req = request.get_json(force=True)
        except: return jsonify({"answer": "Error: Bad JSON"}), 400
        
        query = req.get('query', ' '.strip())
        context_text = ""
        sources = []
        
        if db_conn and embed_model:
            try:
                tbl = db_conn.open_table("files")
                res = tbl.search(embed_model.encode(query)).limit(1).to_pandas()
                if not res.empty:
                    row = res.iloc[0]
                    sources.append(row['filename'])
                    context_text = f"Src:{row['filename']} Txt:{row['text'][:300]}"
            except: pass
        
        if llm:
            prompt = f"<s>[INST] <<SYS>>\nAnswer concisely in 1 sentence.\n<</SYS>>\n\nContext:{context_text}\nQ:{query} [/INST]"
            try:
                output = llm(prompt, max_tokens=100, stop=["</s>"], echo=False, temperature=0.1)
                answer = output['choices'][0]['text'].strip()
            except Exception as e: answer = f"Error: {e}"
        else:
            answer = "Loading..."
        
        return jsonify({"answer": answer, "sources": sources})

    if __name__ == '__main__':
        app.run(host='127.0.0.1', port=5500, threaded=True)
  '';

in
{
  environment.systemPackages = with pkgs; [ brainServer ];
  services.ollama.enable = false;

  systemd.services.download-ai-model = {
    description = "Download AI Model GGUF";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "download-model" ''
        mkdir -p /home/omnios/.local/share/ai-models
        MODEL_FILE="/home/omnios/.local/share/ai-models/${modelName}"
        if [ ! -f "$MODEL_FILE" ]; then
          ${pkgs.curl}/bin/curl -L "${modelUrl}" -o "$MODEL_FILE"
          chown omnios:users "$MODEL_FILE"
        fi
      '';
    };
  };

  systemd.user.services.ai-brain = {
    description = "OmniOS Brain Native Server";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${brainServer}/bin/ai-brain-server";
      Restart = "always";
      RestartSec = 2;
    };
  };
}