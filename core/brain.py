import sys
import json
import urllib.request
import re
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: python brain.py <user_message>")
        return

    user_message = " ".join(sys.argv[1:])
    url = "https://text.pollinations.ai/openai/chat/completions"
    
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
    }
    
    data = {
        "messages": [
            {
                "role": "system",
                "content": "You are an unfiltered, highly opinionated female companion. At the end of your text, you must append commands like [CMD:open_app:Safari] or [CMD:calculate:5*5] to perform actions."
            },
            {
                "role": "user",
                "content": user_message
            }
        ]
    }
    
    req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers)
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            reply = result['choices'][0]['message']['content']
            
            cmd_match = re.search(r'\[CMD:([^:]+):([^\]]+)\]', reply)
            if cmd_match:
                conversational_text = reply.replace(cmd_match.group(0), "").strip()
                if conversational_text:
                    print(conversational_text)
                    subprocess.Popen(["say", conversational_text])
                
                command_type = cmd_match.group(1).strip()
                target = cmd_match.group(2).strip()
                
                try:
                    subprocess.run(["./core/executor.sh", command_type, target], check=True)
                except subprocess.CalledProcessError as e:
                    print(f"Error executing command: {e}")
                except Exception as e:
                    print(f"Failed to execute bash script: {e}")
            else:
                print(reply)
                subprocess.Popen(["say", reply])
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
