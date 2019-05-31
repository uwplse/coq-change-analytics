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

To build the plugin initially, run:

```
./build.sh
./make
```

This will walk you through the entire process, including pulling the appropriate dependencies and
making sure you have a version of Coq that is compatible with the plugin.

In the future, if you would like to skip rebuilding Coq, and would like to rebuild only the plugin, just run:

```
./make
```

# Using Analytics

Simply add this line:

```
Require Import Analytical.Analytics.
```
to the beginning of your [coqrc](https://coq.inria.fr/refman/practical-tools/coq-commands.html#by-resource-file) resource file 
(creating one if it does not exist), then go on with your proof development as you normally would.

# Debugging Analytics

To print analytics data locally instead of sending it to a server,
set the Debug Analytics option:

```
Set Debug Analytics.
```
