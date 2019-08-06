#!/usr/bin/env python3

from sexpdata import loads, dump, Symbol
import functools
from datetime import datetime
from tqdm import tqdm
import argparse
from os import listdir
from os.path import isfile, join

from common import *

logdir = "logs"

class More:
    def __init__(self, num_lines):
        self.num_lines = num_lines
    def __ror__(self, other):
        s = str(other).split("\n")
        for i in range(0, len(s), self.num_lines):
            print(*s[i: i + self.num_lines], sep="\n")
            input("Press <Enter> for more")

def multipartition(items, f):
    categories = {}
    for item in items:
        key = f(item)
        if key not in categories:
            categories[key] = []
        categories[key].append(item)
    return list(categories.values())

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user", type=int, default=-2)
    parser.add_argument("--no-paginate", dest="paginate", action='store_false')
    parser.add_argument("--mode", choices=["raw", "human"], default="human")
    parser.add_argument("--unsorted", action='store_false', dest="sorted")
    args = parser.parse_args()

    #### User selection
    selected_user = args.user
    users = sorted([f for f in listdir(logdir) if isfile(join(logdir, f))])
    while selected_user == -2:
        print("Select user (-1 for all):")
        print(users)
        try:
            i = input("User #: ")
            selected_user = int(i)
            if str(selected_user) not in users and selected_user != -1:
                print(f"{selected_user} is not a valid user!")
                selected_use = -2
        except:
            selected_user = -2

    #### Session selection
    sessions = set()
    if selected_user == -1:
        for user in users:
            with open(join(logdir, str(user)), 'r') as logfile:
                for line in tqdm(logfile):
                    entry = try_loads(line)
                    if entry:
                        sessions.add((get_user(entry), get_session(entry)))
    else:
        with open(join(logdir, str(selected_user)), 'r') as logfile:
            for line in tqdm(logfile):
                entry = try_loads(line)
                if entry:
                    sessions.add((get_user(entry), get_session(entry)))
    session_list = sorted(list(sessions))

    more = More(num_lines=30)
    if selected_user == -1:
        lines = [f"{idx}: User {user}, Start time: {datetime.fromtimestamp(float(timestamp))}"
                   for idx, (user, timestamp) in enumerate(session_list)]
    else:
        lines = [f"{idx}: Start time: {datetime.fromtimestamp(float(timestamp))}"
                   for idx, (user, timestamp) in enumerate(session_list)]
    if args.paginate:
        print("\n".join(lines))
    else:
        "\n".join(lines) | more

    session_idx = -1
    while session_idx == -1:
        try:
            session_idx = int(input("Session #:"))
            if session_idx > len(sessions):
                print("Not a valid session!")
                session_idx = -1
        except ValueError:
            print("Not an integer!")
    selected_session = session_list[session_idx]

    #### Print

    user, timestamp = selected_session
    print(f"Selected session {datetime.fromtimestamp(float(timestamp))}")

    cmds = []
    if selected_user == -1:
        for user in users:
            with open(join(logdir, str(user)), 'r') as logfile:
                for line in tqdm(logfile):
                    entry = try_loads(line)
                    if entry and (get_user(entry), get_session(entry)) == selected_session:
                        cmds.append(entry)
    else:
        with open(join(logdir, str(selected_user)), 'r') as logfile:
            for line in tqdm(logfile):
                entry = try_loads(line)
                if entry and (get_user(entry), get_session(entry)) == selected_session:
                    cmds.append(entry)

    if args.sorted:
        sorted_cmds = sorted(cmds, key=lambda cmd: get_time(cmd))
    else:
        sorted_cmds = cmds

    if args.mode == "raw":
        for cmd in sorted_cmds:
            print(dumps(cmd))
    else:
        for cmd in sorted_cmds:
            if get_cmd_type(cmd) == Symbol("StmAdd"):
                print("{}: {}".format(get_id(cmd), get_body(cmd)[1][2]))
            elif get_cmd_type(cmd) == Symbol("StmCancel"):
                print("CANCEL {}".format(get_body(cmd)[1][1][0]))
            else:
                assert get_cmd_type(cmd) == Symbol("StmObserve")
                print("OBSERVE {}".format(get_body(cmd)[1][1]))

if __name__ == "__main__":
    main()
