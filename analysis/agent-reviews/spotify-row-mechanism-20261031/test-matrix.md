| Verified case | Arrow keys19–22 declared | UI absolute | Swipe keys | Down pulse | Target direct Down |
|---|---|---|---|---|---|
| DPAD/absolute | true | true | DPAD | normal | Failed |
| DPAD/gesture | true | false | DPAD | normal | Failed |
| Page A/gesture | true | false | PAGE_MOVE | normal | Failed |
| Page B/gesture | false | false | PAGE_MOVE | normal | Failed |
| Down-only B/gesture | false | false | PAGE_MOVE | raw146 consumed, no93 pulse | Failed |
| Historical page APK | true | true | PAGE_MOVE | normal | Failed after return; older hover behavior |
| Uncovered matched navigation subset | false | true | PAGE_MOVE | normal | **Not tested in verified set** |
