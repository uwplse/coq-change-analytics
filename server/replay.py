#!/usr/bin/env bash

from sexpdata import loads, dump, Symbol
import functools
import datetime

logpath = "log.txt"

def assoc(key, sexp):
    if not isinstance(sexp, list):
        return None
    for entry in sexp:
        if isinstance(entry, list) and entry[0] == Symbol(key):
            return entry[1]
    return None

def get_body(entry):
    return entry[-1]

get_user = functools.partial(assoc, "user")
get_time = functools.partial(assoc, "time")
get_session = functools.partial(assoc, "session")
get_id = functools.partial(assoc, "id")

def get_cmd_type(entry):
    body = get_body(entry)
    assert body[0] == Symbol("Control")
    assert isinstance(body[1], list)
    return body[1][0]

def multipartition(items, f):
    categories = {}
    for item in items:
        key = f(item)
        if key not in categories:
            categories[key] = []
        categories[key].append(item)
    return list(categories.values())

def try_loads(sexp):
    try:
        entry = loads(sexp)
        assert get_user(entry)
        assert get_time(entry)
        assert get_session(entry)
        return entry
    except:
        return None

def main():
    with open(logpath, 'r') as logfile:
        log_entries = [try_loads(sexp) for sexp in logfile.readlines()]
        log_entries = [entry for entry in log_entries if entry]

    sessions = multipartition(log_entries, lambda entry: (get_user(entry), get_session(entry)))
    print("Select session:")
    for idx, cmds in enumerate(sessions):
        user, session = get_user(cmds[0]), get_session(cmds[0])
        print("{}: IP {}, Start time: {}".format(idx, user,
                                                 datetime.datetime.fromtimestamp(float(session))))

    session_id = -1
    while session_id == -1:
        try:
            session_id = int(input("Session #:"))
        except:
            print("Not an integer!")

    for cmd in sessions[session_id]:
        if get_cmd_type(cmd) == Symbol("StmAdd"):
            print("{}: {}".format(get_id(cmd), get_body(cmd)[1][2]))
        elif get_cmd_type(cmd) == Symbol("StmCancel"):
            print("CANCEL {}".format(get_body(cmd)[1][1][0]))
        else:
            assert get_cmd_type(cmd) == Symbol("StmObserve")

main()
