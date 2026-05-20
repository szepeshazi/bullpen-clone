## General coding rules

* Apply single responsibility pricinple. Keep files and classes short.
* One class per file, unless there is a need for 1-2 private helper classes - those can be placed next to the public class in the same file.
* Do no write exceedingly long methods. Soft cap should be about 30 lines.
* Use documentation very sparingly. Public API documentation should be 1-2 lines. Do not document why A -> B change was necessary.
* Code should be self explanatory through proper organization and naming. No need to document a method if it is named `selectPaymentOption`.
* Always create unit and UI tests to achieve full coverage. If, for some reason, full coverage is very hard to reach and would be an unreasonable high effort, explain which edge cases were skipped from tests and why.
* Always run linters and tests before committing a changeset.

## Current project information

This projects implements a logic game for Android and iOS called bullpen. Code is written in Flutter / Dart. Objective of the game is to put bulls on a checkered rectangular board in a specific way. There are interconnected areas of squares on the table, called pens, marked with different colors. To win the game, the player should place exactly two bulls in each row, column and pen. Adjacent bulls are not allowed (diagonally adjacent is also forbidden).