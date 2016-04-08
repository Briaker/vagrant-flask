# -*- coding: utf-8 -*-
__version__ = '0.1'
from flask import Flask
# from flask_debugtoolbar import DebugToolbarExtension
app = Flask(__name__)
app.config.from_object('config')
# app.config['SECRET_KEY'] = 'random'
app.debug = True
# toolbar = DebugToolbarExtension(app)
from app.views import *