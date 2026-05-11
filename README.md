# SNAP Jupyter Notebooks

## Overview

This is a repository containing Jupyter-notebook based workflows for land and water applications.

Currently there are five demo notebooks, illustrating simple, intermediate and more advanced workflows.
The notebooks extensively use the *esa_snappy* Python package and its integrated *SNAPISTA* framework.
As example input data, only small S3-OLCI and S2 MSI subsets are provided here, which are sufficient for
demonstration purposes. If needed, the corresponding full products can be accessed from dedicated
data resources, e.g. using the ESA Copernicus Browser [[1]](https://www.esa.int/Education/Copernicus_Browser_guide).

## Preparations

As preparatory steps, open the guide for Installation and configuration
[[2]](https://senbox.atlassian.net/wiki/spaces/SNAP/pages/3114106881/Installation+and+configuration+of+the+SNAP-Python+esa_snappy+interface+SNAP+version+12)
in a Web browser and carefully follow step-by-step the instructions in the subsections

- Selection of the Python distribution
- Installation of the *esa_snappy* Python package and configuration during SNAP installation
- Installation of the *esa_snappy* Python package and configuration from the command line
- Testing esa_snappy
- Testing SNAPISTA

## Using the notebooks

If the testing of *esa_snappy* and *SNAPISTA* was successful, you are ready for using the
Jupyter notebooks provided in this repositoty. To get started, select the Jupyter environment of your
preference. This would usually be a Web based or locally installed JupyterLab or Jupyter notebook 
environment. For installation and usage, please refer to the comprehensive Jupyter documentation
[[3]](https://docs.jupyter.org/en/latest/).

If you want to write your own notebooks using *esa_snappy* and *SNAPISTA*, the guides
on how to use the SNAP API from Python  
[[4]](https://senbox.atlassian.net/wiki/spaces/SNAP/pages/19300362/How+to+use+the+SNAP+API+from+Python)
and on how to use SNAPISTA
[[5]](https://snap-contrib.github.io/snapista/gettingstarted/) 
are useful entry points.

For any questions, comments, or if you would like to discuss own notebooks which might be worth adding them to this 
repository, feel free to contact the SNAP team and community via the STEP forum [[6]](https://forum.step.esa.int/).


## References and further reading:

[1] [The ESA Copernicus Browser](https://www.esa.int/Education/Copernicus_Browser_guide)

[2] [Installation and configuration of the SNAP-Python (esa_snappy) interface (SNAP version 12+)](https://senbox.atlassian.net/wiki/spaces/SNAP/pages/3114106881/Installation+and+configuration+of+the+SNAP-Python+esa_snappy+interface+SNAP+version+12)

[3] [Jupyter documentation](https://docs.jupyter.org/en/latest/)

[4] [How to use the SNAP API from Python](https://senbox.atlassian.net/wiki/spaces/SNAP/pages/19300362/How+to+use+the+SNAP+API+from+Python)

[5] [Getting started with SNAPISTA](https://snap-contrib.github.io/snapista/gettingstarted/)

[6] [The STEP forum](https://forum.step.esa.int/)
