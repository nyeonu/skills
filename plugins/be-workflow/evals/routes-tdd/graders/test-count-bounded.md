---
type: regex
target: { source: file, path: src/test/java/com/example/profile/ProfileServiceTest.java }
pattern: '(@Test[\s\S]*?){5}'
match: not_contains
---
