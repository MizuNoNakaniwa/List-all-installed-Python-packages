[中文](./README.md) | **English**

# pyrecords — One-Click Audit of Python Download/Install Records

Scans your machine for every trace of Python downloads and installations, then compiles a timestamped report saved to your Desktop (`Python下载记录.txt`).

Python has no single "download history" file, so this tool pieces the ledger together from scattered evidence and tells you, in one pass:

- **[0]** How many Pythons are on your machine (py launcher, PATH, conda/Miniforge envs)
- **[1]** What packages each Python has installed, and when (newest first — the running tab)
- **[2]** Packages still sitting in the pip download cache (even after uninstalling, the cache keeps receipts) and how many MB it's eating
- **[3]** conda install/uninstall history (command by command, with timestamps — the closest thing to a real ledger)
- **[4]** Download time and size of every model in your model caches (HuggingFace / ModelScope / PaddleOCR / EasyOCR)

## Usage

1. Download `find_records.ps1` and `run.bat` into the same folder
2. Double-click `run.bat` and wait for the scan to finish (about a minute)
3. Results print in the window and are also saved to **`Python下载记录.txt` on your Desktop**
4. Want an AI to analyze it? Just paste the txt contents into a chat: what got downloaded when, what's dead weight, whether the cache is safe to clear

## Notes

- Windows only. No installation required — it uses the built-in PowerShell
- Read-only scan: nothing is deleted or modified, safe to run
- Works even without Python installed (it will just report "no Python detected")
- Package lists cap at 120 entries per interpreter (newest first), which is plenty
- If your antivirus flags it, that's because the bat launches PowerShell — just allow it
