include "Token.dfy"
include "EnrollmentStation.dfy"
include "Door.dfy"

// Integration Test Cases

// All usual actions - everything works as intended
method {:test} should_WorkAsNormal_when_NormalOperation()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var doorLowClearance: Door := new Door(enrollmentStation, 1);
  var doorMedClearance: Door := new Door(enrollmentStation, 1);

  // Bob creates a token at the front desk
  var bobFingerprint: int := 10;
  var bobTokenMedClearance: Token := enrollmentStation.IssueToken(bobFingerprint, 1);

  // Bob goes to the custodial closet
  doorLowClearance.OpenDoor(bobTokenMedClearance, bobFingerprint);
  assert (doorLowClearance.isOpen);

  // He closes the door behind him
  doorLowClearance.CloseDoor();
  assert (!doorLowClearance.isOpen);

  // Bob goes to his medium clearance workroom
  doorMedClearance.OpenDoor(bobTokenMedClearance, bobFingerprint);
  assert (doorMedClearance.isOpen);

  // He closes the door behind him
  doorMedClearance.CloseDoor();
  assert (!doorMedClearance.isOpen);
}

// Attacker steals a token and tries his own fingerprint
method {:test} should_DeclareBreach_when_AttackerStealsToken()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var doorHighClearance: Door := new Door(enrollmentStation, 2);

  // Vice President Bob creates a token at the front desk
  var bobFingerprint: int := 10;
  var bobTokenHighClearance: Token := enrollmentStation.IssueToken(bobFingerprint, 2);

  // Attacker Mallory steals VP Bob's token and tries to use it
  var malloryFingerprint: int := 11;
  doorHighClearance.OpenDoor(bobTokenHighClearance, malloryFingerprint);
  assert (!doorHighClearance.isOpen);
  assert (doorHighClearance.isAlarmOn);
  assert (bobTokenHighClearance.fingerprint !in enrollmentStation.usersWithTokens);
  assert (|enrollmentStation.usersWithTokens| == 0);
}


// Attacker creates own token (not at the enrollment station) and tries to use it
method {:test} should_DeclareBreach_when_AttackerUsesTokenNotCreatedByEnrollmentStation()
{
  // Note - breaches only occur when there are fingerprint mismatches
  // This is simply a design choise and I chose to simply not open the door if a token didn't exist
  // I chose this because the spec only stated that there is a breach when there is a fingerprint mismatch

  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var doorHighClearance: Door := new Door(enrollmentStation, 2);

  // Attacker Mallory creates a fake high clearance token
  var malloryFingerprint: int := 11;
  var malloryTokenFake: Token := new Token(malloryFingerprint, 2);

  // Mallory attempts to use the token
  doorHighClearance.OpenDoor(malloryTokenFake, malloryFingerprint);
  assert (!doorHighClearance.isOpen);
  assert (!doorHighClearance.isAlarmOn);
  assert (|enrollmentStation.usersWithTokens| == 0);
}

// Fired employee (with revoked token) tries to get in
method {:test} should_NotGrantAccess_when_FiredEmployeeUsesRevokedToken()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var doorLowClearance: Door := new Door(enrollmentStation, 1);

  // Jim creates a token at the front desk
  var jimFingerprint: int := 10;
  var jimTokenMedClearance: Token := enrollmentStation.IssueToken(jimFingerprint, 1);
  assert (jimFingerprint in enrollmentStation.usersWithTokens);

  // Jim got fired so his token is revoked
  var wasDeleted: bool := enrollmentStation.InvalidateToken(jimFingerprint);
  assert (jimFingerprint !in enrollmentStation.usersWithTokens);

  // Jim tries to enter the janatorial closet and gets denied
  doorLowClearance.OpenDoor(jimTokenMedClearance, jimFingerprint);
  assert (!doorLowClearance.isOpen);
  assert (!doorLowClearance.isAlarmOn);
  assert (jimFingerprint !in enrollmentStation.usersWithTokens);
}

// Janitor (low clearance) tries to enter top secret (high clearance) room
method {:test} should_NotGrandAccess_when_JanitorTriesToEnterHighClearanceRoom()
{
  var enrollmentStation: EnrollmentStation := new EnrollmentStation();
  var doorHighClearance: Door := new Door(enrollmentStation, 2);

  // Ben the janitor creates a token at the front desk
  var benFingerprint: int := 10;
  var benTokenLowClearance: Token := enrollmentStation.IssueToken(benFingerprint, 0);
  assert (benFingerprint in enrollmentStation.usersWithTokens);

  // Ben the janitor tries to enter the top secret room and gets denied
  doorHighClearance.OpenDoor(benTokenLowClearance, benFingerprint);
  assert (!doorHighClearance.isOpen);
  assert (!doorHighClearance.isAlarmOn);
  assert (benFingerprint in enrollmentStation.usersWithTokens);
  assert (|enrollmentStation.usersWithTokens| == 1);
}
