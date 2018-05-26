This is example code for [this post](http://www.themetabytes.com/2018/05/26/python-inter-process-communication/)

to compile: `python setup.py build_ext --inplace`

This will create a `shm.so` which you can import and experiment with.

**NOTE:** This is a native module that uses POSIX calls that will probably not work with windows.
