#!/usr/bin/env bash

logpath = "log.txt"

from flask import Flask, request
app = Flask(__name__)

@app.route("/coq-analytics/", methods=["POST"])
def log_command():
    with open(logpath, 'a') as logfile:
        print(request.form["msg"])
        logfile.write("{}\n".format(request.form["msg"]))
    return 'Submitted'
