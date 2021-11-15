# -*- mode: python ; coding: utf-8 -*-


block_cipher = None


a = Analysis(['main.py'],
             pathex=['C:\\Users\\HaK\\Desktop\\HcMusic\\Inspector'],
             binaries=[],
             datas=[
                ('C:\\Users\\HaK\\Desktop\\HcMusic\\Inspector\\ui', 'ui'),
                ('C:\\Users\\HaK\\Desktop\\HcMusic\\Inspector\\plugins', 'plugins'),
                ('C:\\Users\\HaK\\Desktop\\HcMusic\\Inspector\\demo', 'demo'),
                ('C:\\Users\\HaK\\Desktop\\HcMusic\\Inspector\\imports', 'imports'),
                ('C:\\Users\\HaK\\Desktop\\HcMusic\\Inspector\\pic', 'pic'),
                ('C:\\Users\\HaK\\Desktop\\HcMusic\\Inspector\\Algorithm', 'Algorithm'),
                ('C:\\Users\\HaK\\miniconda3\\Lib\\site-packages\\PySide2\\plugins', '.'),
             ],
             hiddenimports=[
                'scipy', 'scipy.signal', 'statistics', 'mido', 'rtmidi', 'mido.backends.rtmidi'
             ],
             hookspath=[],
             hooksconfig={},
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)

exe = EXE(pyz,
          a.scripts, 
          [],
          exclude_binaries=True,
          name='main',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          console=True,
          disable_windowed_traceback=False,
          target_arch=None,
          codesign_identity=None,
          entitlements_file=None )
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas, 
               strip=False,
               upx=True,
               upx_exclude=[],
               name='main')
