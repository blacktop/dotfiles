# Ubuntu Setup Notes

## To export and load Terminal Settings
To Export
```bash
$ gconftool-2 --dump '/apps/gnome-terminal' > gnome-terminal-conf.xml
```
To Load
```bash
gconftool-2 --load gnome-terminal-conf.xml
```
