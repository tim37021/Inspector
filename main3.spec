# -*- mode: python ; coding: utf-8 -*-


block_cipher = None


a = Analysis(['main.py'],
             pathex=['C:\\Users\\HaK\\Desktop\\External Projects\\Thermal\\Inspector'],
             binaries=[],
             datas=[
                 ('C:\\Users\\HaK\\Desktop\\External Projects\\Thermal\\Inspector\\openglrenderer.dll', '.'),
                 ('C:\\Users\\HaK\\Desktop\\External Projects\\Thermal\\Inspector\\plugins', 'plugins'),
                 ('C:\\Users\\HaK\\Desktop\\External Projects\\Thermal\\Inspector\\ui', 'ui'),
                 ('C:\\Users\\HaK\\Desktop\\External Projects\\Thermal\\Inspector', '.')
             ],
             hiddenimports=['pandas', 'numpy', 'scipy', 'scipy.signal', 'statistics', 'xlsxwriter', 'openpyxl'],
             hookspath=[],
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
          name='執行檔',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          console=True )
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=False,
               upx=True,
               upx_exclude=[],
               name='main')
