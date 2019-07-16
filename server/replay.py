#!/usr/bin/env python3

from sexpdata import loads, dump, Symbol
import functools
from datetime import datetime
from tqdm import tqdm
import argparse

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
    parser = argparse.ArgumentParser()
    parser.add_argument("--by", choices=['user', 'session'], default='session')
    parser.add_argument("--user", type=int, default=-1)
    parser.add_argument("--no-paginate", dest="paginate", action='store_false')
    args = parser.parse_args()

    #### User selection
    selected_user = args.user
    if args.by == 'user':
        users = set()
        with open(logpath, 'r') as logfile:
            for line in tqdm(logfile):
                entry = try_loads(line)
                if entry:
                    users.add(get_user(entry))
        print("Select user:")
        print(users)
        while selected_user == -1:
            try:
                selected_user = int(input("User #:"))
                if selected_user not in users:
                    print("Not a valid user!")
                    selected_user = -1
            except:
                print("Not an integer!")

    #### Session selection
    sessions = set()
    with open(logpath, 'r') as logfile:
        for line in tqdm(logfile):
            entry = try_loads(line)
            if entry and (selected_user == -1 or get_user(entry) == selected_user):
                sessions.add((get_user(entry), get_session(entry)))
    session_list = list(sessions)

    more = More(num_lines=30)
    if args.by == "session":
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

    print(f"Selected session {selected_session}")

    cmds = []
    with open(logpath, 'r') as logfile:
        for line in tqdm(logfile):
            entry = try_loads(line)
            if entry and (get_user(entry), get_session(entry)) == selected_session:
                cmds.append(entry)

    print(f"{len(cmds)} commands")
    for cmd in cmds:
        if get_cmd_type(cmd) == Symbol("StmAdd"):
            print("{}: {}".format(get_id(cmd), get_body(cmd)[1][2]))
        elif get_cmd_type(cmd) == Symbol("StmCancel"):
            print("CANCEL {}".format(get_body(cmd)[1][1][0]))
        else:
            assert get_cmd_type(cmd) == Symbol("StmObserve")


    # sessions = multipartition(log_entries, lambda entry: (get_user(entry), get_session(entry)))
    # print("Select session:")
    # for idx, cmds in enumerate(sessions):
    #     user, session = get_user(cmds[0]), get_session(cmds[0])
    #     print("{}: IP {}, Start time: {}".format(idx, user,
    #                                              datetime.datetime.fromtimestamp(float(session))))

    # session_id = -1
    # while session_id == -1:
    #     try:
    #         session_id = int(input("Session #:"))
    #     except:
    #         print("Not an integer!")

    # for cmd in sessions[session_id]:
    #     if get_cmd_type(cmd) == Symbol("StmAdd"):
    #         print("{}: {}".format(get_id(cmd), get_body(cmd)[1][2]))
    #     elif get_cmd_type(cmd) == Symbol("StmCancel"):
    #         print("CANCEL {}".format(get_body(cmd)[1][1][0]))
    #     else:
    #         assert get_cmd_type(cmd) == Symbol("StmObserve")

if __name__ == "__main__":
    main()
