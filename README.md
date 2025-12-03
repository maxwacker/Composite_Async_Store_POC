# Composite Redux Demo App

## Goals : Implement some Composable Redux Store for SwiftUI modular App

### Original target :
  - Composable Features : Allowing App features to be isolated in their own SPM package for quick&easy devvelopment and testing
  - View Code independant of Redux implementation details. View Code only rely on ActionEmitter and Presenter concepts
  - AsyncStream Core / Observable Shell : States changes emited as AsyncStream at Store level, translated to @Observable at Presenting layer
