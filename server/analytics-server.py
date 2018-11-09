#!/usr/bin/env bash

from sexpdata import loads, dump, Symbol
from flask import Flask, request

logpath = "log.txt"

app = Flask(__name__)

@app.route("/coq-analytics/", methods=["POST"])
def log_command():
    try:
        sexp = [[Symbol("user"), str(request.remote_addr)]] + loads(request.form["msg"])
    except:
        print("Got bad plugin message: {}".format(request.form["msg"]))
        print("Ignoring...")
        return "Failed"
    with open(logpath, 'a') as logfile:
        dump(sexp, logfile)
        logfile.write("\n")
    return 'Submitted'
