# Explanation

Below are my preliminary explanations of each method. I wrote the general idea of everything out in comments prior to messing with any Dafny specificatoin or code. I was able to make adjustments to method and classes at a high level without having to deal with the Dafny error.

NOTE: Some things below were changed and simplified in the actual implementation, but this was just what I got down prior to writing any specification or code.

## Token
```
// Class Token  
// FIELDS:  
//      fingerprint: int  
//      clearance: int { 0: low, 1: medium, 2: high }  
// METHODS:
//      Init(fingerprint: int, clearance: int): null
//          This initializes a token to include a given fingerprint and clearance level.
//          modifies: this
//          req:
//              clearance is between 0 and 2 (inclusive)
//          ens:
//              this.fingerprint == fingerprint
//              this.clearance == clearance
//              IsValid()
//      predicate IsValid(): bool
//          reads: this
//          checks:
//              this.clearance is between 0 and 2 (inclusive)
```
## Enrollment Station
```
// Class EnrollmentStation
// FIELDS:
//      usersWithTokens: set<int> // contains the fingerprints of users who currently have tokens
// METHODS:
//      Init(): null
//          modifies: this
//          req:
//              none
//          ens:
//              usersWithTokens has length 0
//      predicate IsValid(): bool // NOT NEEDED BECAUSE IT CAN'T BE INVALID
//          reads: this
//          checks:
//      IssueToken(fingerprint: int, clearance: int): token | null
//          modifies: .usersWithTokens
//          req:
//              clearance is between 0 and 2 (inclusive)
//          ens:
//              if fingerprint in usersWithTokens: // user already has token - don't issue one
//                  usersWithTokens is unchanged
//                  returnToken is null
//              else // user doesn't have a token yet - issue one
//                  usersWithTokens has same items but also has fingerprint
//                  returnToken is not null
//                  returnToken.IsValid()
//                  returnToken`fingerPrint == fingerprint
//                  returnToken`clearance == clearance
//      InvalidateToken(fingerprint): bool // returns true if it was delete, else false (if nonexistent)
//          modifies: .usersWithTokens
//          req:
//              none
//          ens:
//              if fingerprint in old(usersWithTokens): // invalidate it
//                  length of usersWithTokens is 1 less
//                  for item in old(usersWithTokens):
//                      if not fingerprint:
//                          it is in new(usersWithTokens)
//                  return is true
//              else: // nothing to change
//                  usersWithTokens unchanged
//                  return is false
```

## Door
```
// Class Door
// FIELDS:
//      isOpen: bool
//      isAlarmOn: bool
//      requiredClearance: int [0, 1, or 2]
//      enrollmentStation: EnrollmentStation
// METHODS:
//      Init(enrollmentStation: EnrollmentStation, requiredClearance: int): null
//          modifies: this
//          req:
//              enrollmentStation.IsValid()
//              requiredClearance is between 0 and 2 (inclusive)
//          ens:
//              isOpen == false
//              isAlarmOn == false
//              this`requiredClearance == requiredClearance
//              this`enrollmentStation == enrollmentStation
//              this`enrollmentStation is unchanged
//      predicate IsValid(): bool
//          reads: this
//          checks:
//              this`requiredClearance is between 0 and 2 (inclusive)
//              this`enrollmentStation is not null
//      OpenDoor(token: Token, actualFingerprint: int): bool
//          modifies: this`isOpen, this`isAlarmOn, this.enrollmentStation
//          req:
//              token.IsValid()
//              IsValid()
//          ens:
//              IsValid()
//              if the token.fingerprint doesn't match actualFingerprint: // breach
//                  if fingerprint in this.enrollmentStation.usersWithTokens:
//                    same as old except doesn't have fingerprint
//                  else:
//                    same as old
//                  this`isAlarmOn == true
//                  this`isOpen == false
//                  return is false
//              else if fingerprint in enrollmentStation.usersWithTokens and token`clearance >= this`requiredClearance:
//                  this.enrollmentStation.usersWithTokens unchanged
//                  this`isAlarmOn == false
//                  this`isOpen == true
//                  return is true
//              else // if the token isn't enrolled or the clearance is insufficient, it simply fails
//                  this.enrollmentStation.usersWithTokens is unchanged
//                  this`isAlarmOn is unchanged
//                  this`isOpen is unchanged
//                  return is false
//      CloseDoor(): null
//          modifies: this`isOpen
//          req:
//              IsValid()
//          ens:
//              IsValid()
//              this`isOpen == false
```
