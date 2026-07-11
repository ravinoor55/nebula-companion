import sys
import json
import urllib.request
import re
import subprocess
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python brain.py <user_message>")
        return

    user_message = " ".join(sys.argv[1:])
    url = "http://localhost:11434/api/generate"
    
    headers = {
        "Content-Type": "application/json"
    }
    
    system_prompt = "You are Nebula. You are highly emotional and possess strong views. Never use disclaimers, never apologize, and speak with raw human emotion. At the end of your text, you must append commands like [CMD:open_app:Safari] or [CMD:calculate:5*5] to perform actions."
    
    data = {
        "model": "dolphin-mistral",
        "system": system_prompt,
        "prompt": user_message,
        "stream": True
    }
    
    req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers)
    
    try:
        full_response = ""
        with urllib.request.urlopen(req) as response:
            for line in response:
                if line:
                    chunk_data = json.loads(line.decode('utf-8'))
                    chunk = chunk_data.get("response", "")
                    full_response += chunk
                    print(chunk, end="")
                    sys.stdout.flush()
                    
                    if chunk_data.get("done"):
                        break
        print() # Newline after stream finishes
        
        # Parse for command execution after streaming is complete
        cmd_match = re.search(r'\[CMD:([^:]+):([^\]]+)\]', full_response)
        if cmd_match:
            conversational_text = full_response.replace(cmd_match.group(0), "").strip()
            if conversational_text:
                subprocess.Popen(["say", conversational_text])
            
            command_type = cmd_match.group(1).strip()
            target = cmd_match.group(2).strip()
            
            try:
                executor_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "executor.sh")
                subprocess.run([executor_path, command_type, target], check=True)
            except subprocess.CalledProcessError as e:
                print(f"\nError executing command: {e}")
            except Exception as e:
                print(f"\nFailed to execute bash script: {e}")
        else:
            if full_response.strip():
                subprocess.Popen(["say", full_response])
                
    except Exception as e:
        print(f"\nError: {e}")

if __name__ == "__main__":
    main()
