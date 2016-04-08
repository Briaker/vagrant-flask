from flask import Flask, render_template, request, make_response

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")
# def hello():
#     return "Hello World!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8000)