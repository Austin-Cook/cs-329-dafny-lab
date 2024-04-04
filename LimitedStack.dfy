class LimitedStack {
  var arr : array<int>  // contents
  var capacity : int    // max number of elements in stack.
  var top : int         // The index of the top of the stack, or -1 if the stack is empty.

  method Init(c : int)
  . . .
  {
  capacity := c;
  arr := new int[c];
  top := -1;
  } 
  . . . 

  // Need for push2 to discard the oldest element
  method Shift()
    modifies this.arr, this`top;
    requires Valid() && !Empty();
    ensures
      && Valid();
      && forall i : int :: 0 <= i < capacity - 1 ==> arr[i] == old(arr[i + 1]);
      && top == old(top) - 1;
  {
    var i : int := 0;
    while (i < capacity - 1 )
      invariant 0 <= i < capacity;
      invariant top == old(top);
      invariant forall j : int :: 0 <= j < i ==> arr[j] == old(arr[j + 1]);
      invariant forall j : int :: i <= j < capacity ==> arr[j] == old(arr[j]);
    {
      arr[i] := arr[i + 1];
      i := i + 1;
    }
    top := top - 1;
  }

  // Feel free to add extra ones as well.
  method Main()
  {
    var s := new LimitedStack;
    s.Init(3);

    assert s.Empty() && !s.Full();

    s.Push(27);
    assert !s.Empty();

    var e := s.Pop();
    assert e == 27;

    s.Push(5);
    s.Push(32);
    s.Push(9);
    assert s.Full();

    var e2 := s.Pop();
    assert e2 == 9 && !s.Full();
    assert s.arr[0] == 5;

    s.Push(e2);
    s.Push2(99);

    var e3 := s.Peek();
    assert e3 == 99;
    assert s.arr[0] == 32;
  }
}
