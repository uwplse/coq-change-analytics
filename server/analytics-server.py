#!/usr/bin/env python

from sexpdata import load, loads, dump, dumps, Symbol
from flask import Flask, request
import random
from datetime import datetime

logpath = "log.txt"
userpath = "users.txt"
questionpath = "questions.txt"
version_id = "2"

app = Flask(__name__)

# Log a command
@app.route("/coq-analytics/", methods=["POST"])
def log_command():
    try:
        all_sexps = loads(request.form["msg"])
        with open(logpath, 'a') as logfile:
            for sexp in all_sexps:
                dump([[Symbol("user"), str(request.form["id"])]] + sexp, logfile)
                logfile.write("\n")
    except:
        print("Got bad plugin message: {}".format(request.form["msg"]))
        print("Ignoring...")
        return "Failed"
    return 'Submitted'

# Register a new user
@app.route("/register/", methods=["POST"])
def register():
    try:
        users = open(userpath, 'r')
        profiles = load(users)
        new_uid = str(len(profiles))
        users.close()
    except:
        profiles = []
        new_uid = "0"
    finally:
        users = open(userpath, 'w')
        dump(profiles + [[[Symbol("user"), new_uid]] + [[Symbol("version"), "0"]]], users)
        users.write("\n")
        users.close()
        return str(new_uid)

@app.route("/sync-profile/", methods=["GET"])
def sync_profile():
    uid = int(request.args.get('id'))
    users = open(userpath, 'r')
    profile = load(users)[uid]
    users.close()
    version = profile[1][1]
    if version == version_id:
        return dumps([])
    else:
        question_store = open(questionpath, 'r')
        questions = dumps(load(question_store))
        return questions

# TODO explain
# TODO obviously some consistency bugs are possible, but eh. obviously not the best way, but it's a way
# TODO refactor common code
@app.route("/update-profile/", methods=["POST"])
def update_profile():
    uid = request.form["id"]
    answers = loads(request.form["answers"]) # list of 0-indexed offsets of answers for each question
    users = open(userpath, 'r')
    profiles = load(users)
    users.close()
    users = open(userpath, 'w')
    new_profile = [[Symbol("user"), uid]] + [[Symbol("version"), version_id]] + [[Symbol("answers"), answers]]
    profiles[int(uid)] = new_profile
    dump(profiles, users) 
    return "Updated"

