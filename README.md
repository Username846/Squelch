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

Every crime plays fully with **just a mouse**, **just a touch screen**, or **just a keyboard**.

| | Mouse / touch | Keyboard |
|---|---|---|
| Walk (Party, Library, Heist) | hold the mouse button or a finger where you want to go | arrows / WASD |
| Fart / boost / gas | on-screen action button (hold it in the elevator) | Space |
| Everything else | click or tap the thing (lanes, dishes, valves, buttons) | arrows, Space, X, 1-5 |
| Skip a cutscene, back to the board, sound | on-screen Skip, X and Sound buttons | Esc, M |

On phones, play in landscape. On touch screens you can walk with one finger and fart with another.

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
