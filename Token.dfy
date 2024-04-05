class Token {
  var fingerprint: int
  var clearance: int

  constructor(newFingerprint: int, newClearance: int)
    requires 0 <= newClearance <= 2
    ensures
      && fingerprint == newFingerprint
      && clearance == newClearance
      && IsValid()
  {
    fingerprint := newFingerprint;
    clearance := newClearance;
  }

  predicate IsValid()
    reads this
  {
    && 0 <= clearance <= 2
  }
}

// UNIT TESTS

method {:test} should_InitializeToken_when_InitializerCalled()
{
  var token := new Token(1234, 2);
  assert (token.IsValid());
}