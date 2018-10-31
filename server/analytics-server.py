#!/usr/bin/env bash

logpath = "log.txt"

from flask import Flask, request
app = Flask(__name__)

@app.route("/coq-analytics/", methods=["POST"])
def log_command():
    with open(logpath, 'a') as logfile:
        logfile.write("{}: {}".format(request.form["timestamp"],
                                      request.form["command"]))
    return 'Submitted'
