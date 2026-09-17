## Pixelify Sans

`PixelifySans-Regular.ttf` / `-Medium.ttf` / `-Bold.ttf`, by Eduardo Xavier.
Sourced from Google Fonts: https://fonts.google.com/specimen/Pixelify+Sans
Licensed under the SIL Open Font License 1.1 (free for commercial use,
including games; no attribution required in-app).

Only the Regular weight is wired in right now (`project.godot`
`gui/theme/custom_font`), so every UI Label/Button in the project picks it
up automatically. Medium/Bold are here if we want a heavier weight for
headers later - swap by pointing a specific Label's font override at one of
them, or build a real `Theme` resource with type variations if this needs
to happen more than once or twice.
