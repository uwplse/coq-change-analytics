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

Install `cohttp`:

```
opam install cohttp-lwt-unix
```

Once you have done that, you should be able to `make` the plugin.
For now, you need to add a line to your Makefile.conf:

```
CAMLPKGS = -package cohttp -package cohttp-lwt-unix -package lwt
```

But before we release this, hopefully we'll figure out how to make this easier.

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
