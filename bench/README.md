# OCR accuracy bench

Measures per-field accuracy (amount, date and time, payee exact) of the Dart
stage: `ThaiSlipExtractionService.combine`, which parses and votes across
several OCR readings of one slip.

    flutter test bench/

## What it does not measure

It does not run Tesseract or Apple Vision, and it does not test image
preprocessing (`SlipOcr.kt`). It starts from OCR text that was already
recorded, one text file per pass.

## Committed set: `bench/synthetic/`

Invented slips only (the text fixtures in `test/fixtures/slips/` plus small
hand-made misreadings). `manifest.json` lists, per slip, the pass files and
the expected values. This run must be 100% or the test fails. Some cases show
voting rescuing a misread pass; a mutation check (dropping the good passes)
turns the amount case red.

## Private set: `bench/private/` (gitignored)

For real slips. Nothing in this directory except `.gitkeep` is tracked. Put
recorded OCR text passes and a `manifest.json` in the same format as the
synthetic one, with paths relative to the manifest:

    {"cases":[{"id":"slip01","passes":["slip01_a.txt","slip01_b.txt"],
      "expected":{"amountMinor":125050,"occurredAt":"2026-02-12T02:05:00Z",
                  "merchant":"..."}}]}

When the manifest exists the bench prints per-field counts; with none it is
skipped. Only slip ids and ok/WRONG verdicts are printed, never slip text.
Do not paste real names, account numbers or images anywhere in the repo.
