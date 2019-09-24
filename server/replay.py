#!/usr/bin/env python3

from sexpdata import loads, dumps, Symbol
import functools
from datetime import datetime
from tqdm import tqdm
import argparse
from os import listdir, stat
from os.path import isfile, join, exists

from common import *
from typing import List, TypeVar, Callable
from data_format import get_sessions

logdir = "logs"

class More:
    def __init__(self, num_lines):
        self.num_lines = num_lines
    def __ror__(self, other):
        s = str(other).split("\n")
        for i in range(0, len(s), self.num_lines):
            eprint(*s[i: i + self.num_lines], sep="\n")
            input("Press <Enter> for more")

def multipartition(items, f):
    categories = {}
    for item in items:
        key = f(item)
        if key not in categories:
            categories[key] = []
        categories[key].append(item)
    return list(categories.values())

def parseDate(s):
    return datetime.strptime(s, "%Y-%m-%d")

def inDateRange(args, entry):
    session_time = datetime.fromtimestamp(get_session(entry))
    return (not args.before or session_time < args.before) and \
        (not args.after or session_time > args.after)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user", type=int, default=-2)
    parser.add_argument("--paginate", dest="paginate", action='store_true')
    parser.add_argument("--mode", choices=["raw", "human"], default="human")
    parser.add_argument("--before", type=parseDate)
    parser.add_argument("--after", type=parseDate)
    args = parser.parse_args()

    #### User selection
    selected_user = args.user
    users = get_users(logdir)
    while selected_user == -2:
        eprint("Select user (-1 for all):")
        eprint(users)
        try:
            eprint("User #: ", end="")
            sys.stderr.flush()
            i = input()
            selected_user = int(i)
            if str(selected_user) not in users and selected_user != -1:
                eprint(f"{selected_user} is not a valid user!")
                selected_use = -2
        except:
            selected_user = -2

    with open("users.txt", 'r') as usersfile:
        profiles = loads(usersfile.read())

    if selected_user == -1:
        sessions = []
        for user in users:
            sessions += [(user, session) for session in get_sessions(user)]
        sessions = sorted(sessions)
    else:
        sessions = sorted([(selected_user, session) for session in
                           get_sessions(selected_user)])
    more = More(num_lines=30)
    if selected_user == -1:
        lines = [f"{idx}: User {user}, Start time: {timestamp}"
                   for idx, (user, timestamp) in enumerate(sessions)]
    else:
        lines = [f"{idx}: Start time: {timestamp}"
                   for idx, (user, timestamp) in enumerate(sessions)]
    if not args.paginate:
        eprint("\n".join(lines))
    else:
        "\n".join(lines) | more

    session_idx = -1
    while session_idx == -1:
        try:
            eprint("Session#: ", end="")
            sys.stderr.flush()
            session_idx = int(input())
            if session_idx > len(sessions):
                print("Not a valid session!")
                session_idx = -1
        except ValueError:
            print("Not an integer!")
            raise
    selected_session = sessions[session_idx]

    #### Print

    user, session_label = selected_session
    eprint(f"Selected session {session_label}")

    sorted_cmds = get_commmands(logdir, user, session_label)

    if args.mode == "raw":
        for cmd in sorted_cmds:
            print(dumps(cmd))
        return

    processed_cmds = preprocess_failures(profiles, sorted_cmds)

    for cmd in processed_cmds:
        if get_cmd_type(cmd) == Symbol("StmAdd"):
            print("(*{}:*) {}".format(get_id(cmd), get_body(cmd)[1][2]))
        elif get_cmd_type(cmd) == Symbol("StmCancel"):
            print("(*CANCEL {}*)".format(get_body(cmd)[1][1][0]))
        elif get_cmd_type(cmd) == Symbol("Failed"):
            print("(*FAILED {}*)".format(get_body(cmd)[1][1]))
        else:
            assert get_cmd_type(cmd) == Symbol("StmObserve")
            # print("OBSERVE {}".format(get_body(cmd)[1][1]))

if __name__ == "__main__":
    main()
