#!/usr/bin/env python3

from sexpdata import loads, dump, Symbol
import functools
from datetime import datetime
from tqdm import tqdm
import argparse
import os
import os.path

from common import *

def try_loads(sexp):
    try:
        entry = loads(sexp)
        assert get_user(entry) != None
        return entry
    except:
        return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("infile")
    parser.add_argument("outdir")
    parser.add_argument("--append", '-a', action='store_true')
    args = parser.parse_args()

    if not os.path.exists(args.outdir):
        os.makedirs(args.outdir)
    seen_users = set()
    with open(args.infile, 'r') as logfile:
        for line in tqdm(logfile):
            entry = try_loads(line)
            user = get_user(entry)
            if user in seen_users or args.append:
                with open(os.path.join(args.outdir, str(user)), 'a') as f:
                    f.write(line)
            else:
                with open(os.path.join(args.outdir, str(user)), 'w') as f:
                    f.write(line)
                seen_users.add(user)

if __name__ == "__main__":
    main()
