# MemoPair

A memory card matching game for iPad built as a learning project for [Hacking with Swift](https://www.hackingwithswift.com).

## About

Flip cards and find matching pairs. The game tracks your moves and time, and includes a parent-protected card editor to customize the card set.

## Features

- 4×4 grid (dynamic layout based on number of pairs)
- Flip animations with card back texture
- Move counter and timer
- Confetti animation on win
- Sound feedback on match/mismatch
- Parent Mode protected by Face ID / Touch ID with password fallback (password stored in Keychain)
- Card editor — add, edit, delete pairs
- Reset to default cards
- Persistent storage via UserDefaults

## Architecture

MVC with dedicated service layers:

- `GameEngine` — game logic, move counting, timer
- `CardManager` — card pair storage (UserDefaults + Codable)
- `AuthenticationManager` — biometric auth and password validation
- `KeychainManager` — secure password storage
- `CardCell` — card UI with gradient colors, matched state, shake animation

## Requirements

- iOS 18.4+
- iPad
- Xcode 16.3+

## Learning Project

Built as part of the [100 Days of Swift](https://www.hackingwithswift.com/100) challenge on [Hacking with Swift](https://www.hackingwithswift.com).
