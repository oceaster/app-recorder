# app-recorder

Record the **active application window** on Linux/X11 — its video plus that
application's own audio — from a single hotkey. Switch application while
recording and the target follows the focus.

Press once to start, press again to stop and save an `.mp4`.

```bash
app-recorder --toggle     # start recording, or stop and save
```

## Install

```bash
make install              # installs to /usr/local/bin/app-recorder
```

or, without make:

```bash
sudo install -Dm755 app-recorder /usr/local/bin/app-recorder
```

Bind it to a hotkey — for i3, in `~/.config/i3/config` or `/etc/i3/config`:

```
bindsym Control+$mod+r exec --no-startup-id /usr/local/bin/app-recorder --toggle
```

## Usage

| Command | Action |
|---|---|
| `app-recorder` | Record the focused window in the foreground until stopped (Ctrl-C) |
| `app-recorder --toggle` | Start a detached recording, or stop the running one (hotkey path) |
| `app-recorder --stop` | Stop a running detached recording |
| `app-recorder --list` | Show what would be recorded now (window, display, pid, audio source) |
| `app-recorder --no-follow` | Stay on the window focused at start |
| `app-recorder --window-name firefox` | Pin to an application instead of following focus |
| `app-recorder --no-audio` | Video only |
| `app-recorder -o clip.mp4` | Choose the output file |

Output defaults to `~/Videos/recordings/Recording-<date>.mp4`; `latest.mp4` in
that directory is a symlink to the newest recording.

Run `app-recorder --help` for the full option list (`--fps`, `--quality`,
`--encoder`, `--audio-mode`, `--allow-overlap`, `--wait`, `--no-pause`,
`--no-mouse`, `--keep-parts`, `--display`, `--pid`, `--no-notify`, `--debug`).
`--debug` logs what the tool sees, including every window it rejects and the rule
that rejected it — useful when the target is not the window you expected.

## What it does

**Target.** The focused window is the target: its X display and XAUTHORITY are
found automatically (every X server on the machine is probed), along with its
geometry, its pid and its title. With focus following on (the default) a switch
to another application closes the current segment and opens a new one on the
newly focused window — new size, new position, and its audio. Windows that are
not applications (docks, notification popups, launchers, override-redirect
windows) are never chosen as a target.

**Video.** Only the target window's rectangle is captured. Anything stacked over
it — a notification popup, another window — *pauses* capture instead of ending up
in the video, and capture resumes with a new segment when the screen is clear.
A window hanging off a screen edge is clipped to the display. `--allow-overlap`
records through covering windows instead.

**Audio.** By default the recording carries only the target application's audio:
PipeWire has no per-application monitor, so a capture stream is linked directly
to that application's output ports (`pw-record` + `pw-link`). This does not
change what is audible and adds no latency. Other applications playing on the
same device are excluded. `--audio-mode sink` records the whole device monitor
instead, and `--audio-source` picks an explicit source. If the application has no
audio stream yet the segment is video-only until its stream appears.

**Files.** Segments are written as crash-tolerant Matroska files and remuxed into
one `.mp4` on stop (`-c copy`, or re-encoded when the window size changed).
Encoding uses `h264_nvenc` when a working NVENC encoder is present, else
`libx264`.

**Notifications** report the state through `notify-send` (start, paused because
something covers the window, target switch, saved, failures). They are sent
before capture starts or after it stops, so a popup can never be recorded.

## Dependencies

- `bash`, `ffmpeg`/`ffprobe` with `x11grab` and `pulse` (or `pipewire-pulse`)
- `wmctrl`, `xwininfo`, `xprop` (window discovery and the overlay guard)
- `python3` (PipeWire graph inspection)
- `pw-dump`, `pw-link`, `pw-record`, `pactl` (per-application audio)
- `notify-send` (optional), `xdotool` (optional fallback for focus lookup),
  `setsid` (optional, isolates ffmpeg from terminal signals)

## Notes and limitations

- X11 only; there is no Wayland path (screen capture and focus lookup are X11).
- Multi-monitor is fine — the target's own display is used — but a window
  spanning two displays is captured through its own rectangle only.
- While something covers the target, capture pauses, so the finished file has a
  gap in time rather than a popup in the picture.
- A recording that is killed with `SIGKILL` leaves its segments in
  `<output>.parts/` next to the output file; a normal stop, `SIGINT`/`SIGTERM`,
  or the recorded window closing all finalise the file.

## Tests

```bash
make test     # CLI contract tests, plus an end-to-end test when Xvfb/i3 exist
make lint     # shellcheck
```

`tests/run-tests.sh` checks the command-line contract everywhere, and runs a real
capture with `Xvfb` + a window manager when those tools are installed (it skips
that part otherwise). The end-to-end part starts a real recording against a
throwaway X display and asserts the captured file's duration, streams and
resolution.
