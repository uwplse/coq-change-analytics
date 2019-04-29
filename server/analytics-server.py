#!/usr/bin/env bash

from sexpdata import loads, dump, Symbol
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

def ask_reg_questions(uid):
    # TODO ask the questions and send back to the client
    return uid

@app.route("/register/", methods=["POST"])
def register():
    users = open(userpath, 'r')
    uid = str(len(users.readlines()) + 1)
    users = open(userpath, 'a')
    dump([[Symbol("user"), str(uid)]], users)
    users.write("\n")
    # TODO ask the questions and send back to the client along w/ UID
    return ask_reg_questions(uid)

@app.route("/sync-profile/", methods=["GET"])
def login():
    # TODO check profile version
    # TODO if it's the latest version, then do nothing
    # TODO otherwise, ask the registration questions; client will check both cases and act accordingly
    return "foo"

# TODO client pings this for new profiles and updated profiles after getting reg question answers
# TODO passes us UID, answers
# TODO we write the UID, version ID, and answers to the profilepath
@app.route("/update-profile/", methods=["POST"])
def update_profile():
    return "1" # TODO

@app.route("/profile-version/", methods=["GET"])
def get_profile_version():
    users = open (userpath, 'r')
    return version_id # TODO get the version from the users file
