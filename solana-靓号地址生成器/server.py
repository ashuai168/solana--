#!/usr/bin/env python3
"""
Web server that connects the frontend to Rust address generators
Streams real-time progress updates to the client
"""

from flask import Flask, request, Response, send_from_directory
from flask_cors import CORS
import subprocess
import json

app = Flask(__name__)
CORS(app)

@app.route('/')
def index():
    return send_from_directory('web', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory('web', path)

@app.route('/generate-both', methods=['GET', 'POST'])
def generate_both():
    """Generate both prefix and suffix addresses"""
    if request.method == 'GET':
        chain = request.args.get('chain', 'solana')
        pattern = request.args.get('pattern', 'test')
    else:
        data = request.get_json() or {}
        chain = data.get('chain', 'solana')
        pattern = data.get('pattern', 'test')
    
    print(f"Generating addresses for chain={chain}, pattern={pattern}")
    
    def generate():
        # Send initial connection message
        yield f"data: {json.dumps({'type': 'connected', 'message': 'Starting search...'})}\n\n"
        
        # Define Solana commands
        commands = [
            (['./target/release/solana-generator', pattern, '1', 'prefix'], 'prefix'),
            (['./target/release/solana-generator', pattern, '1', 'suffix'], 'suffix')
        ]
        
        found_count = 0
        
        for cmd, position_type in commands:
            print(f"运行: {' '.join(cmd)}")
            
            try:
                process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True
                )
                
                # Read line by line
                while True:
                    line = process.stdout.readline()
                    if not line:
                        break
                    
                    line = line.strip()
                    if not line:
                        continue
                    
                    try:
                        data = json.loads(line)
                        
                        # Log progress only (no sensitive data)
                        if data.get('type') == 'progress':
                            print(f"Progress: {data.get('attempts', 0)} attempts")
                        elif data.get('type') == 'found':
                            print(f"Found {position_type} address after {data.get('attempts', 0)} attempts")
                            data['position'] = position_type
                            found_count += 1
                        
                        # Send all messages except 'complete' from first run
                        if data.get('type') != 'complete' or found_count >= 2:
                            output = f"data: {json.dumps(data)}\n\n"
                            yield output
                            
                    except json.JSONDecodeError as e:
                        print(f"JSON parse error: {e}")
                
                process.wait()
                
            except Exception as e:
                print(f"Error running generator: {e}")
                yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"
        
        # Send final complete if we found both
        if found_count == 2:
            yield f"data: {json.dumps({'type': 'complete', 'message': 'Both addresses found'})}\n\n"
    
    return Response(generate(), mimetype='text/event-stream', headers={
        'Cache-Control': 'no-cache',
        'X-Accel-Buffering': 'no',
        'Connection': 'keep-alive'
    })

@app.route('/generate', methods=['GET', 'POST'])
def generate_single():
    """Generate addresses for a single position: prefix or suffix"""
    if request.method == 'GET':
        chain = request.args.get('chain', 'solana')
        pattern = request.args.get('pattern', 'test')
        position = request.args.get('position', 'prefix')
        suffix = request.args.get('suffix', '')
        count = request.args.get('count', None)
    else:
        data = request.get_json() or {}
        chain = data.get('chain', 'solana')
        pattern = data.get('pattern', 'test')
        position = data.get('position', 'prefix')
        suffix = data.get('suffix', '')
        count = data.get('count')

    # Normalize position - 保持both模式不变
    if str(position).lower() == 'both':
        position = 'both'
    elif str(position).lower() == 'suffix':
        position = 'suffix'
    else:
        position = 'prefix'

    print(f"Generating address for chain={chain}, pattern={pattern}, suffix={suffix}, position={position}")

    def generate():
        yield f"data: {json.dumps({'type': 'connected', 'message': 'Starting search...', 'position': position})}\n\n"

        # Map to binary invocation
        if position == 'both':
            # both模式：prefix pattern + suffix pattern + 'both' + optional count
            # 修复：确保suffix参数正确传递，count默认为1
            cmd = ['./target/release/solana-generator', pattern, suffix, 'both', '1']
        else:
            # 单条件
            cmd = ['./target/release/solana-generator', pattern, '1', position]
        print(f"运行: {' '.join(cmd)}")
        try:
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )

            while True:
                line = process.stdout.readline()
                if not line:
                    break

                line = line.strip()
                if not line:
                    continue

                try:
                    data = json.loads(line)

                    if data.get('type') == 'progress':
                        # pass-through progress
                        pass
                    elif data.get('type') == 'found':
                        data['position'] = position

                    yield f"data: {json.dumps(data)}\n\n"
                except json.JSONDecodeError as e:
                    print(f"JSON parse error: {e}")

            process.wait()

        except Exception as e:
            print(f"Error running generator: {e}")
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

        yield f"data: {json.dumps({'type': 'complete', 'message': 'Done', 'position': position})}\n\n"

    return Response(generate(), mimetype='text/event-stream', headers={
        'Cache-Control': 'no-cache',
        'X-Accel-Buffering': 'no',
        'Connection': 'keep-alive'
    })

@app.route('/health')
def health():
    return {'status': 'ok'}

if __name__ == '__main__':
    print("Starting server on http://localhost:8080")
    app.run(debug=True, port=8080, threaded=True)