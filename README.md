REPLICA is a Coq plugin that collects data on the changes proof engineers make
as they make them. The goal of this project is to classify and analyze this data,
then use it to inform several proof engineering tools, including a proof patching tool
and a machine learning tool.

***UPDATE, December 2019***: We have published the paper about this study in CPP 2020.
The paper is [here](http://tlringer.github.io/pdf/analytics.pdf), and the data is 
[here](https://github.com/uwplse/analytics-data).
Thanks for your participation! If you see any mistakes in how your data was classified,
feel free to reach out to us and we can post an errata.

***UPDATE, September 2019***: The REPLICA study has ended.
If you install REPLICA, it will not send data to the server because the server is no longer receiving data.
Instead, it will log locally.
Feel free to tweak the locally logged data so that it is easier to process, or feel free to
hook up REPLICA to a server of your choice instead.
Doing this requires a few lines of modification to the source for now, but we have done it in another
setting already, so please cut an issue if you would like our help.
And feel free to submit a PR making it easier to reuse the infrastructure, in the meantime!

# Philosophy

Proof engineers commit only large changes to Github, and rarely commit
broken proofs. As a result, data from Github reveals little about the proof development process.
Tools that aim to improve the development process for proof engineers ought to have insight
into how that development process currently works. This plugin will provide those tools with that information.

# Dependencies

You will need [Opam](https://opam.ocaml.org/). The build script will take
care of the remaining dependencies.

# Building REPLICA

To build the plugin initially, run:

```
./build.sh
./make
```

This will walk you through the entire process, including pulling the appropriate dependencies and
making sure you have a version of Coq that is compatible with the plugin.

This build script will ask you if you would like to install Coq locally. If you choose to install Coq locally,
please make sure that you also use this verison of Coq for your normal development. 

In the future, if you would like to skip rebuilding Coq, and would like to rebuild only the plugin, just run:

```
./make
```

# Using REPLICA

Simply add this line:

```
Require Import Analytical.Analytics.
```
to the beginning of your [coqrc](https://coq.inria.fr/refman/practical-tools/coq-commands.html#by-resource-file) resource file 
(creating one if it does not exist).

By default, `coq_makefile` disables the flag that loads your coqrc resource file during compilation passes.
Thus, inside of the projects you develop during your time using the plugin, if you use `coq_makefile`,
please overwrite `COQFLAGS` in your `[MakefileName].conf` file so that it does not include the `-q` option.

Then go on with your proof development as you normally would.

# Reanswering Profile Questions

When you first install the plugin, it will ask you a number of questions about your Coq usage. If at any point
you would like to reset your answers to these questions, run:

```
./reset-profile.sh
./make
```

You will then be prompted to reanswer the questions.

# Debugging REPLICA

To print analytics data locally instead of sending it to a server,
set the Debug Analytics option:

```
Set Debug Analytics.
```

# Reporting Bugs

Please report any bugs that you find to Github. If you need to temporarily disable the plugin due to a severe bug,
you can comment out the line in your coqrc; if you do so, please let us know so we prioritize fixing the bug.

# Removing the Plugin

When you are done with the study, please remove the line you added to your [coqrc](https://coq.inria.fr/refman/practical-tools/coq-commands.html#by-resource-file) resource file.
