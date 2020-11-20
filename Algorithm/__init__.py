from .Algorithm import *
import os, importlib
p = os.path.dirname(os.path.realpath(__file__))
fs = ['.%s'%f[:-3] for f in os.listdir(p) if f.endswith('.py') and f != '__init__.py']

mods = []
for f in fs:
    mod = importlib.import_module(f, 'Algorithm')
    mods.append(mod)

def hot_reload():
    for mod in mods:
        importlib.reload(mod)

