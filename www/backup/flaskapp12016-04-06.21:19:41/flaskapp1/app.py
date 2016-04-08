from flask import Flask
my_app = Flask(__name__)

@my_app.route("/")
def hello():
    return "Hello World!test"

if __name__ == "__main__":
    my_app.run(host='0.0.0.0', port=8000)