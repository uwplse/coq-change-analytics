#!/usr/bin/env bash

from sexpdata import loads, dump, Symbol
from flask import Flask, request

logpath = "log.txt"

app = Flask(__name__)

@app.route("/coq-analytics/", methods=["POST"])
def log_command():
    try:
        all_sexps = loads(request.form["msg"])
        with open(logpath, 'a') as logfile:
            for sexp in all_sexps:
                dump([[Symbol("user"), str(request.remote_addr)]] + sexp, logfile)
                logfile.write("\n")
    except:
        print("Got bad plugin message: {}".format(request.form["msg"]))
        print("Ignoring...")
        return "Failed"
    return 'Submitted'
