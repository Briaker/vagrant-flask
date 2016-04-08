# -*- coding: utf-8 -*-
from flask import flash


class SomeObject(object):

    def show_string(self, name):
        if name == '':
            flash("You didn't enter a name")
        else:
            flash(name + "!!!")
