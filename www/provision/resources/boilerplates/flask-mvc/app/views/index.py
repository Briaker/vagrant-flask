# -*- coding: utf-8 -*-
from app import app
from flask import render_template, request

@app.route('/')
def start():
    return render_template('index.html')