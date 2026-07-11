import sys
import json
import urllib.request

def main():
    if len(sys.argv) < 2:
        print("Usage: python brain.py <user_message>")
        return

    user_message = sys.argv[1]
    url = "https://text.pollinations.ai/openai/chat/completions"
    
    headers = {
        "Content-Type": "application/json"
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
            print(reply)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
