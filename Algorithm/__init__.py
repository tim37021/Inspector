from .Algorithm import *
import os, importlib
p = os.path.dirname(os.path.realpath(__file__))
fs = ['.%s'%f[:-3] for f in os.listdir(p) if f.endswith('.py') and f != '__init__.py']

for f in fs:
    importlib.import_module(f, 'Algorithm')