#!/usr/bin/env python3

from sexpdata import Symbol, loads
from typing import Any, Tuple, TypeVar, Callable, List
import re
import functools

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
get_session_module = functools.partial(assoc, "session-module")
get_id = functools.partial(assoc, "id")

def isObserve(entry):
    return get_cmd_type(entry) == Symbol("StmObserve")
def isCancel(entry):
    return get_cmd_type(entry) == Symbol("StmCancel") or \
        get_cmd_type(entry) == Symbol("Failed")
def isFailed(entry):
    return get_cmd_type(entry) == Symbol("Failed")
def isAdd(entry):
    return get_cmd_type(entry) == Symbol("StmAdd")
def getAddBody(entry):
    return get_body(entry)[1][2]

def mkEntry(time : float, user : int, module : str, session : float, body : Any):
    return [[Symbol('time'), time], [Symbol('user'), user],
            [Symbol('session-module'), module],
            [Symbol('session'), session], body]

def get_cmd_type(entry):
    body = get_body(entry)
    assert body[0] == Symbol("Control")
    assert isinstance(body[1], list)
    return body[1][0]

def try_loads(sexp):
    entry = loads(sexp)
    try:
        entry = loads(sexp)
        assert get_user(entry) != None
        assert get_time(entry)
        assert get_session(entry)
        return entry
    except:
        return None

def preprocess_failures(profiles, commands : List[str]):
    return sublist_replace(
        sublist_replace(
            commands,
            [hoAnd(isCancel, functools.partial(userUsesIDE, profiles, "Proof General")),
             lambda entry: (not isCancel(entry)) and (not isUnsetSilent(entry))],
            lambda msgs: [mkEntry(get_time(msgs[0]),
                                  get_user(msgs[0]),
                                  get_session_module(msgs[0]),
                                  get_session(msgs[0]),
                                  [Symbol("Control"),
                                   [Symbol("Failed"),
                                    get_body(msgs[0])[1][1][0]]]),
                          msgs[1]]),
        [hoAnd(isCancel, functools.partial(userUsesIDE, profiles, "CoqIDE")),
         isObserve, isObserve, isObserve],
        lambda msgs: [mkEntry(get_time(msgs[0]),
                              get_user(msgs[0]),
                              get_session_module(msgs[0]),
                              get_session(msgs[0]),
                              [Symbol("Control"),
                               [Symbol("Failed"),
                                get_body(msgs[0])[1][1][0]]])])

T = TypeVar('T')
def sublist_replace(lst : List[T], sublst : List[Callable[[T], bool]],
                    replace : Callable[[List[T]], List[T]]) -> List[T]:
    for i in range(0, len(lst) - (len(sublst) - 1)):
        if all([f(item) for f, item in zip(sublst, lst[i:i+len(sublst)])]):
            return lst[:i] + replace(lst[i:i+len(sublst)]) + \
                sublist_replace(lst[i+len(sublst):], sublst, replace)
    return lst

def sublist_contained(lst : List[T], sublst : List[Callable[[T], bool]]) -> bool:
    for i in range(0, len(lst) - (len(sublst) - 1)):
        if all([f(item) for f, item in zip(sublst, lst[i:i+len(sublst)])]):
            return True

def isUnsetSilent(entry):
    return get_cmd_type(entry) == Symbol("StmAdd") and \
        get_body(entry) == [Symbol("Control"), [Symbol("StmAdd"), [], "Unset Silent. "]]
ides = ["coqtop", "coqc", "CoqIDE", "Proof General", "other"]
def userUsesIDE(profiles, ide : str, entry) -> bool:
    return ides[assoc("answers", profiles[get_user(entry)])[4]] == ide

def hoAnd(*fs):
    if len(fs) == 1:
        return fs[0]
    else:
        return lambda *args: fs[0](*args) and hoAnd(*fs[1:])(*args)

import sys
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def get_stem(tactic : str) -> str:
    return split_tactic(tactic)[0]

def split_tactic(tactic : str) -> Tuple[str, str]:
    tactic = kill_comments(tactic).strip()
    if re.match("[-+*\{\}]", tactic):
        stripped = tactic.strip()
        return stripped[:-1], stripped[-1]
    if re.match(".*;.*", tactic):
        return tactic, ""
    for prefix in ["try", "now", "repeat", "decide"]:
        prefix_match = re.match("{}\s+(.*)".format(prefix), tactic)
        if prefix_match:
            rest_stem, rest_rest = split_tactic(prefix_match.group(1))
            return prefix + " " + rest_stem, rest_rest
    for special_stem in ["rewrite <-", "rewrite !", "intros until", "simpl in"]:
        special_match = re.match("{}\s*(.*)".format(special_stem), tactic)
        if special_match:
            return special_stem, special_match.group(1)
    match = re.match("^\(?(\w+)(?:\s+(.*))?", tactic)
    assert match, "tactic \"{}\" doesn't match!".format(tactic)
    stem, rest = match.group(1, 2)
    if not rest:
        rest = ""
    return stem, rest

def kill_comments(string: str) -> str:
    result = ""
    depth = 0
    in_quote = False
    for i in range(len(string)):
        if in_quote:
            if depth == 0:
                result += string[i]
            if string[i] == '"' and string[i-1] != '\\':
                in_quote = False
        else:
            if string[i:i+2] == '(*':
                depth += 1
            if depth == 0:
                result += string[i]
            if string[i-1:i+1] == '*)' and depth > 0:
                depth -= 1
            if string[i] == '"' and string[i-1] != '\\':
               in_quote = True
    return result

def isVernacCmd(cmd : str) -> bool:
    if isGoalPunctuation(cmd):
        return False
    keyword = re.match("(#\[.*?\])?\s*(\S+)(\s+.*)?\.", cmd, re.DOTALL).group(2)
    return isVernacKeyword(keyword)

def isGoalPunctuation(cmd : str) -> bool:
    return bool(re.match("(\d+:)?\s*[-*+\{\}]", cmd.strip()))

def isVernacKeyword(cmd : str) -> bool:
    if cmd in ["Show", "Timeout", "Unset",
               "Qed", "Require", "Set", "From",
               "Definition", "Fixpoint", "Theorem",
               "Function", "Check", "Lemma", "Search",
               "Hint", "Proof", "Backtrack", "Add",
               "Inductive", "Open", "Coercion", "Instance",
               "Ltac", "Notation", "Generalizable", "Anomaly",
               "Redirect", "Import", "Defined", "Admitted",
               "Remove", "Fact"]:
        return True
    return False
