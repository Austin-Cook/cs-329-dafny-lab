include "Token.dfy"

class EnrollmentStation {
  var usersWithTokens: set<int>

  constructor()
    ensures
      && |usersWithTokens| == 0
  {
    usersWithTokens := {};
  }

  predicate SetDiff_Same(oldSet: set<int>, newSet: set<int>)
  {
    && |oldSet| == |newSet|
    && (forall elem :: elem in oldSet ==> elem in newSet)
  }

  predicate SetDiff_SameWithOneNew(oldSet: set<int>, newSet: set<int>, newFingerprint: int)
  {
    && |oldSet| + 1 == |newSet|
    && (forall elem :: elem in oldSet ==> elem in newSet)
    && newFingerprint in newSet
  }

  predicate SetDiff_SameWithOneLess(oldSet: set<int>, newSet: set<int>, deletedFingerprint: int)
  {
    && |oldSet| - 1 == |newSet|
    && (forall elem :: elem in oldSet - {deletedFingerprint} ==> elem in newSet)
    && deletedFingerprint !in newSet
  }

  method IssueToken(fingerprint: int, clearance: int) returns (returnToken: Token?)
    modifies `usersWithTokens
    requires 0 <= clearance <= 2
    ensures
      && (if fingerprint in old(usersWithTokens) then // token already exists for user - don't create one
            && SetDiff_Same(old(usersWithTokens), usersWithTokens)
            && returnToken == null
          else // token does not exist for user - create one
            && SetDiff_SameWithOneNew(old(usersWithTokens), usersWithTokens, fingerprint)
            && returnToken != null
            && returnToken.IsValid()
            && returnToken.fingerprint == fingerprint
            && returnToken.clearance == clearance)
  {
    if fingerprint in usersWithTokens {
      return null;
    } else {
      usersWithTokens := usersWithTokens + {fingerprint};
      var token: Token := new Token(fingerprint, clearance);
      return token;
    }
  }

  method InvalidateToken(fingerprint: int) returns (wasDeleted: bool)
    modifies `usersWithTokens
    ensures (if fingerprint in old(usersWithTokens) then
               && SetDiff_SameWithOneLess(old(usersWithTokens), usersWithTokens, fingerprint)
               && wasDeleted == true
             else
               && SetDiff_Same(old(usersWithTokens), usersWithTokens)
               && wasDeleted == false)
  {
    if fingerprint in usersWithTokens {
      usersWithTokens := usersWithTokens - {fingerprint};
      return true;
    } else {
      return false;
    }
  }
}

// UNIT TESTS

// General

method {:test} should_InitializeToZeroUsers_when_InitializerCalled()
{
  var enrollmentStation := new EnrollmentStation();
  assert (|enrollmentStation.usersWithTokens| == 0);
}

// IssueToken()

method {:test} should_IssueToken_when_FingerprintNotRegistered()
{
  var enrollmentStation := new EnrollmentStation();

  var token: Token? := enrollmentStation.IssueToken(10, 2);
  assert (token != null);
  assert (10 in enrollmentStation.usersWithTokens);
  assert (token.fingerprint == 10);
  assert (token.clearance == 2);
  assert (token.IsValid());
  assert (|enrollmentStation.usersWithTokens| == 1);
}

method {:test} should_NotIssueToken_when_FingerprintAlreadyRegistered()
{
  var enrollmentStation := new EnrollmentStation();
  var token1: Token? := enrollmentStation.IssueToken(10, 2);
  var token2: Token? := enrollmentStation.IssueToken(10, 0);
  assert (token2 == null);
  assert (10 in enrollmentStation.usersWithTokens);
  assert (|enrollmentStation.usersWithTokens| == 1);
}

// InvalidateToken()

method {:test} should_InvalidateToken_when_FingerprintRegistered()
{
  var enrollmentStation := new EnrollmentStation();
  var token: Token? := enrollmentStation.IssueToken(10, 0);

  var wasDeleted: bool := enrollmentStation.InvalidateToken(10);
  assert (wasDeleted == true);
  assert (|enrollmentStation.usersWithTokens| == 0);
}

method {:test} should_NotInvalidateToken_when_FingerprintNotRegistered()
{
  var enrollmentStation := new EnrollmentStation();
  var token: Token? := enrollmentStation.IssueToken(10, 0);

  var wasDeleted: bool := enrollmentStation.InvalidateToken(11);
  assert (wasDeleted == false);
  assert (|enrollmentStation.usersWithTokens| == 1);
}
