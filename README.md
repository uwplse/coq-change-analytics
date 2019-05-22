This is a Coq plugin that collects data on the changes proof engineers make
as they make them. The goal of this project is to classify and analyze this data,
then use it to inform several research projects, including a proof patching tool
and a machine learning tool.

# Philosophy

Proof engineers commit only large changes to Github, and rarely commit
broken proofs. As a result, data from Github reveals little about the proof development process.
Tools that aim to improve the development process for proof engineers ought to have insight
into how that development process currently works. This plugin will provide those tools with that information.

# Building Analytics

Install `sexplib` and `cohttp`:

```
opam install sexplib cohttp cohttp-lwt-unix
```

The first time, for now, you need to use the local clone of Coq, which is in a submodule:

```
git submodule init
git submodule update
```

and then run the build script to build the local clone of Coq:

```
./build.sh
```

After, and from then on, you can simply run:

```
`./make-local`.
```

This process will change to become simpler for later releases.

# Using Analytics

Just import the plugin:

```
Require Import Analytical.Analytics.
```

Then go on with your proof development as you normally would.

# Debugging Analytics

To print analytics data locally instead of sending it to a server,
set the Debug Analytics option:

```
Set Debug Analytics.
```
