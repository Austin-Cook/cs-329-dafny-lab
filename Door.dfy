include "EnrollmentStation.dfy"

class Door {
  var isOpen: bool
  var isAlarmOn: bool
  var requiredClearance: int
  var enrollmentStation: EnrollmentStation

  constructor(newEnrollmentStation: EnrollmentStation, newRequiredClearance: int)
    requires
      && 0 <= newRequiredClearance <= 2
    ensures
      && isOpen == false
      && isAlarmOn == false
      && requiredClearance == newRequiredClearance
      && enrollmentStation == newEnrollmentStation
      && newEnrollmentStation.SetDiff_Same(old(newEnrollmentStation.usersWithTokens), enrollmentStation.usersWithTokens)
      && IsValid()
  {
    isOpen := false;
    isAlarmOn := false;
    requiredClearance := newRequiredClearance;
    enrollmentStation := newEnrollmentStation;
  }

  predicate IsValid()
    reads this
  {
    && 0 <= requiredClearance <= 2
  }

  method OpenDoor(token: Token, actualFingerprint: int)
    modifies `isOpen, `isAlarmOn, enrollmentStation
    requires
      && token.IsValid()
      && IsValid()
    ensures
      && IsValid()
      && (if token.fingerprint != actualFingerprint then
            // breach - invlidate token, open door, turn on alarm
            && (if old(token.fingerprint) in old(enrollmentStation.usersWithTokens) then
                  enrollmentStation.SetDiff_SameWithOneLess(old(enrollmentStation.usersWithTokens), enrollmentStation.usersWithTokens, old(token.fingerprint))
                else
                  enrollmentStation.SetDiff_Same(old(enrollmentStation.usersWithTokens), enrollmentStation.usersWithTokens))
            && isAlarmOn == true
            && isOpen == false
          else if old(token.fingerprint) in old(enrollmentStation.usersWithTokens) && token.clearance >= requiredClearance then
            // token not enrolled && clearance sufficient - open door, turn off alarm
            && enrollmentStation.SetDiff_Same(old(enrollmentStation.usersWithTokens), enrollmentStation.usersWithTokens)
            && isAlarmOn == false
            && isOpen == true
          else
            // token not enrolled || clearance insufficient - do nothing
            && enrollmentStation.SetDiff_Same(old(enrollmentStation.usersWithTokens), enrollmentStation.usersWithTokens)
            && isAlarmOn == old(isAlarmOn)
            && isOpen == old(isOpen))
  {
    if token.fingerprint != actualFingerprint {
      var removed: bool := enrollmentStation.InvalidateToken(token.fingerprint);
      isAlarmOn := true;
      isOpen := false;
    } else if token.fingerprint in enrollmentStation.usersWithTokens && token.clearance >= requiredClearance {
      isAlarmOn := false;
      isOpen := true;
    }
  }

  method CloseDoor()
    modifies `isOpen
    requires
      && IsValid()
    ensures
      && IsValid()
      && isOpen == false
  {
    isOpen := false;
  }
}

// UNIT TESTS

// OpenDoor()
method {:test} should_SetBreachAndRevokeToken_when_FingerprintsDoNotMatchAndTokenRegistered()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);
  var registeredToken: Token := enrollmentStation.IssueToken(10, 2);
  assert (|enrollmentStation.usersWithTokens| == 1);
  door.OpenDoor(registeredToken, 11);

  assert (door.isAlarmOn);
  assert (!door.isOpen);
  assert (|enrollmentStation.usersWithTokens| == 0);
}

method {:test} should_SetBreachAndRevokeNothing_when_FingerprintsDoNotMatchAndTokenNotRegistered()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);
  var unregisteredToken: Token := new Token(10, 2);
  door.OpenDoor(unregisteredToken, 11);

  assert (door.isAlarmOn);
  assert (!door.isOpen);
  assert (|enrollmentStation.usersWithTokens| == 0);
}

method {:test} should_OpenDoor_when_FingerprintsMatchAndTokenRegisteredAndClearanceIsSufficient()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);
  assert (!door.isOpen);

  var registeredToken: Token := enrollmentStation.IssueToken(10, 1);
  door.OpenDoor(registeredToken, 10);
  assert (door.isOpen);
  assert (!door.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 1);
}

method {:test} should_NotOpenDoor_when_FingerprintsMatchAndTokenRegiteredAndClearanceIsInsufficient()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);
  assert (!door.isOpen);

  var registeredToken: Token := enrollmentStation.IssueToken(10, 0);
  door.OpenDoor(registeredToken, 10);
  assert (!door.isOpen);
  assert (!door.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 1);
}

method {:test} should_NotOpenDoor_when_FingerprintsMatchAndTokenNotRegisteredAndClearanceIsSufficient()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);
  assert (!door.isOpen);

  var unregisteredToken: Token := new Token(10, 2);
  door.OpenDoor(unregisteredToken, 10);
  assert (!door.isOpen);
  assert (!door.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 0);
}

method {:test} should_NotOpenDoor_when_FingerprintsMatchAndTokenNotRegisteredAndClearanceIsInsufficient()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);
  assert (!door.isOpen);

  var unregisteredToken: Token := new Token(10, 0);
  door.OpenDoor(unregisteredToken, 10);
  assert (!door.isOpen);
  assert (!door.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 0);
}

// CloseDoor()

method {:test} should_CloseDoor_when_CloseDoorCalledAndDoorOpened()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);
  var registeredToken: Token := enrollmentStation.IssueToken(10, 1);
  door.OpenDoor(registeredToken, 10);
  assert (door.isOpen);

  door.CloseDoor();
  assert (!door.isOpen);
  assert (!door.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 1);
}

method {:test} should_DoNothing_when_CloseDoorCalledAndDoorClosed()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var door: Door := new Door(enrollmentStation, 1);

  assert (!door.isOpen);
  assert (!door.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 0);
  door.CloseDoor();
  assert (!door.isOpen);
  assert (!door.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 0);
}
