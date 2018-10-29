This is a Coq plugin that collects data on the changes proof engineers make
as they make them. The goal of this project is to classify and analyze this data,
then use it to inform several research projects, including a proof patching tool
and a machine learning tool.

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
