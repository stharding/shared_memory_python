from platform import system
from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    name='Shared memory example',
    ext_modules=cythonize([
        Extension('shm', ['shm.pyx'],
                  libraries=['rt'] if system() == 'Linux' else [])
    ])
)
