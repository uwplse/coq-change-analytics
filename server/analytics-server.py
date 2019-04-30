#!/usr/bin/env python

from sexpdata import load, loads, dump, dumps, Symbol
from flask import Flask, request
import random
from datetime import datetime

logpath = "log.txt"
userpath = "users.txt"
profilepath = "profiles.txt"
version_id = "1"

app = Flask(__name__)

# TODO fill this stuff in
# TODO sync client
# TODO test

# TODO use user ID to dump
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

@app.route("/register/", methods=["POST"])
def register():
    try:
        users = open(userpath, 'r')
        last_uid = int(load(users)[1])
        new_uid = str(last_uid + 1)
    except:
        new_uid = "0"
    finally:
        users = open(userpath, 'w')
        dump([Symbol("user"), new_uid], users)
        users.write("\n")
        return str(new_uid)

@app.route("/sync-profile/", methods=["GET"])
def sync_profile():
    uid = request.args.get('id')
    # TODO check profile version
    # TODO if profile file empty, create, and let version be zero
    # TODO if it's the latest version, then do nothing
    # TODO otherwise, ask the registration questions; client will check both cases and act accordingly
    return uid

# TODO client pings this for new profiles and updated profiles after getting reg question answers
# TODO passes us UID, answers
# TODO we write the UID, version ID, and answers to the profilepath
@app.route("/update-profile/", methods=["POST"])
def update_profile():
    return "1" # TODO

