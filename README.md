# PaperCut MF Database Migration Tool

## Summary
Tool for updating PaperCut MF databases with versions prior to v23.0.0 for migration to later versions

## Description
Originally lodged with PaperCut as ticket 1294438 on 22/03/2024 [PO-2009](https://papercut.com/support/known-issues/?id=PO-2009#mf)

When using "db-tools import-db" command line utility to import PCMF database exports from v22.1.5 and eariler to v23.0.0+ the following error occurs:
Error occured running db-tools, command: import-db.
Liquidbase changelog list not found: C\Users\%username%\AppData\Local\Temp\changelogsXXXXXXXXXXXXXXXXXXX\db.changelog-list.yaml

This error occurs simply due to db.changelog-master.yaml (v22.1.5 and eariler) being renamed to db.changelog-list.yaml in v23.0.0+
Because of this, "db-tools import-db" now looks for db.changelog-list.yaml rather than db.changelog-master.yaml, causing a file not found error.

This script simply checks the app-version-major property in db-data.xml file for versions prior to v23.
If the version is eariler than v23 it updates updates the filename of db.changelog-master.yaml to db.changelog-list.yaml
