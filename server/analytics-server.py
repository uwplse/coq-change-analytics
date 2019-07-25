#!/usr/bin/env python

from sexpdata import load, loads, dump, dumps, Symbol
from flask import Flask, request
import random
from datetime import datetime
from common import *
import os
import os.path

logpath = "log.txt"
logdir = "logs"
userpath = "users.txt"
questionpath = "questions.txt"
version_id = "2"

app = Flask(__name__)

# Log a command
@app.route("/coq-analytics/", methods=["POST"])
def log_command():
    try:
        all_sexps = loads(request.form["msg"])
        for sexp in all_sexps:
            save_message(sexp)
    except:
        print("Got bad plugin message: {}".format(request.form["msg"]))
        print("Ignoring...")
        return "Failed"
    return 'Submitted'

def save_message(sexp):
    user = get_user(sexp)
    if not os.path.exists(logdir):
        os.makedirs(logdir)
    with open(os.path.join(logdir, user), 'a') as logfile:
        dump(sexp, logfile)
        logfile.write("\n")

# Register a new user
@app.route("/register/", methods=["POST"])
def register():
    try:
        with open(userpath, 'r') as f:
            users = f.read()
            profiles = loads(users)
            new_uid = str(len(profiles))
    except:
        profiles = []
        new_uid = "0"
    finally:
        with open(userpath, 'w') as f:
            f.write(dumps(profiles + [[[Symbol("user"), new_uid]] + [[Symbol("version"), "0"]]]) + "\n")
        return str(new_uid)

# Determine if a profile is up-to-date and, if not, ask the latest profile questions
@app.route("/sync-profile/", methods=["GET"])
def sync_profile():
    uid = int(request.args.get('id'))
    with open(userpath, 'r') as f:
        users = f.read()
        profile = loads(users)[uid]
    version = profile[1][1]
    if version == version_id:
        return dumps([])
    else:
        with open(questionpath, 'r') as qf:
            question_store = qf.read()
            questions = dumps(loads(question_store))
        return questions

# Reset a profile
@app.route("/reset-profile/", methods=["POST"])
def reset_profile():
    uid = request.form["id"]
    with open(userpath, 'r') as f:
        users = f.read()
        profiles = loads(users)
    with open(userpath, 'w') as f:
        new_profile = [[Symbol("user"), uid]] + [[Symbol("version"), "0"]]
        profiles[int(uid)] = new_profile
        f.write(dumps(profiles))
    return "Succesfully reset\n"

# Update a profile with answers to the profile questions
@app.route("/update-profile/", methods=["POST"])
def update_profile():
    uid = request.form["id"]
    answers = loads(request.form["answers"]) # list of 0-indexed offsets of answers for each question
    with open(userpath, 'r') as f:
        users = f.read()
        print(users)
        profiles = loads(users)
    with open(userpath, 'w') as f:
        new_profile = [[Symbol("user"), uid]] + [[Symbol("version"), version_id]] + [[Symbol("answers"), answers]]
        profiles[int(uid)] = new_profile
        f.write(dumps(profiles))
    return "Updated"
