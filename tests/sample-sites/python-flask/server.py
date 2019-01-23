from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return 'Python Flask site is working!'

@app.route('/json')
def json_index():
    return jsonify({
        'status': 'ok',
        'message': 'Hello, World!'
    })

@app.errorhandler(404)
def handle404(error):
    return jsonify({
        'status': 404,
        'error': str(error)
    })

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--development', help='Run in debug mode',
            action='store_true')
    parser.add_argument('-p', '--port', default=54321,
            help='Port to run on (default %(default)s)')
    args = parser.parse_args()

    if args.development:
        app.run(debug=True, port=args.port)
    else:
        import waitress
        waitress.serve(app, port=args.port)
