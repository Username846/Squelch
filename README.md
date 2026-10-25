# Squelch: A Life of Fart Crime

**▶ Play in your browser: https://username846.github.io/Squelch/**

You are **Squelch**, the city's most wanted gas bandit. Commit ten heinous fart crimes
while Detective Sniffington and his legendary nose close in.

| # | Crime | What you do |
|---|-------|-------------|
| 1 | Birthday Bash | Musical chairs: foul every chair before the music stops |
| 2 | Going Down | Silently gas a crowded elevator without getting caught |
| 3 | Silent But Deadly | Stealthily crop-dust five readers past the librarian |
| 4 | Downward Dog | Hot-yoga rhythm game, one toot per beat |
| 5 | Le Bistro Pew | "Season" the soup when the waiter isn't looking |
| 6 | Speak Now | Perfectly time three blasts during a wedding |
| 7 | Gas Getaway | Car chase with fart boost |
| 8 | Symphony No. 2 | Simon-says on the tuba |
| 9 | Royal Tea | Clench through the Queen's speech, release under cannon fire |
| 10 | The Evidence Room | Heist: knock out guards with gas clouds, steal the Golden Bean |

Every crime hides one **secret stash** — no hints given. Find all ten to open
**the Final Case**, where Squelch finally gets caught... or does he?

## Controls

- **Arrows / WASD** move, **Space** farts, **X / Enter** is the alternate action
- Most crimes can also be played with the mouse or touch (on-screen pad appears on touch screens)
- **Esc** returns to the crime board, **M** mutes

## Tech

- Godot **4.7.2**, GL Compatibility renderer, single-threaded web export (works on plain GitHub Pages)
- All art is drawn procedurally in code (`scripts/art.gd`)
- All music and sound effects are synthesized by `tools/make_audio.py` (numpy + ffmpeg)
- Dialogue is voiced with the browser's speech synthesizer via Godot's text-to-speech API
- Every push to `main` builds, smoke-tests and deploys the game with GitHub Actions
  (`.github/workflows/deploy.yml`)

## Developing

```sh
godot --path .                                                   # play locally
godot --headless --path . --fixed-fps 60 res://tests/smoke.tscn  # smoke test every scene
python3 tools/make_audio.py                                      # regenerate music + sfx
```
