---
layout: tutorialLayout
---
# Changelog

### Gryphon v0.6

See it on [GitHub](https://github.com/vinivendra/Gryphon/tree/v0.6).

- Bugfixes
  - Fixed an issue some users were having when trying to output a translation to the console;
  - Add `return@label` in closures to avoid returning to the root function (*#14*);
  - **@pt2121** implemented a pass to remove `break` statements in `switches` (*#17*);
  - Add parentheses around `or` operators in if conditions to avoid issues with operator precedence (*#18*);
  - Support trailing closures on simple tuple shuffle expressions;
  - Removed extra output from automated tests;
  - Lack of a second Swift toolchain is now just a warning, not a test failure;
  - Fixed the favicon for safari and iOS.
- First-timers-only
  - Added isntructions on an issue (*#3*) especially for first-time contributors to open source.
- Documentation
  - Added test scripts, which should make running the tests a lot easier for everyone;
  - Improved several things on the contributor's guide;
  - Wrote templates for bug reports, feature requests, and pull requests on GitHub;
  - Added a `GOVERNANCE.md` file to the repo;
  - Started using the ethical Hippocratic license (v2.1);
  - Fixed lots of typos on the website.
- For the future
  - Started looking into using SourceKit instead of the AST dumps, which should greatly improve stability and reliability in general.

